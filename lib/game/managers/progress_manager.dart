import 'package:shared_preferences/shared_preferences.dart';
import 'high_score_manager.dart';

/// Persists long-term player progress across sessions.
///
/// During active gameplay all updates stay in memory only. Disk writes happen
/// at checkpoints (stage complete, game over, pause, exit) via [flush].
class ProgressManager {
  static const _keyLifetimeApples = 'progress_lifetime_apples';
  static const _keyUnlockedSkins = 'progress_unlocked_skins';
  static const _keyLastStage = 'progress_last_stage';
  static const _keyDailyDate = 'progress_daily_date';
  static const _keyDailyBest = 'progress_daily_best';

  int _lifetimeApples = 0;
  List<String> _unlockedSkinIds = ['default'];
  int _lastPlayedStage = 1;
  String _dailyChallengeDate = '';
  int _dailyBestScore = 0;

  bool _applesDirty = false;
  bool _stageDirty = false;

  int get lifetimeApples => _lifetimeApples;
  List<String> get unlockedSkinIds => List.unmodifiable(_unlockedSkinIds);
  int get lastPlayedStage => _lastPlayedStage;
  String get dailyChallengeDate => _dailyChallengeDate;
  int get dailyBestScore => _dailyBestScore;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lifetimeApples = prefs.getInt(_keyLifetimeApples) ?? 0;
    _unlockedSkinIds = prefs.getStringList(_keyUnlockedSkins) ?? ['default'];
    _lastPlayedStage = prefs.getInt(_keyLastStage) ?? 1;
    _dailyChallengeDate = prefs.getString(_keyDailyDate) ?? '';
    _dailyBestScore = prefs.getInt(_keyDailyBest) ?? 0;
  }

  /// Memory only — persisted at the next [flush] checkpoint.
  void addApples(int count) {
    _lifetimeApples += count;
    _applesDirty = true;
  }

  Future<void> spendApples(int count) async {
    _lifetimeApples = (_lifetimeApples - count).clamp(0, _lifetimeApples);
    _applesDirty = true;
    await flush();
  }

  Future<void> unlockSkin(String skinId) async {
    if (_unlockedSkinIds.contains(skinId)) return;
    _unlockedSkinIds = [..._unlockedSkinIds, skinId];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyUnlockedSkins, _unlockedSkinIds);
  }

  /// Memory only — persisted at the next [flush] checkpoint.
  void saveLastStage(int stage) {
    _lastPlayedStage = stage;
    _stageDirty = true;
  }

  /// Returns true if [score] is a new daily best for [dateKey] (format: yyyyMMdd).
  Future<bool> saveDailyScore(String dateKey, int score) async {
    final isNewDate = dateKey != _dailyChallengeDate;
    final isNewBest = isNewDate || score > _dailyBestScore;
    if (isNewBest) {
      _dailyChallengeDate = dateKey;
      _dailyBestScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDailyDate, _dailyChallengeDate);
      await prefs.setInt(_keyDailyBest, _dailyBestScore);
    }
    return isNewBest;
  }

  /// Single batched disk write for apples, last stage, and optional high score.
  Future<void> flush({HighScoreManager? highScore}) async {
    final highScoreDirty = highScore?.isDirty ?? false;
    if (!_applesDirty && !_stageDirty && !highScoreDirty) return;

    final prefs = await SharedPreferences.getInstance();
    if (_applesDirty) {
      await prefs.setInt(_keyLifetimeApples, _lifetimeApples);
      _applesDirty = false;
    }
    if (_stageDirty) {
      await prefs.setInt(_keyLastStage, _lastPlayedStage);
      _stageDirty = false;
    }
    if (highScore != null) {
      await highScore.persistIfDirty(prefs);
    }
  }

  void dispose() {}

  bool isSkinUnlocked(String skinId) => _unlockedSkinIds.contains(skinId);
}
