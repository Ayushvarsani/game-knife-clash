import 'dart:math';
import 'angle_utils.dart';
import 'board_theme.dart';

class StageData {
  final int knivesCount;
  final double rotationSpeed;
  final bool reverseDirection;
  final bool directionChanges;
  final bool isBoss;
  final int applesCount;
  /// Precomputed rim angles for bonus stages (placed in gaps between pre-stuck knives).
  final List<double> appleAngles;
  final BoardTheme theme;
  /// Bonus stages: angles for pre-stuck knives around the rim (replaces spikes).
  final List<double> bossSpikeAngles;
  // How many knives are pre-stuck on the board at stage start (increases difficulty)
  final int preStuckKnivesCount;
  // Whether the board has speed-burst intervals (brief fast spins)
  final bool hasSpeedBursts;
  // Periodic 180° spin at boosted speed, then back to normal — aids timing.
  final bool hasHalfSpinRhythm;
  final double halfSpinInterval;
  final double halfSpinSpeedMultiplier;
  /// Stage 10+: cycles cruise / half-turn / 1s sprint / gentle speed lift.
  final bool advancedRhythm;
  // Boss only: after this many knives are stuck, the board escalates speed by 40%
  // and direction changes activate. 0 means no phase escalation.
  final int bossPhaseThreshold;
  // How long (seconds) before the board flips direction. Shrinks with stage.
  final double dirChangeInterval;

  const StageData({
    required this.knivesCount,
    required this.rotationSpeed,
    required this.theme,
    this.reverseDirection = false,
    this.directionChanges = false,
    this.isBoss = false,
    this.applesCount = 1,
    this.appleAngles = const [],
    this.bossSpikeAngles = const [],
    this.preStuckKnivesCount = 0,
    this.hasSpeedBursts = false,
    this.hasHalfSpinRhythm = false,
    this.halfSpinInterval = 4.5,
    this.halfSpinSpeedMultiplier = 1.5,
    this.advancedRhythm = false,
    this.bossPhaseThreshold = 0,
    this.dirChangeInterval = 2.0,
  });
}

/// Bonus stage modes — each gives the bonus round a distinct feel.
enum BonusMode { appleFrenzy, spikeGauntlet, speedRush }

