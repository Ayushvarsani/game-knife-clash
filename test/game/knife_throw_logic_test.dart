import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knife_hit_game/game/components/knife.dart';
import 'package:knife_hit_game/game/logic/knife_throw_logic.dart';

void main() {
  final spawn = Vector2(100, 500);

  group('KnifeThrowLogic.canThrowNow', () {
    test('idle and ready with knives left', () {
      expect(
        KnifeThrowLogic.canThrowNow(
          isPlaying: true,
          knivesRemaining: 3,
          knifeState: KnifeState.idle,
          knifeReadyAtSpawn: true,
        ),
        true,
      );
    });

    test('blocked while flying', () {
      expect(
        KnifeThrowLogic.canThrowNow(
          isPlaying: true,
          knivesRemaining: 3,
          knifeState: KnifeState.flying,
          knifeReadyAtSpawn: false,
        ),
        false,
      );
    });

    test('blocked when idle but not ready (parked off-screen)', () {
      expect(
        KnifeThrowLogic.canThrowNow(
          isPlaying: true,
          knivesRemaining: 3,
          knifeState: KnifeState.idle,
          knifeReadyAtSpawn: false,
        ),
        false,
      );
    });

    test('blocked with no knives remaining', () {
      expect(
        KnifeThrowLogic.canThrowNow(
          isPlaying: true,
          knivesRemaining: 0,
          knifeState: KnifeState.idle,
          knifeReadyAtSpawn: true,
        ),
        false,
      );
    });
  });

  group('KnifeThrowLogic.shouldBufferTap', () {
    test('buffers while knife is flying', () {
      expect(
        KnifeThrowLogic.shouldBufferTap(
          isPlaying: true,
          knivesRemaining: 2,
          knifeState: KnifeState.flying,
        ),
        true,
      );
    });

    test('does not buffer when knife is ready', () {
      expect(
        KnifeThrowLogic.shouldBufferTap(
          isPlaying: true,
          knivesRemaining: 2,
          knifeState: KnifeState.idle,
        ),
        false,
      );
    });
  });

  group('KnifeThrowLogic.isAtSpawn', () {
    test('matches spawn within tolerance', () {
      expect(KnifeThrowLogic.isAtSpawn(spawn, spawn), true);
      expect(KnifeThrowLogic.isAtSpawn(spawn + Vector2(10, 0), spawn), true);
    });

    test('rejects off-screen park position', () {
      expect(KnifeThrowLogic.isAtSpawn(Vector2(-9999, -9999), spawn), false);
    });
  });
}
