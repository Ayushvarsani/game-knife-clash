import 'progress_manager.dart';
import 'high_score_manager.dart';

/// Batches score, fruit, stage, and high-score persistence into one disk write.
///
/// Never called mid-throw — only at stage complete, game over, pause, and exit.
class GameCheckpoint {
  GameCheckpoint._();

  /// Marks all runtime values in memory, then writes once to disk.
  static Future<void> persist({
    required ProgressManager progress,
    required HighScoreManager highScore,
    required int score,
    required int stage,
  }) async {
    progress.saveLastStage(stage);
    highScore.markIfBetter(score);
    await progress.flush(highScore: highScore);
  }
}
