import 'dart:math';

/// Varied spin patterns for stage 10+ — cruise, half-turn, 1s sprint, gentle lift.
enum RhythmPhase { cruising, halfTurn, sprint, speedLift }

class BoardRhythmController {
  final Random random;
  RhythmPhase phase = RhythmPhase.cruising;
  double cruiseTimer = 0;
  double cruiseGap = 4.0;
  double phaseTimer = 0;
  double halfTurnRadiansDone = 0;

  static const double sprintSeconds = 1.0;
  static const double speedLiftSeconds = 2.4;
  static const double halfTurnTarget = pi;

  BoardRhythmController({Random? random}) : random = random ?? Random();

  bool get isActive => phase != RhythmPhase.cruising;

  void reset({double initialCruiseGap = 4.0}) {
    phase = RhythmPhase.cruising;
    cruiseTimer = 0;
    cruiseGap = initialCruiseGap;
    phaseTimer = 0;
    halfTurnRadiansDone = 0;
  }

  void _pickNextPhase() {
    final roll = random.nextDouble();
    if (roll < 0.35) {
      phase = RhythmPhase.halfTurn;
      halfTurnRadiansDone = 0;
    } else if (roll < 0.7) {
      phase = RhythmPhase.sprint;
      phaseTimer = 0;
    } else {
      phase = RhythmPhase.speedLift;
      phaseTimer = 0;
    }
  }

  /// Returns the rotation speed to use this frame.
  double tick({
    required double dt,
    required double baseSpeed,
    required double maxSpeed,
    double halfTurnMultiplier = 1.12,
    double sprintMultiplier = 1.55,
    double liftMultiplier = 1.1,
  }) {
    switch (phase) {
      case RhythmPhase.cruising:
        cruiseTimer += dt;
        if (cruiseTimer >= cruiseGap) {
          cruiseTimer = 0;
          cruiseGap = 3.2 + random.nextDouble() * 2.8;
          _pickNextPhase();
          return tick(
            dt: 0,
            baseSpeed: baseSpeed,
            maxSpeed: maxSpeed,
            halfTurnMultiplier: halfTurnMultiplier,
            sprintMultiplier: sprintMultiplier,
            liftMultiplier: liftMultiplier,
          );
        }
        return baseSpeed;

      case RhythmPhase.halfTurn:
        final speed =
            (baseSpeed * halfTurnMultiplier).clamp(0.0, maxSpeed);
        halfTurnRadiansDone += speed * dt;
        if (halfTurnRadiansDone >= halfTurnTarget) {
          phase = RhythmPhase.cruising;
          halfTurnRadiansDone = 0;
          cruiseTimer = 0;
          return baseSpeed;
        }
        return speed;

      case RhythmPhase.sprint:
        phaseTimer += dt;
        if (phaseTimer >= sprintSeconds) {
          phase = RhythmPhase.cruising;
          phaseTimer = 0;
          cruiseTimer = 0;
          return baseSpeed;
        }
        return (baseSpeed * sprintMultiplier).clamp(0.0, maxSpeed);

      case RhythmPhase.speedLift:
        phaseTimer += dt;
        if (phaseTimer >= speedLiftSeconds) {
          phase = RhythmPhase.cruising;
          phaseTimer = 0;
          cruiseTimer = 0;
          return baseSpeed;
        }
        return (baseSpeed * liftMultiplier).clamp(0.0, maxSpeed);
    }
  }
}
