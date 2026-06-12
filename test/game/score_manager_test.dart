import 'package:flutter_test/flutter_test.dart';
import 'package:knife_hit_game/game/managers/score_manager.dart';

void main() {
  group('ScoreManager strict scoring', () {
    test('knife score is always +1', () {
      final score = ScoreManager();
      expect(score.addKnifeScore(), 1);
      expect(score.score, 1);
      expect(score.addKnifeScore(), 1);
      expect(score.score, 2);
      expect(score.comboStreak, 2);
    });

    test('apple score is always +5', () {
      final score = ScoreManager();
      score.addAppleScore();
      expect(score.score, 5);
      expect(score.apples, 1);
      score.addAppleScore();
      expect(score.score, 10);
      expect(score.apples, 2);
    });

    test('perfect/clean/goal bonus methods do not add score', () {
      final score = ScoreManager();
      score.addKnifeScore(); // +1 baseline
      expect(score.addPerfectScore(), 0);
      expect(score.addCleanShotScore(), 0);
      score.addGoalBonus(25);
      expect(score.score, 1);
    });
  });
}
