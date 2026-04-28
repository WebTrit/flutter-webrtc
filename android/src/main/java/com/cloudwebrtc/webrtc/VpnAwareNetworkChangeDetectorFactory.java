package com.cloudwebrtc.webrtc;

import android.annotation.SuppressLint;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.LinkAddress;
import android.net.LinkProperties;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.webrtc.NetworkChangeDetector;
import org.webrtc.NetworkChangeDetectorFactory;
import org.webrtc.NetworkMonitorAutoDetect;

import java.net.InetAddress;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Produces a NetworkChangeDetector that keeps NetworkMonitorAutoDetect for physical
 * interfaces and adds a dedicated VPN callback for tun0.
 *
 * Why two layers:
 *
 * 1. requestVPN field trial (VpnFieldTrialObserver): tells NetworkMonitorAutoDetect
 *    to include TRANSPORT_VPN in its NetworkRequest. Handles the common case on
 *    older Android where NetworkMonitorAutoDetect can process VPN networks.
 *
 * 2. Own VPN NetworkCallback (VpnInclusiveDetector): on Android 16 (API 36),
 *    NetworkMonitorAutoDetect.networkToInfo() calls the deprecated
 *    ConnectivityManager.getNetworkInfo() which returns null for VPN networks,
 *    so onNetworkConnect is never forwarded to the ICE observer. Our callback
 *    builds NetworkInformation directly from getLinkProperties() +
 *    getNetworkHandle() and calls observer.onNetworkConnect explicitly.
 */
class VpnAwareNetworkChangeDetectorFactory implements NetworkChangeDetectorFactory {

    private static final String TAG = "VpnAwareNMFactory";

    @Override
    public NetworkChangeDetector create(NetworkChangeDetector.Observer observer, Context context) {
        Log.d(TAG, "create: installing VPN-inclusive NetworkChangeDetector");
        return new VpnInclusiveDetector(observer, context);
    }

    private static class VpnInclusiveDetector implements NetworkChangeDetector {

        private static final String TAG = "VpnInclusiveDetector";

        private final NetworkChangeDetector.Observer observer;
        private final NetworkMonitorAutoDetect delegate;
        private final ConnectivityManager cm;
        private final ConnectivityManager.NetworkCallback vpnCallback;
        private final Set<Long> notifiedVpnHandles = new HashSet<>();

        @SuppressLint("MissingPermission")
        VpnInclusiveDetector(NetworkChangeDetector.Observer observer, Context context) {
            this.observer = observer;
            this.cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            this.delegate = new NetworkMonitorAutoDetect(new VpnFieldTrialObserver(observer), context);
            this.vpnCallback = buildVpnCallback();
            registerVpnCallback();
        }

        @Override
        public ConnectionType getCurrentConnectionType() {
            return delegate.getCurrentConnectionType();
        }

        @Override
        public boolean supportNetworkCallback() {
            return delegate.supportNetworkCallback();
        }

        @Override
        public List<NetworkInformation> getActiveNetworkList() {
            List<NetworkInformation> base = delegate.getActiveNetworkList();
            if (base == null) base = new ArrayList<>();

            Set<Long> reported = new HashSet<>();
            for (NetworkInformation info : base) reported.add(info.handle);

            List<NetworkInformation> result = new ArrayList<>(base);
            for (NetworkInformation vpn : currentVpnNetworks()) {
                if (!reported.contains(vpn.handle)) {
                    Log.d(TAG, "getActiveNetworkList: adding VPN " + vpn.name
                            + " handle=" + vpn.handle);
                    result.add(vpn);
                }
            }
            return result;
        }

        @Override
        public void destroy() {
            try {
                cm.unregisterNetworkCallback(vpnCallback);
            } catch (Exception e) {
                Log.w(TAG, "unregisterNetworkCallback: " + e.getMessage());
            }
            delegate.destroy();
        }

        // --- VPN callback ---

