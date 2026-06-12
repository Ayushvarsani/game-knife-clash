import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:knife_hit_game/game/utils/angle_utils.dart';

void main() {
  group('normalizeAngle', () {
    test('zero stays zero', () => expect(normalizeAngle(0), 0));
    test('2*pi wraps to 0', () => expect(normalizeAngle(2 * pi), closeTo(0, 1e-10)));
    test('negative wraps into range', () {
      expect(normalizeAngle(-pi), closeTo(pi, 1e-10));
    });
    test('already in range is unchanged', () {
      expect(normalizeAngle(pi), closeTo(pi, 1e-10));
    });
  });

  group('shortestAngleDiff', () {
    test('identical angles = 0', () => expect(shortestAngleDiff(1.0, 1.0), 0));
    test('pi apart = pi', () => expect(shortestAngleDiff(0, pi), closeTo(pi, 1e-10)));
    test('wrap at 0/2pi is short', () {
      expect(shortestAngleDiff(0.1, 2 * pi - 0.1), closeTo(0.2, 1e-10));
    });
    test('always positive', () {
      expect(shortestAngleDiff(5.0, 1.0), greaterThanOrEqualTo(0));
    });
  });

  group('isAngleTooClose', () {
    test('empty list = never too close', () {
      expect(isAngleTooClose(1.0, [], 0.3), false);
    });
    test('exact match = too close', () {
      expect(isAngleTooClose(1.0, [1.0], 0.3), true);
    });
    test('at minGap boundary is NOT too close', () {
      expect(isAngleTooClose(1.3, [1.0], 0.3), false);
    });
    test('just inside minGap = too close', () {
      expect(isAngleTooClose(1.29, [1.0], 0.3), true);
    });
    test('wrap-around is handled', () {
      // 0.1 and 2*pi-0.1 are 0.2 apart across the wrap
      expect(isAngleTooClose(0.1, [2 * pi - 0.1], 0.3), true);
    });
  });
}
