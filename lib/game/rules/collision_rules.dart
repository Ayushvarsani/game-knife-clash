import 'dart:math';
import '../utils/angle_utils.dart';
import '../utils/constants.dart';

/// Computes effective minimum angle between knives as more fill the board.
/// Shrinks slowly so late-stage boards stay playable for casual users.
double effectiveMinAngle(int stuckCount) {
  final extraKnives = (stuckCount - 4).clamp(0, 999);
  return (GameConstants.minAngleBetweenKnives - extraKnives * 0.003)
      .clamp(0.20, GameConstants.minAngleBetweenKnives);
}

/// Returns true if [knifeAngle] collides with any knife in [stuckAngles].
/// [difficultyMultiplier] scales the minimum gap: <1.0 is forgiving (easy),
/// >1.0 is punishing (hard).
bool knifeCollidesWithStuck(
  double knifeAngle,
  List<double> stuckAngles, {
  double difficultyMultiplier = 1.0,
}) {
  final minAngle = effectiveMinAngle(stuckAngles.length) * difficultyMultiplier;
  for (final angle in stuckAngles) {
    if (shortestAngleDiff(knifeAngle, angle) < minAngle) return true;
  }
  return false;
}

/// Returns true if the knife landed in a "perfect" gap (>= [perfectGap] rad
/// clearance on both sides from every stuck knife).
bool isPerfectThrow(double knifeAngle, List<double> stuckRelAngles, double boardAngle,
    {double perfectGap = 0.45}) {
  if (stuckRelAngles.isEmpty) return false;

  final stuckAngles = stuckRelAngles
      .map((a) => normalizeAngle(a + boardAngle))
      .toList()
    ..sort();

  final needle = normalizeAngle(knifeAngle);

  int lo = 0, hi = stuckAngles.length;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    if (stuckAngles[mid] < needle) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  final prevIdx = (lo - 1 + stuckAngles.length) % stuckAngles.length;
  final nextIdx = lo % stuckAngles.length;

  double gapCCW = (needle - stuckAngles[prevIdx]) % (2 * pi);
  if (gapCCW < 0) gapCCW += 2 * pi;
  double gapCW = (stuckAngles[nextIdx] - needle) % (2 * pi);
  if (gapCW < 0) gapCW += 2 * pi;

  return gapCCW >= perfectGap && gapCW >= perfectGap;
}

