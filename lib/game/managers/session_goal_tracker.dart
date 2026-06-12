import '../../data/mocks/session_goals.dart';

class GoalProgress {
  final SessionGoal goal;
  int current;
  bool completed;

  GoalProgress(this.goal) : current = 0, completed = false;

  int get target => goal.target;
  double get fraction => (current / target).clamp(0.0, 1.0);
}

class SessionGoalTracker {
  final List<GoalProgress> _goals;
  // Bonus points awarded so far this run
  int _bonusAwarded = 0;

  SessionGoalTracker()
      : _goals = kSessionGoals.map((g) => GoalProgress(g)).toList();

  List<GoalProgress> get goals => List.unmodifiable(_goals);
  int get bonusAwarded => _bonusAwarded;

  /// Records an apple collected. Returns bonus score if a goal just completed.
  int onAppleCollected() => _increment(GoalType.collectApples);

  /// Records a perfect throw. Returns bonus score if a goal just completed.
  int onPerfectThrow() => _increment(GoalType.perfectThrows);

  /// Records a clean stage clear (no spike hit). Returns bonus score if goal completed.
  int onCleanStageClear() => _increment(GoalType.clearStageClean);

  int _increment(GoalType type) {
    int earned = 0;
    for (final gp in _goals) {
      if (gp.goal.type == type && !gp.completed) {
        gp.current++;
        if (gp.current >= gp.target) {
          gp.completed = true;
          earned += gp.goal.bonusScore;
          _bonusAwarded += gp.goal.bonusScore;
        }
      }
    }
    return earned;
  }

  void reset() {
    for (final gp in _goals) {
      gp.current = 0;
      gp.completed = false;
    }
    _bonusAwarded = 0;
  }
}
