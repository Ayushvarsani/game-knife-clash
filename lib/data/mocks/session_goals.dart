enum GoalType {
  collectApples,
  perfectThrows,
  clearStageClean, // clear a stage without hitting a spike
}

class SessionGoal {
  final String id;
  final String description;
  final GoalType type;
  final int target;
  final int bonusScore;

  const SessionGoal({
    required this.id,
    required this.description,
    required this.type,
    required this.target,
    required this.bonusScore,
  });
}

const List<SessionGoal> kSessionGoals = [
  SessionGoal(
    id: 'collect_3_apples',
    description: 'Collect 3 apples',
    type: GoalType.collectApples,
    target: 3,
    bonusScore: 15,
  ),
  SessionGoal(
    id: 'perfect_2_throws',
    description: 'Land 2 perfect throws',
    type: GoalType.perfectThrows,
    target: 2,
    bonusScore: 20,
  ),
  SessionGoal(
    id: 'clear_stage_clean',
    description: 'Clear a stage without hitting a spike',
    type: GoalType.clearStageClean,
    target: 1,
    bonusScore: 25,
  ),
];
