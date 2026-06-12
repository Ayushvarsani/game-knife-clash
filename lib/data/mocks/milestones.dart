enum MilestoneTrigger {
  firstBoss,
  apples10,
  perfectRun5,   // 5 perfect throws in one run
  stage10,
  combo9,
}

class Milestone {
  final String id;
  final String title;
  final String description;
  final MilestoneTrigger trigger;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.trigger,
  });
}

const List<Milestone> kMilestones = [
  Milestone(
    id: 'first_boss',
    title: 'Boss Encounter',
    description: 'Reach your first boss stage.',
    trigger: MilestoneTrigger.firstBoss,
  ),
  Milestone(
    id: 'apples_10',
    title: 'Apple Collector',
    description: 'Collect 10 lifetime apples.',
    trigger: MilestoneTrigger.apples10,
  ),
  Milestone(
    id: 'perfect_5_run',
    title: 'Sharpshooter',
    description: 'Land 5 perfect throws in a single run.',
    trigger: MilestoneTrigger.perfectRun5,
  ),
  Milestone(
    id: 'stage_10',
    title: 'Veteran',
    description: 'Reach stage 10.',
    trigger: MilestoneTrigger.stage10,
  ),
  Milestone(
    id: 'combo_9',
    title: 'On Fire',
    description: 'Build a combo streak of 9.',
    trigger: MilestoneTrigger.combo9,
  ),
];