/// Returns deterministic stage data for [stage].
/// Pass an explicit [seed] to override (e.g. for daily challenge mode).
/// Pass [recentThemes] so the generator avoids repeating them.
/// Default seed: stage * 7919 — same stage always produces the same layout.
StageData getStageData(int stage, {int? seed, List<BoardThemeId> recentThemes = const []}) {
  final random = Random(seed ?? stage * 7919);
  final isBoss = stage % 5 == 0;
  final difficulty = stage - 1;

  // --- Normal stage parameters (wider variation so each run feels different) ---

  // Casual-friendly: few knives early, slow ramp.
  final baseKnives = 3 + (difficulty / 4).floor();
  final knifeVariation = random.nextInt(2); // 0 to +1

  final speedVariation = random.nextDouble() * 0.1 - 0.05;
  final double baseRotationSpeed;
  if (stage <= 10) {
    final speedCurve = 1.15 + 0.95 * (1 - exp(-difficulty / 5.0));
    baseRotationSpeed = (speedCurve + speedVariation).clamp(1.1, 2.1);
  } else {
    // Post-10: keep base spin tame — pacing comes from rhythm patterns.
    final capped = 1.95 + 0.035 * (stage - 10);
    baseRotationSpeed = (capped + speedVariation).clamp(1.85, 2.2);
  }

  // Bonus stages: almost always relaxed apple-frenzy.
  final BonusMode bonusMode = isBoss
      ? (random.nextInt(20) < 18
          ? BonusMode.appleFrenzy
          : BonusMode.values[random.nextInt(BonusMode.values.length)])
      : BonusMode.appleFrenzy;

  // Boss mode parameters
  int bossTargetApples;
  int bossSpikeCount;
  double bossRotationSpeedMultiplier;
  bool bossDirChanges;
  double bossDirChangeInterval;
  bool bossHasBursts;

  if (isBoss) {
    switch (bonusMode) {
      case BonusMode.appleFrenzy:
        bossTargetApples = (10 + random.nextInt(3)).clamp(10, 12);
        bossSpikeCount = 0;
        bossRotationSpeedMultiplier = 0.48 + random.nextDouble() * 0.06;
        bossDirChanges = false;
        bossDirChangeInterval = 4.0;
        bossHasBursts = false;
      case BonusMode.spikeGauntlet:
        bossTargetApples = (8 + random.nextInt(2)).clamp(8, 9);
        bossSpikeCount = 1 + random.nextInt(2); // 1–2 spikes
        bossRotationSpeedMultiplier = 0.55 + random.nextDouble() * 0.08;
        bossDirChanges = false;
        bossDirChangeInterval = 3.5;
        bossHasBursts = false;
      case BonusMode.speedRush:
        bossTargetApples = (7 + random.nextInt(2)).clamp(7, 8);
        bossSpikeCount = random.nextInt(2); // 0–1 spikes
        bossRotationSpeedMultiplier = 0.62 + random.nextDouble() * 0.08;
        bossDirChanges = false;
        bossDirChangeInterval = 3.8;
        bossHasBursts = false;
    }
  } else {
    bossTargetApples = 0;
    bossSpikeCount = 0;
    bossRotationSpeedMultiplier = 1.0;
    bossDirChanges = false;
    bossDirChangeInterval = 2.5;
    bossHasBursts = false;
  }

  // Rotation speed: boss uses mode multiplier, normal uses wider variation
  final rotationSpeed = isBoss
      ? (baseRotationSpeed * bossRotationSpeedMultiplier).clamp(0.85, 1.35)
      : baseRotationSpeed;

  final targetBonusApples = isBoss
      ? bossTargetApples
      : (stage <= 5 ? 1 : (1 + (difficulty / 6).floor())).clamp(1, 2);

  final normalKnivesCount = (baseKnives + knifeVariation).clamp(3, 8);

  // Casual curve: predictable spin for the first many stages.
  //   Stage 1–8  : always clockwise
  //   Stage 9–15 : 25% chance reverse
  //   Stage 16+  : gentle mix; direction flips only after stage 20
  bool reverseDirection = false;
  bool directionChanges = false;
  if (!isBoss) {
    if (stage >= 9 && stage <= 15) {
      reverseDirection = random.nextDouble() < 0.25;
    } else if (stage >= 16) {
      reverseDirection = random.nextDouble() < 0.35;
      if (stage >= 20) {
        directionChanges = random.nextDouble() < 0.20;
      }
    }
  }
  if (isBoss) {
    directionChanges = bossDirChanges;
    reverseDirection = bonusMode != BonusMode.appleFrenzy && random.nextDouble() < 0.3;
  }

  // Theme: bonus always gold, normal avoids recent repeats
  final BoardTheme theme;
  if (isBoss) {
    theme = BoardTheme.bonus;
  } else {
    final pool = BoardTheme.allNormal
        .where((t) => !recentThemes.contains(t.id))
        .toList();
    final source = pool.isNotEmpty ? pool : BoardTheme.allNormal;
    theme = source[random.nextInt(source.length)];
  }

  // Bonus stage: pre-stuck knives (spikes) — count driven by mode
  List<double> bossSpikeAngles = [];
  if (isBoss) {
    final minSpacing = bonusMode == BonusMode.spikeGauntlet ? 0.9 : 1.4;
    final angles = <double>[];
    int attempts = 0;
    while (angles.length < bossSpikeCount && attempts < 400) {
      final a = random.nextDouble() * 2 * pi;
      bool tooClose = false;
      for (final existing in angles) {
        double diff = (a - existing).abs() % (2 * pi);
        if (diff > pi) diff = 2 * pi - diff;
        if (diff < minSpacing) { tooClose = true; break; }
      }
      if (!tooClose) angles.add(a);
      attempts++;
    }
    bossSpikeAngles = angles;
  }

  // Apple placement for bonus stages
  List<double> appleAngles;
  if (isBoss) {
    if (bossSpikeAngles.length >= 2) {
      final minAppleSpacing = bonusMode == BonusMode.spikeGauntlet ? 0.28 : 0.32;
      appleAngles = computeAppleAnglesInSpikeGaps(
        bossSpikeAngles, targetBonusApples,
        minAppleSpacing: minAppleSpacing,
      );
    } else {
      appleAngles = List.generate(
        targetBonusApples,
        (i) => (2 * pi / targetBonusApples) * i,
      );
    }
  } else {
    appleAngles = const [];
  }
  // Boss knivesCount = actual apples placed (not the target, which may exceed
  // what fits in the spike gaps). Normal knivesCount was computed above.
  final knivesCount = isBoss ? appleAngles.length.clamp(1, 99) : normalKnivesCount;
  final applesCount = isBoss ? appleAngles.length : targetBonusApples;

  // Pre-stuck knives — very rare; most stages start with a clean board.
  const minAngle = 0.26;
  final rawPreStuck = isBoss ? 0 : (stage >= 12 ? ((difficulty - 10) ~/ 6) : 0);
  final softCap = (knivesCount * 0.20).floor();
  int preStuckKnivesCount = rawPreStuck.clamp(0, softCap);
  while (preStuckKnivesCount > 0 &&
      (preStuckKnivesCount + knivesCount) * minAngle > 2 * pi) {
    preStuckKnivesCount--;
  }

  // Direction-change interval: mode-driven for boss, wider variation for normal
  final dirChangeInterval = isBoss
      ? bossDirChangeInterval
      : (3.0 - difficulty * 0.04 + (random.nextDouble() * 0.2 - 0.1)).clamp(1.8, 3.0);

  final advancedRhythm = !isBoss && stage >= 10;
  final hasHalfSpinRhythm = !isBoss && stage >= 2 && stage < 10;
  final halfSpinInterval =
      (5.5 - difficulty * 0.06 + (random.nextDouble() * 0.4 - 0.2)).clamp(3.0, 5.5);
  final halfSpinSpeedMultiplier =
      (1.35 + difficulty * 0.02 + random.nextDouble() * 0.08).clamp(1.35, 1.75);

  // Light bursts on late normal stages — never on bonus (kept easy).
  final burstChance = !isBoss && stage >= 15
      ? 0.08 + 0.14 * (1 - exp(-(stage - 15) / 12.0))
      : 0.0;
  final hasBursts =
      !advancedRhythm && (isBoss ? bossHasBursts : random.nextDouble() < burstChance);

  // No mid-boss speed escalation — keeps bonus rounds relaxed.
  const bossPhaseThreshold = 0;

  return StageData(
    knivesCount: knivesCount,
    rotationSpeed: rotationSpeed,
    reverseDirection: reverseDirection,
    directionChanges: directionChanges,
    isBoss: isBoss,
    applesCount: applesCount,
    appleAngles: appleAngles,
    theme: theme,
    bossSpikeAngles: bossSpikeAngles,
    preStuckKnivesCount: preStuckKnivesCount,
    hasSpeedBursts: hasBursts,
    hasHalfSpinRhythm: hasHalfSpinRhythm,
    halfSpinInterval: halfSpinInterval,
    halfSpinSpeedMultiplier: halfSpinSpeedMultiplier,
    advancedRhythm: advancedRhythm,
    bossPhaseThreshold: bossPhaseThreshold,
    dirChangeInterval: dirChangeInterval,
  );
}

