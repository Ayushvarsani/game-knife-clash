// Ads disabled — uncomment this file and main.dart / game_over_screen to re-enable.

/*
import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_unit_ids.dart';
import 'mobile_ads_initializer.dart';

/// Loads and shows rewarded video ads.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void _log(String message) => developer.log(message, name: 'Ads');

  void preload() {
    if (_rewardedAd != null || _isLoading) return;
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (_isLoading) return;
    _isLoading = true;
    await MobileAdsInitializer.ensureInitialized();
    _log('Loading rewarded ad. unit=${AdUnitIds.rewardedId}');
    RewardedAd.load(
      adUnitId: AdUnitIds.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          _log('Rewarded ad LOADED.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          _log('Rewarded ad FAILED TO LOAD. '
              'code=${error.code} domain=${error.domain} '
              'message=${error.message}');
        },
      ),
    );
  }

  Future<bool> show() async {
    final ad = _rewardedAd;
    if (ad == null) {
      _log('show() called but no ad is ready — kicking off a load.');
      preload();
      return false;
    }

    _rewardedAd = null;

    final completer = Completer<bool>();
    var rewarded = false;
    var shown = false;

    void finish(bool result) {
      _log('Rewarded flow finishing. success=$result rewarded=$rewarded');
      ad.dispose();
      if (!completer.isCompleted) completer.complete(result);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        shown = true;
        _log('Rewarded ad SHOWED.');
      },
      onAdDismissedFullScreenContent: (_) {
        _log('Rewarded ad DISMISSED. shown=$shown rewardedSoFar=$rewarded');
        finish(shown || rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _log('Rewarded ad FAILED TO SHOW. '
            'code=${err.code} domain=${err.domain} message=${err.message}');
        finish(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          rewarded = true;
          _log('User EARNED REWARD: ${reward.amount} ${reward.type}');
        },
      );
    } catch (e, st) {
      _log('Rewarded ad show() threw: $e\n$st');
      finish(false);
    }

    return completer.future;
  }

  bool get isReady => _rewardedAd != null;

  Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (isReady) return true;
    preload();

    const tick = Duration(milliseconds: 200);
    var waited = Duration.zero;
    while (!isReady && waited < timeout) {
      await Future<void>.delayed(tick);
      waited += tick;
      if (!isReady) preload();
    }
    return isReady;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
  }
}
*/
