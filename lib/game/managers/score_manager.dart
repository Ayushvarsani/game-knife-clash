import 'high_score_manager.dart';

class ScoreManager {
  int _score = 0;
  int _apples = 0;
  int _comboStreak = 0;
  int _lastKnifePoints = 0;

  final HighScoreManager highScoreManager = HighScoreManager();

  int get score => _score;
  int get apples => _apples;
  int get comboStreak => _comboStreak;
  /// Combo tier: 0 = no streak, 1 = 3–5 knives, 2 = 6–8 knives, 3 = 9+ knives.
  int get comboTier => _comboStreak < 3 ? 0 : (_comboStreak < 6 ? 1 : (_comboStreak < 9 ? 2 : 3));
  int get lastKnifePoints => _lastKnifePoints;
  int get highScore => highScoreManager.highScore;

  Future<void> loadHighScore() => highScoreManager.load();

  int addKnifeScore() {
    _comboStreak++;
    _score += 1;
    _lastKnifePoints = 1;
    return 1;
  }

  void addAppleScore() {
    _score += 5;
    _apples += 1;
    // Apple does NOT reset combo — it's a bonus, not a miss
  }

  // Kept for backward compatibility; strict mode does not award perfect bonus score.
  int addPerfectScore() {
    return 0;
  }

  // Kept for backward compatibility; strict mode does not award clean-shot score.
  int addCleanShotScore() {
    return 0;
  }

  // Kept for backward compatibility; strict mode does not award goal bonus score.
  void addGoalBonus(int bonus) {}

  void resetCombo() {
    _comboStreak = 0;
    _lastKnifePoints = 0;
  }

  void addStartScore(int score) => _score += score;

  void reset() {
    _score = 0;
    _apples = 0;
    _comboStreak = 0;
    _lastKnifePoints = 0;
  }
}
