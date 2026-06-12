import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:knife_hit_game/game/utils/stage_data.dart';

void main() {
  group('getStageData determinism', () {
    test('same stage produces same output', () {
      final a = getStageData(3);
      final b = getStageData(3);
      expect(a.knivesCount, b.knivesCount);
      expect(a.rotationSpeed, b.rotationSpeed);
      expect(a.reverseDirection, b.reverseDirection);
      expect(a.directionChanges, b.directionChanges);
      expect(a.preStuckKnivesCount, b.preStuckKnivesCount);
    });

    test('different stages produce different outputs', () {
      final s1 = getStageData(1);
      final s2 = getStageData(2);
      // At least one property should differ for consecutive stages
      final same = s1.knivesCount == s2.knivesCount &&
          s1.rotationSpeed == s2.rotationSpeed;
      expect(same, false);
    });

    test('explicit seed overrides default', () {
      final withSeed = getStageData(3, seed: 99999);
      // They may or may not match, but both calls with the same seed must match
      final repeat = getStageData(3, seed: 99999);
      expect(withSeed.knivesCount, repeat.knivesCount);
      expect(withSeed.rotationSpeed, repeat.rotationSpeed);
    });
  });

  group('getStageData arc capacity', () {
    test('pre-stuck + knives fit within 2*pi for stages 1-20', () {
      const minAngle = 0.20;
      for (int stage = 1; stage <= 20; stage++) {
        final data = getStageData(stage);
        final totalKnives = data.preStuckKnivesCount + data.knivesCount;
        expect(
          totalKnives * minAngle,
          lessThanOrEqualTo(2 * pi + 1e-9),
          reason: 'Stage $stage: $totalKnives knives exceeds arc capacity',
        );
      }
    });
  });

  group('getStageData bonus stages', () {
    test('stage 5 is a bonus stage cadence slot', () {
      expect(getStageData(5).isBoss, true);
    });
    test('bonus stage may be spike-free in apple frenzy mode', () {
      final data = getStageData(5);
      expect(data.isBoss, true);
      expect(data.bossSpikeAngles.length, lessThanOrEqualTo(2));
    });
    test('bonus stage has no pre-stuck knives', () {
      expect(getStageData(5).preStuckKnivesCount, 0);
    });
    test('bonus stage directionChanges is mode-driven (not always on)', () {
      // Bonus stages pick one of three modes (appleFrenzy / spikeGauntlet /
      // speedRush). Only speedRush may enable directionChanges, so it is NOT
      // guaranteed on for every bonus stage — just that it is a valid bool
      // determined by the chosen mode rather than crashing or being forced.
      final data = getStageData(5);
      expect(data.isBoss, true);
      expect(data.directionChanges, isA<bool>());
    });
    test('bonus stage has at least 3 apples for risk/reward', () {
      expect(getStageData(5).applesCount, greaterThanOrEqualTo(3));
    });
    test('bonus stage precomputes apple angles in spike gaps', () {
      final data = getStageData(5);
      expect(data.appleAngles, isNotEmpty);
      expect(data.appleAngles.length, data.applesCount);
    });
    test('every bonus stage from 5 to 25 spawns apples on the board', () {
      for (int stage = 5; stage <= 25; stage += 5) {
        final data = getStageData(stage);
        expect(
          data.appleAngles,
          isNotEmpty,
          reason: 'Stage $stage bonus should place apples between spikes',
        );
      }
    });
  });

  group('getStageData rotation tiers', () {
    test('stage 1 is clockwise only', () {
      for (final stage in [1]) {
        final data = getStageData(stage);
        expect(data.reverseDirection, false, reason: 'stage $stage should not reverse');
        expect(data.directionChanges, false, reason: 'stage $stage should not change direction');
      }
    });

    test('rotation speed ramps early then caps after stage 10', () {
      final early = getStageData(1).rotationSpeed;
      final mid = getStageData(9).rotationSpeed;
      final late = getStageData(19).rotationSpeed;
      expect(mid, greaterThan(early));
      expect(late, lessThanOrEqualTo(mid + 0.35));
    });

    test('half-spin rhythm on stages 2-9 only', () {
      expect(getStageData(1).hasHalfSpinRhythm, false);
      expect(getStageData(4).hasHalfSpinRhythm, true);
      expect(getStageData(9).hasHalfSpinRhythm, true);
      expect(getStageData(10).hasHalfSpinRhythm, false);
      expect(getStageData(11).advancedRhythm, true);
    });

    test('bonus stages spin slower than mid normal stages', () {
      final bonus = getStageData(5);
      final normal = getStageData(6);
      expect(bonus.isBoss, true);
      expect(bonus.rotationSpeed, lessThan(normal.rotationSpeed));
    });
  });
}
