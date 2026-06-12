import 'package:flame/components.dart';
import '../components/knife.dart';

/// Pure rules for when taps launch vs buffer a knife throw.
/// Keeps [KnifeHitGame] from duplicating booleans that can desync.
class KnifeThrowLogic {
  KnifeThrowLogic._();

  static const double spawnMatchDistance = 24;

  static bool isAtSpawn(Vector2 knifePosition, Vector2 spawnPosition) {
    return knifePosition.distanceTo(spawnPosition) <= spawnMatchDistance;
  }

  static bool canThrowNow({
    required bool isPlaying,
    required int knivesRemaining,
    required KnifeState knifeState,
    required bool knifeReadyAtSpawn,
  }) {
    if (!isPlaying || knivesRemaining <= 0) return false;
    if (knifeState == KnifeState.collided) return false;
    return knifeState == KnifeState.idle && knifeReadyAtSpawn;
  }

  static bool shouldBufferTap({
    required bool isPlaying,
    required int knivesRemaining,
    required KnifeState knifeState,
  }) {
    if (!isPlaying || knivesRemaining <= 0) return false;
    return knifeState == KnifeState.flying;
  }

  /// After a stick/miss the knife is parked off-screen until spawn makes it ready.
  static bool needsSpawnBeforeThrow({
    required KnifeState knifeState,
    required bool knifeReadyAtSpawn,
    required Vector2 knifePosition,
    required Vector2 spawnPosition,
  }) {
    if (knifeState == KnifeState.flying) return false;
    if (knifeReadyAtSpawn) return false;
    return knifeState != KnifeState.idle ||
        !isAtSpawn(knifePosition, spawnPosition);
  }
}
