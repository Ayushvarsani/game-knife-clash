import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:knife_hit_game/game/managers/stage_manager.dart';

void main() {
  group('StageManager session seeds', () {
    test('uses fixed run seed when provided', () {
      final manager = StageManager(fixedRunSeed: 12345);
      expect(manager.runSeed, 12345);
    });

    test('different seeded managers produce different stage 3 layouts', () {
      final a = StageManager(fixedRunSeed: 101);
      final b = StageManager(fixedRunSeed: 202);

      a.nextStage();
      a.nextStage();
      b.nextStage();
      b.nextStage();

      final ad = a.currentStageData;
      final bd = b.currentStageData;

      final same = ad.knivesCount == bd.knivesCount &&
          ad.rotationSpeed == bd.rotationSpeed &&
          ad.reverseDirection == bd.reverseDirection &&
          ad.directionChanges == bd.directionChanges &&
          ad.theme == bd.theme &&
          ad.applesCount == bd.applesCount;
      expect(same, false);
    });

    test('reset creates a new run seed for non-fixed runs', () {
      final manager = StageManager(runSeedRandom: Random(99));
      final before = manager.runSeed;
      manager.reset();
      final after = manager.runSeed;
      expect(after, isNot(before));
    });

    test('fixed run seed remains stable across reset', () {
      final manager = StageManager(fixedRunSeed: 777);
      manager.nextStage();
      manager.reset();
      expect(manager.runSeed, 777);
      expect(manager.currentStage, 1);
    });

    test('adjacent stages are not near-identical in one run', () {
      final manager = StageManager(fixedRunSeed: 424242);
      final first = manager.currentStageData;
      manager.nextStage();
      final second = manager.currentStageData;

      final identical = first.knivesCount == second.knivesCount &&
          first.applesCount == second.applesCount &&
          first.preStuckKnivesCount == second.preStuckKnivesCount &&
          first.reverseDirection == second.reverseDirection &&
          first.directionChanges == second.directionChanges &&
          first.hasSpeedBursts == second.hasSpeedBursts &&
          first.theme == second.theme &&
          (first.rotationSpeed - second.rotationSpeed).abs() < 0.2;
      expect(identical, false);
    });
  });

  group('StageManager throw/stuck invariants (deadlock guard)', () {
    test('every successful stick keeps remaining and stuck aligned', () {
      final m = StageManager(fixedRunSeed: 555);
      final total = m.currentStageData.knivesCount;
      for (int i = 0; i < total; i++) {
        m.knifeThrown();
        m.knifeStuck();
      }
      expect(m.knivesRemaining, 0);
      expect(m.isStageComplete, true);
    });

    test('a rolled-back miss returns the throw so the stage can still finish', () {
      final m = StageManager(fixedRunSeed: 556);
      final total = m.currentStageData.knivesCount;
      // Throw all but one successfully.
      for (int i = 0; i < total - 1; i++) {
        m.knifeThrown();
        m.knifeStuck();
      }
      // Last throw misses (overshoot) and is rolled back — must NOT consume it.
      m.knifeThrown();
      m.rollbackThrow();
      expect(m.knivesRemaining, 1, reason: 'rolled-back throw must be returned');
      expect(m.isStageComplete, false);
      // Now land it for real.
      m.knifeThrown();
      m.knifeStuck();
      expect(m.knivesRemaining, 0);
      expect(m.isStageComplete, true);
    });

    test('all throws used but not all stuck is a detectable deadlock state', () {
      final m = StageManager(fixedRunSeed: 557);
      final total = m.currentStageData.knivesCount;
      // Simulate the desync: throws consumed without matching sticks.
      for (int i = 0; i < total; i++) {
        m.knifeThrown();
      }
      // This is the exact state that used to strand an un-throwable knife:
      // no throws left, yet the stage is not "complete" by stuck-count.
      expect(m.knivesRemaining, 0);
      expect(m.isStageComplete, false);
      // KnifeHitGame._spawnKnife now detects (knivesRemaining<=0) and ends the
      // stage instead of loading a knife that can never be thrown.
    });
  });
}
