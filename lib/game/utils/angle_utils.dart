import 'dart:math';

/// Normalises [angle] to [0, 2*pi).
double normalizeAngle(double angle) {
  double a = angle % (2 * pi);
  if (a < 0) a += 2 * pi;
  return a;
}

/// Shortest angular distance between two angles (always positive, in [0, pi]).
double shortestAngleDiff(double a, double b) {
  double diff = (a - b).abs() % (2 * pi);
  if (diff > pi) diff = 2 * pi - diff;
  return diff;
}

/// Returns true if [angle] is within [minGap] radians of any angle in [existing].
bool isAngleTooClose(double angle, List<double> existing, double minGap) {
  for (final a in existing) {
    if (shortestAngleDiff(angle, a) < minGap) return true;
  }
  return false;
}
