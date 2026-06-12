// Ads disabled — uncomment this file and game_over_screen.dart to re-enable.

/*
import 'package:flutter/material.dart';

import '../../screens/widgets/game_modal.dart';
import '../../screens/widgets/game_modal_icons.dart';
import '../services/rewarded_ad_service.dart';

/// Game-over button that shows a rewarded video ad before continuing.
class KeepPlayingButton extends StatefulWidget {
  final VoidCallback onRewarded;

  const KeepPlayingButton({
    super.key,
    required this.onRewarded,
  });

  @override
  State<KeepPlayingButton> createState() => _KeepPlayingButtonState();
}

class _KeepPlayingButtonState extends State<KeepPlayingButton> {
  bool _isShowingAd = false;

  Future<void> _handleTap() async {
    if (_isShowingAd) return;
    setState(() => _isShowingAd = true);

    final ready = await RewardedAdService.instance.waitUntilReady();
    if (!mounted) return;

    if (!ready) {
      _showUnavailable();
      widget.onRewarded();
      return;
    }

    final watched = await RewardedAdService.instance.show();

    if (!mounted) return;

    if (watched) {
      widget.onRewarded();
      return;
    }

    _showUnavailable();
    widget.onRewarded();
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ad not available — continuing your game.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameModalButton(
      label: 'KEEP PLAYING',
      color: GameModalColors.accentPurple,
      icon: GameModalIconKind.keepPlaying,
      loading: _isShowingAd,
      onTap: _handleTap,
    );
  }
}
*/
