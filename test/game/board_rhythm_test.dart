import 'package:flutter_test/flutter_test.dart';
import 'package:knife_hit_game/game/components/board_rhythm.dart';

void main() {
  group('BoardRhythmController', () {
    test('sprint phase lasts about one second', () {
      final rhythm = BoardRhythmController();
      rhythm.phase = RhythmPhase.sprint;
      var elapsed = 0.0;
      while (elapsed < 0.95) {
        rhythm.tick(dt: 0.05, baseSpeed: 2.0, maxSpeed: 5.0);
        elapsed += 0.05;
        expect(rhythm.phase, RhythmPhase.sprint);
      }
      rhythm.tick(dt: 0.1, baseSpeed: 2.0, maxSpeed: 5.0);
      expect(rhythm.phase, RhythmPhase.cruising);
    });

    test('half-turn completes after pi radians', () {
      final rhythm = BoardRhythmController();
      rhythm.phase = RhythmPhase.halfTurn;
      var spins = 0;
      while (rhythm.phase == RhythmPhase.halfTurn && spins < 500) {
        rhythm.tick(dt: 0.016, baseSpeed: 2.0, maxSpeed: 5.0);
        spins++;
      }
      expect(rhythm.phase, RhythmPhase.cruising);
      expect(spins, lessThan(500));
    });
  });
}
