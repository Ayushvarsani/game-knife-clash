import 'package:flutter/material.dart';
import '../../game/utils/collectible_type.dart';
import '../../game/utils/collectible_renderer.dart';

enum CollectibleIconStyle {
  /// In-game fruit pickup shape.
  fruit,
  /// Gold star coin for lifetime / HUD counters.
  tally,
}

/// Small collectible icon for Flutter UI (home screen, etc.).
class CollectibleIcon extends StatelessWidget {
  final CollectibleType type;
  final CollectibleIconStyle style;
  final double size;

  const CollectibleIcon({
    super.key,
    this.type = CollectibleType.apple,
    this.style = CollectibleIconStyle.tally,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CollectibleIconPainter(type: type, style: style),
    );
  }
}

class _CollectibleIconPainter extends CustomPainter {
  final CollectibleType type;
  final CollectibleIconStyle style;

  _CollectibleIconPainter({required this.type, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    if (style == CollectibleIconStyle.tally) {
      CollectibleRenderer.drawTallyBadge(canvas, center, radius);
      return;
    }
    CollectibleRenderer.draw(canvas, center, radius, type: type);
  }

  @override
  bool shouldRepaint(covariant _CollectibleIconPainter old) =>
      old.type != type || old.style != style;
}