        @SuppressLint("MissingPermission")
        private ConnectivityManager.NetworkCallback buildVpnCallback() {
            return new ConnectivityManager.NetworkCallback() {
                @Override
                public void onAvailable(Network network) {
                    Log.d(TAG, "VPN onAvailable: handle=" + network.getNetworkHandle());
                }

                @Override
                public void onLinkPropertiesChanged(Network network, LinkProperties lp) {
                    long handle = network.getNetworkHandle();
                    NetworkCapabilities caps = cm.getNetworkCapabilities(network);
                    if (caps == null || !caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) return;
                    if (!notifiedVpnHandles.add(handle)) return;

                    List<IPAddress> ips = new ArrayList<>();
                    for (LinkAddress la : lp.getLinkAddresses()) {
                        ips.add(new IPAddress(la.getAddress().getAddress()));
                    }
                    if (ips.isEmpty()) {
                        notifiedVpnHandles.remove(handle);
                        return;
                    }
                    String iface = lp.getInterfaceName();
                    if (iface == null) iface = "vpn";
                    NetworkInformation info = new NetworkInformation(
                            iface,
                            ConnectionType.CONNECTION_VPN,
                            ConnectionType.CONNECTION_UNKNOWN, // TODO: resolve from NetworkCapabilities (TRANSPORT_WIFI/CELLULAR)
                            handle,
                            ips.toArray(new IPAddress[0]));
                    Log.d(TAG, "VPN onLinkPropertiesChanged: notifying ICE " + iface + " handle=" + handle);
                    observer.onNetworkConnect(info);
                }

                @Override
                public void onLost(Network network) {
                    long handle = network.getNetworkHandle();
                    if (notifiedVpnHandles.remove(handle)) {
                        Log.d(TAG, "VPN onLost: handle=" + handle);
                        observer.onNetworkDisconnect(handle);
                    }
                }
            };
        }

        @SuppressLint("MissingPermission")
        private void registerVpnCallback() {
            try {
                // No transport filter — TRANSPORT_VPN-filtered requests may not receive
                // callbacks for non-bypassable VPN networks on Android 16 (API 36).
                // VPN filtering is done inside the callback via getNetworkCapabilities().
                // Handler(mainLooper) guarantees delivery regardless of the calling thread.
                NetworkRequest req = new NetworkRequest.Builder()
                        .removeCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
                        .build();
                cm.registerNetworkCallback(req, vpnCallback, new Handler(Looper.getMainLooper()));
                Log.d(TAG, "VPN NetworkCallback registered");
            } catch (Exception e) {
                Log.w(TAG, "registerNetworkCallback failed: " + e.getMessage());
            }
        }

        // --- helpers ---

        @SuppressLint("MissingPermission")
        private List<NetworkInformation> currentVpnNetworks() {
            List<NetworkInformation> result = new ArrayList<>();
            if (cm == null) return result;
            try {
                Network[] all = cm.getAllNetworks();
                if (all == null) return result;
                for (Network n : all) {
                    NetworkCapabilities caps = cm.getNetworkCapabilities(n);
                    if (caps == null || !caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) continue;
                    NetworkInformation info = buildVpnInfo(n);
                    if (info != null) result.add(info);
                }
            } catch (Exception e) {
                Log.w(TAG, "currentVpnNetworks: " + e.getMessage());
            }
            return result;
        }

        private NetworkInformation buildVpnInfo(Network network) {
            try {
                LinkProperties lp = cm.getLinkProperties(network);
                if (lp == null) return null;
                List<IPAddress> ips = new ArrayList<>();
                for (LinkAddress la : lp.getLinkAddresses()) {
                    InetAddress addr = la.getAddress();
                    ips.add(new IPAddress(addr.getAddress()));
                }
                if (ips.isEmpty()) return null;
                String iface = lp.getInterfaceName();
                if (iface == null) iface = "vpn";
                return new NetworkInformation(
                        iface,
                        ConnectionType.CONNECTION_VPN,
                        ConnectionType.CONNECTION_UNKNOWN, // TODO: resolve from NetworkCapabilities (TRANSPORT_WIFI/CELLULAR)
                        network.getNetworkHandle(),
                        ips.toArray(new IPAddress[0])
                );
            } catch (Exception e) {
                Log.w(TAG, "buildVpnInfo: " + e.getMessage());
                return null;
            }
        }
    }

    private static class VpnFieldTrialObserver extends NetworkChangeDetector.Observer {

        private final NetworkChangeDetector.Observer delegate;

        VpnFieldTrialObserver(NetworkChangeDetector.Observer delegate) {
            this.delegate = delegate;
        }

        @Override
        public String getFieldTrialsString() {
            String base = delegate.getFieldTrialsString();
            return (base.isEmpty() || base.endsWith("/"))
                    ? base + "requestVPN/Enabled/"
                    : base + "/requestVPN/Enabled/";
        }

        @Override
        public void onConnectionTypeChanged(NetworkChangeDetector.ConnectionType t) {
            delegate.onConnectionTypeChanged(t);
        }

        @Override
        public void onNetworkConnect(NetworkChangeDetector.NetworkInformation info) {
            delegate.onNetworkConnect(info);
        }

        @Override
        public void onNetworkDisconnect(long handle) {
            delegate.onNetworkDisconnect(handle);
        }

        @Override
        public void onNetworkPreference(
                List<NetworkChangeDetector.ConnectionType> types, int preference) {
            delegate.onNetworkPreference(types, preference);
        }
    }
}
