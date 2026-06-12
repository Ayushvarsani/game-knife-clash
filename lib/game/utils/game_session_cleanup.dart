import 'package:flutter/painting.dart';
import 'game_texture_cache.dart';

/// Frees all game GPU memory between play sessions.
class GameSessionCleanup {
  GameSessionCleanup._();

  static void afterSession() {
    GameTextureCache.clear();
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  }
}
