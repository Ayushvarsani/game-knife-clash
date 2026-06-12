// Ads disabled — uncomment this file and main.dart to re-enable.

/*
import 'dart:developer' as developer;

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ensures the Mobile Ads SDK is initialized once before any ad loads.
class MobileAdsInitializer {
  MobileAdsInitializer._();

  static Future<void>? _initFuture;

  static const List<String> _testDeviceIds = <String>[
    // 'PASTE_YOUR_DEVICE_ID_FROM_LOGCAT_HERE',
  ];

  static Future<void> ensureInitialized() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  static Future<void> _initialize() async {
    if (_testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }

    final status = await MobileAds.instance.initialize();

    final adapters = status.adapterStatuses.entries
        .map((e) => '${e.key}=${e.value.state.name}')
        .join(', ');
    _log('MobileAds initialized. testDevices=$_testDeviceIds '
        'adapters=[$adapters]');
  }

  static void _log(String message) {
    developer.log(message, name: 'Ads');
  }
}
*/
