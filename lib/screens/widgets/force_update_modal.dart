import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'game_modal.dart';
import 'game_modal_icons.dart';
import 'knife_rush_logo.dart';

/// Android application id used to build the Play Store deep links.
const _kAndroidPackage = 'com.brainora.kniferush';

/// Default Play Store listing for this app.
const kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=$_kAndroidPackage';

/// Opens the Play Store app page, falling back to the browser listing.
Future<bool> openPlayStoreListing(String storeUrl) async {
  final webUri = Uri.parse(storeUrl);
  final packageId = webUri.queryParameters['id'] ?? _kAndroidPackage;
  final marketUri = Uri.parse('market://details?id=$packageId');

  final attempts = <({Uri uri, LaunchMode mode})>[
    (uri: marketUri, mode: LaunchMode.externalNonBrowserApplication),
    (uri: webUri, mode: LaunchMode.externalApplication),
    (uri: webUri, mode: LaunchMode.platformDefault),
  ];

  for (final attempt in attempts) {
    if (await _tryLaunch(attempt.uri, attempt.mode)) {
      return true;
    }
  }
  return false;
}

Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
  try {
    if (!await canLaunchUrl(uri)) return false;
    return await launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}

/// Bundled Rajdhani only — avoids fallback fonts that draw yellow underlines.
TextStyle _rushText({
  required double size,
  FontWeight weight = FontWeight.w600,
  Color color = Colors.white,
  double height = 1.2,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: TextDecoration.none,
    decorationColor: Colors.transparent,
  );
}

/// Blocking "update required" overlay. Cannot be dismissed.
class ForceUpdateModal extends StatefulWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final String storeUrl;

  const ForceUpdateModal({
    super.key,
    this.title = 'NEW UPDATE AVAILABLE',
    this.message =
        'A new version of Knife Rush is available. '
        'Please update the app to continue playing.',
    this.buttonLabel = 'UPDATE NOW',
    this.storeUrl = kPlayStoreUrl,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonLabel,
    String? storeUrl,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (context, _, _) => ForceUpdateModal(
        title: title ?? 'NEW UPDATE AVAILABLE',
        message: message ??
            'A new version of Knife Rush is available. '
                'Please update the app to continue playing.',
        buttonLabel: buttonLabel ?? 'UPDATE NOW',
        storeUrl: storeUrl ?? kPlayStoreUrl,
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ForceUpdateModal> createState() => _ForceUpdateModalState();
}

class _ForceUpdateModalState extends State<ForceUpdateModal>
    with SingleTickerProviderStateMixin {
  bool _launching = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openStore() async {
    if (_launching) return;
    setState(() => _launching = true);

    final opened = await openPlayStoreListing(widget.storeUrl);

    if (!opened && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the Play Store.',
            style: _rushText(size: 14, weight: FontWeight.w500),
          ),
        ),
      );
    }
    if (mounted) setState(() => _launching = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0406).withValues(alpha: 0.88),
                      const Color(0xFF1C0709).withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) => IgnorePointer(
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          KnifeRushBrandColors.flare.withValues(
                            alpha: 0.10 + _pulseAnim.value * 0.08,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _UpdateCard(
                    pulseAnim: _pulseAnim,
                    title: widget.title,
                    message: widget.message,
                    buttonLabel: widget.buttonLabel,
                    launching: _launching,
                    onUpdate: _openStore,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final Animation<double> pulseAnim;
  final String title;
  final String message;
  final String buttonLabel;
  final bool launching;
  final VoidCallback onUpdate;

  const _UpdateCard({
    required this.pulseAnim,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.launching,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: GameModalColors.accentOrange.withValues(alpha: 0.12),
              blurRadius: 40,
              spreadRadius: -4,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 32,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CustomPaint(
            painter: _UpdateCardFramePainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 148,
                    child: Image.asset(
                      AppAssets.knifeRushLogo,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (context, _) => _HeroIcon(pulse: pulseAnim.value),
                  ),
                  const SizedBox(height: 18),
                  _MandatoryBadge(),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: _rushText(
                      size: 28,
                      weight: FontWeight.w700,
                      color: GameModalColors.accentOrange,
                      letterSpacing: 1.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _GradientDivider(),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: _rushText(
                      size: 16,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _UpdateNowButton(
                    label: buttonLabel,
                    loading: launching,
                    onTap: onUpdate,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'You will be redirected to Google Play',
                    textAlign: TextAlign.center,
                    style: _rushText(
                      size: 12,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final double pulse;

  const _HeroIcon({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            GameModalColors.accentOrange.withValues(alpha: 0.22 + pulse * 0.12),
            GameModalColors.accentOrange.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: GameModalColors.accentOrange.withValues(alpha: 0.45 + pulse * 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: GameModalColors.accentOrange.withValues(alpha: 0.18 + pulse * 0.14),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: GameModalIcon(
          kind: GameModalIconKind.update,
          color: GameModalColors.accentOrange,
          size: 30,
        ),
      ),
    );
  }
}

class _MandatoryBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: GameModalColors.accentRed.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameModalColors.accentRed.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        'MANDATORY UPDATE',
        style: _rushText(
          size: 11,
          weight: FontWeight.w700,
          color: GameModalColors.titleRed,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            GameModalColors.accentOrange.withValues(alpha: 0.45),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _UpdateNowButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _UpdateNowButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_UpdateNowButton> createState() => _UpdateNowButtonState();
}

class _UpdateNowButtonState extends State<_UpdateNowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTap: widget.loading
          ? null
          : () {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: CustomPaint(
            painter: _UpdateButtonPainter(pressed: _pressed),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GameModalIcon(
                          kind: GameModalIconKind.update,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: _rushText(
                            size: 20,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateCardFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF221418), Color(0xFF120A0E), Color(0xFF1A1014)],
        ).createShader(rect),
    );

    canvas.drawRRect(
      r.deflate(1),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameModalColors.accentOrange,
            GameModalColors.accentRed,
            Color(0xFF6A1810),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UpdateButtonPainter extends CustomPainter {
  final bool pressed;

  _UpdateButtonPainter({required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pressed
              ? const [Color(0xFFE86A20), Color(0xFFC43818)]
              : const [Color(0xFFFF8A28), Color(0xFFFF5A2E)],
        ).createShader(rect),
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(4, 2, size.width - 8, size.height * 0.45),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: pressed ? 0.12 : 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _UpdateButtonPainter old) =>
      old.pressed != pressed;
}
