import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Rasterizes vector art into a GPU texture once.
///
/// A cached [ui.Picture] still re-executes every draw command (gradients,
/// blurs, paths) on the GPU each frame. Replayed for the rotating board and a
/// dozen stuck knives/fruit per frame, that sustained shader load heats the
/// device and throttles it — the in-play stutter + input lag after minutes.
/// An [ui.Image] is a single textured quad, so repeated frames are cheap.
class PictureRaster {
  PictureRaster._();

  /// Device pixel ratio, clamped so textures stay crisp without over-allocating.
  static double deviceScale({double max = 1.5}) {
    double dpr = 2.0;
    try {
      dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    } catch (_) {}
    return dpr.clamp(1.0, max);
  }

  /// Rasterizes [paint] (which draws in logical [width]x[height] space) into an
  /// image with [pad] margin on every side, at [scale] resolution.
  static ui.Image rasterize({
    required double width,
    required double height,
    required double pad,
    required double scale,
    required void Function(Canvas canvas) paint,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    canvas.translate(pad, pad);
    paint(canvas);
    final picture = recorder.endRecording();
    final wPx = ((width + pad * 2) * scale).ceil();
    final hPx = ((height + pad * 2) * scale).ceil();
    final image = picture.toImageSync(wPx, hPx);
    picture.dispose();
    return image;
  }

  /// Draws a texture produced by [rasterize] back at its original logical
  /// position, accounting for the padding and resolution scale.
  static void drawTexture(
    Canvas canvas,
    ui.Image image, {
    required double pad,
    required double scale,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(-pad, -pad);
    canvas.scale(1 / scale);
    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();
  }
}
