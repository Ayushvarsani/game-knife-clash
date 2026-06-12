import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:knife_hit_game/game/rules/collision_rules.dart';
import 'package:knife_hit_game/game/utils/constants.dart';

void main() {
  group('effectiveMinAngle', () {
    test('0 stuck knives = max (minAngleBetweenKnives)', () {
      expect(effectiveMinAngle(0), GameConstants.minAngleBetweenKnives);
    });
    test('3 stuck knives = max (no reduction yet)', () {
      expect(effectiveMinAngle(3), GameConstants.minAngleBetweenKnives);
    });
    test('4 stuck knives = max - 0.005', () {
      expect(effectiveMinAngle(4),
          closeTo(GameConstants.minAngleBetweenKnives - 0.005, 1e-10));
    });
    test('floored at 0.15', () {
      expect(effectiveMinAngle(1000), greaterThanOrEqualTo(0.15));
    });
  });

  group('knifeCollidesWithStuck', () {
    test('empty board = no collision', () {
      expect(knifeCollidesWithStuck(1.0, []), false);
    });
    test('identical angles = collision', () {
      expect(knifeCollidesWithStuck(1.0, [1.0]), true);
    });
    test('just beyond effectiveMinAngle boundary = no collision', () {
      final minAngle = effectiveMinAngle(1);
      expect(knifeCollidesWithStuck(1.0, [1.0 + minAngle + 0.001]), false);
    });
    test('just inside minAngle = collision', () {
      final minAngle = effectiveMinAngle(1);
      expect(knifeCollidesWithStuck(1.0, [1.0 + minAngle - 0.001]), true);
    });
  });

  group('isPerfectThrow', () {
    test('no stuck knives = not perfect', () {
      expect(isPerfectThrow(1.0, [], 0.0), false);
    });
    test('knife in wide-open gap = perfect', () {
      // Two knives at 0 and pi — needle at pi/2 has pi/2 clearance on each side
      final stuckRel = [0.0, pi];
      expect(isPerfectThrow(pi / 2, stuckRel, 0.0, perfectGap: 0.45), true);
    });
    test('knife squeezed between two close knives = not perfect', () {
      // Knives at 1.0 and 1.5 — needle at 1.25 has only 0.25 clearance
      final stuckRel = [1.0, 1.5];
      expect(isPerfectThrow(1.25, stuckRel, 0.0, perfectGap: 0.45), false);
    });
    test('board rotation is accounted for', () {
      // Stuck knives at relative 0 and pi, board rotated by pi/4.
      // World angles: pi/4 and 5*pi/4. Needle at 3*pi/4 is equidistant.
      final stuckRel = [0.0, pi];
      const boardAngle = pi / 4;
      expect(isPerfectThrow(3 * pi / 4, stuckRel, boardAngle, perfectGap: 0.45), true);
    });
  });

  group('arc capacity invariant', () {
    test('stage layout must fit within 2*pi', () {
      const minAngle = 0.20;
      // Simulate a stage with 10 knives and 3 pre-stuck — total 13
      const total = 13;
      expect(total * minAngle, lessThanOrEqualTo(2 * pi));
    });
  });
}
