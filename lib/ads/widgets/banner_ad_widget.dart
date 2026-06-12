// Ads disabled — uncomment this file and home_screen / game_screen to re-enable.

/*
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_unit_ids.dart';
import '../services/mobile_ads_initializer.dart';
import '../../screens/widgets/stripe_background.dart';

/// Displays an anchored adaptive banner ad at the bottom of its parent.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const _fallbackHeight = 50.0;
  static const _maxRetries = 3;

  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retryCount = 0;
  bool _disposed = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    await MobileAdsInitializer.ensureInitialized();
    if (_disposed || !mounted) return;

    final width = MediaQuery.of(context).size.width.truncate();
    final adSize = await _adaptiveSize(width);
    if (_disposed || !mounted) return;

    final size = adSize ?? AdSize.banner;

    final banner = BannerAd(
      adUnitId: AdUnitIds.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_disposed || !mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _retryCount = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (_disposed) return;
          debugPrint('Banner ad failed: ${error.message} [code ${error.code}]');
          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(Duration(seconds: _retryCount * 2), () {
              if (!_disposed) _loadBanner();
            });
          }
        },
      ),
    );

    await banner.load();
  }

  Future<AnchoredAdaptiveBannerAdSize?> _adaptiveSize(int width) {
    return AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      Orientation.portrait,
      width,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    final canShowAd = ad != null && _isLoaded;
    final height =
        canShowAd ? ad.size.height.toDouble() : _fallbackHeight;

    return StripeBackground(
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: canShowAd
              ? Center(
                  child: SizedBox(
                    width: ad.size.width.toDouble(),
                    height: ad.size.height.toDouble(),
                    child: AdWidget(ad: ad),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
*/
