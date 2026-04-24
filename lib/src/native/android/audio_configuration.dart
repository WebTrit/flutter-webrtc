import '../utils.dart';

enum AndroidAudioMode {
  normal,
  callScreening,
  inCall,
  inCommunication,
  ringtone,
}

extension AndroidAudioModeEnumEx on String {
  AndroidAudioMode toAndroidAudioMode() =>
      AndroidAudioMode.values.firstWhere((d) => d.name == toLowerCase());
}

enum AndroidAudioFocusMode {
  gain,
  gainTransient,
  gainTransientExclusive,
  gainTransientMayDuck
}

extension AndroidAudioFocusModeEnumEx on String {
  AndroidAudioFocusMode toAndroidAudioFocusMode() =>
      AndroidAudioFocusMode.values.firstWhere((d) => d.name == toLowerCase());
}

enum AndroidAudioStreamType {
  accessibility,
  alarm,
  dtmf,
  music,
  notification,
  ring,
  system,
  voiceCall
}

extension AndroidAudioStreamTypeEnumEx on String {
  AndroidAudioStreamType toAndroidAudioStreamType() =>
      AndroidAudioStreamType.values.firstWhere((d) => d.name == toLowerCase());
}

enum AndroidAudioAttributesUsageType {
  alarm,
  assistanceAccessibility,
  assistanceNavigationGuidance,
  assistanceSonification,
  assistant,
  game,
  media,
  notification,
  notificationEvent,
  notificationRingtone,
  unknown,
  voiceCommunication,
  voiceCommunicationSignalling
}

extension AndroidAudioAttributesUsageTypeEnumEx on String {
  AndroidAudioAttributesUsageType toAndroidAudioAttributesUsageType() =>
      AndroidAudioAttributesUsageType.values
          .firstWhere((d) => d.name == toLowerCase());
}

enum AndroidAudioAttributesContentType {
  movie,
  music,
  sonification,
  speech,
  unknown
}

extension AndroidAudioAttributesContentTypeEnumEx on String {
  AndroidAudioAttributesContentType toAndroidAudioAttributesContentType() =>
      AndroidAudioAttributesContentType.values
          .firstWhere((d) => d.name == toLowerCase());
}

enum AndroidAudioOutputDevice { bluetooth, wiredHeadset, earpiece, speakerphone }

class AndroidAudioConfiguration {
  AndroidAudioConfiguration({
    this.manageAudioFocus,
    this.androidAudioMode,
    this.androidAudioFocusMode,
    this.androidAudioStreamType,
    this.androidAudioAttributesUsageType,
    this.androidAudioAttributesContentType,
    this.forceHandleAudioRouting,
    this.preferredOutputOrder,
  });

  /// Controls whether audio focus should be automatically managed during
  /// a WebRTC session.
  final bool? manageAudioFocus;
  final AndroidAudioMode? androidAudioMode;
  final AndroidAudioFocusMode? androidAudioFocusMode;
  final AndroidAudioStreamType? androidAudioStreamType;
  final AndroidAudioAttributesUsageType? androidAudioAttributesUsageType;
  final AndroidAudioAttributesContentType? androidAudioAttributesContentType;

  /// On certain Android devices, audio routing does not function properly and
  /// bluetooth microphones will not work unless audio mode is set to
  /// `inCommunication` or `inCall`. Audio routing is turned off those cases.
  ///
  /// If this set to true, will attempt to do audio routing regardless of audio mode.
  final bool? forceHandleAudioRouting;

  /// Priority-ordered list of audio output devices for Android AudioSwitch.
  ///
  /// AudioSwitch selects the first available device from this list on
  /// [AudioSwitch.activate]. If null, the existing order is unchanged.
  ///
  /// Example for voice calls (earpiece preferred):
  /// ```dart
  /// preferredOutputOrder: const [
  ///   AndroidAudioOutputDevice.bluetooth,
  ///   AndroidAudioOutputDevice.wiredHeadset,
  ///   AndroidAudioOutputDevice.earpiece,
  ///   AndroidAudioOutputDevice.speakerphone,
  /// ]
  /// ```
  final List<AndroidAudioOutputDevice>? preferredOutputOrder;

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (manageAudioFocus != null) 'manageAudioFocus': manageAudioFocus!,
        if (androidAudioMode != null)
          'androidAudioMode': androidAudioMode!.name,
        if (androidAudioFocusMode != null)
          'androidAudioFocusMode': androidAudioFocusMode!.name,
        if (androidAudioStreamType != null)
          'androidAudioStreamType': androidAudioStreamType!.name,
        if (androidAudioAttributesUsageType != null)
          'androidAudioAttributesUsageType':
              androidAudioAttributesUsageType!.name,
        if (androidAudioAttributesContentType != null)
          'androidAudioAttributesContentType':
              androidAudioAttributesContentType!.name,
        if (forceHandleAudioRouting != null)
          'forceHandleAudioRouting': forceHandleAudioRouting!,
        if (preferredOutputOrder != null)
          'androidPreferredOutputOrder':
              preferredOutputOrder!.map((d) => d.name).toList(),
      };

  /// A pre-configured AndroidAudioConfiguration for media playback.
  static final media = AndroidAudioConfiguration(
    manageAudioFocus: true,
    androidAudioMode: AndroidAudioMode.normal,
    androidAudioFocusMode: AndroidAudioFocusMode.gain,
    androidAudioStreamType: AndroidAudioStreamType.music,
    androidAudioAttributesUsageType: AndroidAudioAttributesUsageType.media,
    androidAudioAttributesContentType:
        AndroidAudioAttributesContentType.unknown,
  );

  /// A pre-configured AndroidAudioConfiguration for voice communication.
  static final communication = AndroidAudioConfiguration(
    manageAudioFocus: true,
    androidAudioMode: AndroidAudioMode.inCommunication,
    androidAudioFocusMode: AndroidAudioFocusMode.gain,
    androidAudioStreamType: AndroidAudioStreamType.voiceCall,
    androidAudioAttributesUsageType:
        AndroidAudioAttributesUsageType.voiceCommunication,
    androidAudioAttributesContentType: AndroidAudioAttributesContentType.speech,
  );
}

class AndroidNativeAudioManagement {
  static Future<void> setAndroidAudioConfiguration(
      AndroidAudioConfiguration config) async {
    if (WebRTC.platformIsAndroid) {
      await WebRTC.invokeMethod(
        'setAndroidAudioConfiguration',
        <String, dynamic>{'configuration': config.toMap()},
      );
    }
  }
}
