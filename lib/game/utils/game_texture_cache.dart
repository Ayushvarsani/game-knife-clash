import 'dart:ui' as ui;

/// Shared GPU textures for board / knife / fruit art.
///
/// Each stage used to rasterize a brand-new board texture (~2 MB). Twenty
/// stages × three play sessions = ~180 MB of textures before GC caught up,
/// which is why run 2 felt worse and run 3 hung on stage 1. One texture per
/// theme is cached and reused; everything is disposed when a session ends.
class GameTextureCache {
  GameTextureCache._();

  static final Map<String, ui.Image> _images = {};

  static ui.Image getOrCreate(String key, ui.Image Function() create) {
    final cached = _images[key];
    if (cached != null) return cached;
    final image = create();
    _images[key] = image;
    return image;
  }

  static void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }
}
