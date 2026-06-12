import 'package:shared_preferences/shared_preferences.dart';

class HighScoreManager {
  static const _keyHighScore = 'high_score';

  int _highScore = 0;
  bool _dirty = false;

  int get highScore => _highScore;
  bool get isDirty => _dirty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_keyHighScore) ?? 0;
    _dirty = false;
  }

  /// Updates in-memory high score only. Disk write happens at the next checkpoint [flush].
  bool markIfBetter(int score) {
    if (score <= _highScore) return false;
    _highScore = score;
    _dirty = true;
    return true;
  }

  Future<void> persistIfDirty(SharedPreferences prefs) async {
    if (!_dirty) return;
    await prefs.setInt(_keyHighScore, _highScore);
    _dirty = false;
  }

  /// Standalone immediate save — used only outside batched gameplay checkpoints.
  Future<bool> saveIfBetter(int score) async {
    if (!markIfBetter(score)) return false;
    final prefs = await SharedPreferences.getInstance();
    await persistIfDirty(prefs);
    return true;
  }
}
