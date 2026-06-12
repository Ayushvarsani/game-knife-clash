import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  bool _soundEnabled = true;

  // Shared across every KnifeHitGame instance — pools and the audio cache are
  // created once. Previously each new run disposed and re-created native
  // AudioPlayers, which leaked native memory and caused lag on the 3rd/4th
  // play session without killing the app.
  static bool _cacheLoaded = false;
  static final Map<String, AudioPool> _sharedPools = {};

  static const Map<String, int> _pooledSfx = {
    'knife_throw.mp3': 3,
    'knife_hit.mp3': 3,
    'knife_hit_knife.mp3': 2,
    'apple_collect.mp3': 4,
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('settings_sound') ?? true;
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      await FlameAudio.audioCache.loadAll([
        'bg_music.mp3',
        'knife_hit.mp3',
        'knife_hit_knife.mp3',
        'knife_throw.mp3',
        'apple_collect.mp3',
        'board_break.mp3',
        'stage_complete.mp3',
      ]);
      for (final entry in _pooledSfx.entries) {
        try {
          _sharedPools[entry.key] = await FlameAudio.createPool(
            entry.key,
            minPlayers: 1,
            maxPlayers: entry.value,
          );
        } catch (_) {}
      }
    } catch (_) {
      // Audio files not present — sounds silently disabled
    }
  }

  Future<void> startBgMusic() async {
    if (!_soundEnabled) return;
    try {
      await FlameAudio.bgm.play('bg_music.mp3', volume: 0.4);
    } catch (_) {}
  }

  void stopBgMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  void pauseBgMusic() {
    try {
      FlameAudio.bgm.pause();
    } catch (_) {}
  }

  void resumeBgMusic() {
    if (!_soundEnabled) return;
    try {
      FlameAudio.bgm.resume();
    } catch (_) {}
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      stopBgMusic();
    } else {
      startBgMusic();
    }
  }

  void playThrow() => _play('knife_throw.mp3', volume: 0.6);
  void playHit() => _play('knife_hit.mp3', volume: 0.9);
  void playHitKnife() => _play('knife_hit_knife.mp3', volume: 1.0);
  void playApple() => _play('apple_collect.mp3', volume: 0.7);
  void playGameOver() => _play('knife_hit_knife.mp3', volume: 1.0);
  void playBoardBreak() => _play('board_break.mp3', volume: 1.0);
  void playStageComplete() => _play('stage_complete.mp3', volume: 0.8);

  void _play(String file, {double volume = 1.0}) {
    if (!_soundEnabled) return;
    try {
      final pool = _sharedPools[file];
      if (pool != null) {
        pool.start(volume: volume);
      } else {
        FlameAudio.play(file, volume: volume);
      }
    } catch (_) {}
  }

  /// Stops music for this session only — shared pools stay alive for the next run.
  void dispose() {
    stopBgMusic();
  }
}