/// Places apples in the largest angular gaps between bonus-stage spikes.
/// Places up to [maxApples] evenly across all angular gaps between [spikeAngles].
/// Multiple apples per gap — distributes by gap width so larger gaps get more.
List<double> computeAppleAnglesInSpikeGaps(
  List<double> spikeAngles,
  int maxApples, {
  double minGapWidth = 0.45,
  double minAppleSpacing = 0.38,
}) {
  if (spikeAngles.isEmpty || maxApples <= 0) return const [];

  final spikes = spikeAngles.map(normalizeAngle).toList()..sort();

  // Build gaps: (start, end, width)
  final gaps = <({double start, double end, double width})>[];
  for (int i = 0; i < spikes.length; i++) {
    final a = spikes[i];
    final b = spikes[(i + 1) % spikes.length];
    final width = i < spikes.length - 1 ? b - a : (2 * pi - a) + b;
    if (width >= minGapWidth) gaps.add((start: a, end: b, width: width));
  }
  if (gaps.isEmpty) {
    return List.generate(maxApples, (i) => (2 * pi / maxApples) * i);
  }

  final totalWidth = gaps.fold(0.0, (s, g) => s + g.width);
  final result = <double>[];

  for (final gap in gaps) {
    if (result.length >= maxApples) break;
    // How many apples fit in this gap proportionally
    final share = (gap.width / totalWidth * maxApples).round().clamp(1, maxApples);
    final count = share.clamp(1, (gap.width / minAppleSpacing).floor().clamp(1, share));
    final step = gap.width / (count + 1);
    for (int j = 1; j <= count; j++) {
      if (result.length >= maxApples) break;
      final angle = normalizeAngle(gap.start + step * j);
      result.add(angle);
    }
  }

  // If still short, fill remaining slots evenly from leftover gap space
  if (result.length < maxApples) {
    for (final gap in gaps) {
      if (result.length >= maxApples) break;
      final mid = normalizeAngle(gap.start + gap.width / 2);
      if (!result.any((a) => (a - mid).abs() < minAppleSpacing)) {
        result.add(mid);
      }
    }
  }

  return result;
}
