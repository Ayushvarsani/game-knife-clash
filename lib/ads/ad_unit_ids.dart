import 'dart:io';

// import 'package:flutter/foundation.dart';

/// Central place for all Google AdMob unit IDs.
/// Ads are disabled in the app UI — test IDs are kept here for when ads are re-enabled.
class AdUnitIds {
  AdUnitIds._();

  // Live IDs — disabled while ads are commented out.
  // static const String appId = 'ca-app-pub-7594538790246658~8235505825';
  // static const String banner = 'ca-app-pub-7594538790246658/3444054006';
  // static const String rewarded = 'ca-app-pub-7594538790246658/6798301079';

  // Google sample / test IDs.
  static const String androidTestAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String androidTestBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String androidTestRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosTestRewarded =
      'ca-app-pub-3940256099942544/1712485313';

  static String get appId =>
      Platform.isAndroid ? androidTestAppId : iosTestAppId;

  static String get bannerId =>
      Platform.isAndroid ? androidTestBanner : iosTestBanner;

  static String get rewardedId =>
      Platform.isAndroid ? androidTestRewarded : iosTestRewarded;

  // static String get bannerId {
  //   if (kDebugMode) {
  //     return Platform.isAndroid ? androidTestBanner : iosTestBanner;
  //   }
  //   return banner;
  // }
  //
  // static String get rewardedId {
  //   if (kDebugMode) {
  //     return Platform.isAndroid ? androidTestRewarded : iosTestRewarded;
  //   }
  //   return rewarded;
  // }
}
