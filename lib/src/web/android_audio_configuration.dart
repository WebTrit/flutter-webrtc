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

  final bool? manageAudioFocus;
  final AndroidAudioMode? androidAudioMode;
  final AndroidAudioFocusMode? androidAudioFocusMode;
  final AndroidAudioStreamType? androidAudioStreamType;
  final AndroidAudioAttributesUsageType? androidAudioAttributesUsageType;
  final AndroidAudioAttributesContentType? androidAudioAttributesContentType;
  final bool? forceHandleAudioRouting;
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

  static final media = AndroidAudioConfiguration(
    manageAudioFocus: true,
    androidAudioMode: AndroidAudioMode.normal,
    androidAudioFocusMode: AndroidAudioFocusMode.gain,
    androidAudioStreamType: AndroidAudioStreamType.music,
    androidAudioAttributesUsageType: AndroidAudioAttributesUsageType.media,
    androidAudioAttributesContentType:
        AndroidAudioAttributesContentType.unknown,
  );

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
      AndroidAudioConfiguration config) async {}
}
