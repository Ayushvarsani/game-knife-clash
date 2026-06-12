import 'dart:math';
import '../utils/board_theme.dart';
import '../utils/stage_data.dart';

class StageManager {
  int _currentStage = 1;
  int _knivesThrown = 0;
  int _knivesStuck = 0;
  final Random _runSeedRandom;
  final int? _fixedRunSeed;
  late int _runSeed;
  late StageData _cachedStageData;
  // Last 3 theme IDs used — passed to getStageData to avoid visual repeats.
  final List<BoardThemeId> _recentThemes = [];

  StageManager({int? fixedRunSeed, Random? runSeedRandom})
      : _fixedRunSeed = fixedRunSeed,
        _runSeedRandom = runSeedRandom ?? Random() {
    _runSeed = _nextRunSeed();
    _cachedStageData = _buildStageData(_currentStage);
  }

  int get currentStage => _currentStage;
  int get knivesThrown => _knivesThrown;
  int get knivesStuck => _knivesStuck;
  int get runSeed => _runSeed;

  StageData get currentStageData => _cachedStageData;
  int get knivesRemaining => (_cachedStageData.knivesCount - _knivesThrown).clamp(0, _cachedStageData.knivesCount);
  bool get isStageComplete => _knivesStuck >= _cachedStageData.knivesCount;
  // True when exactly 1 knife remains — used to trigger last-knife warning
  bool get isLastKnife => knivesRemaining == 1;

  void knifeThrown() {
    if (_knivesThrown < _cachedStageData.knivesCount) _knivesThrown++;
  }

  void knifeStuck() {
    if (_knivesStuck < _cachedStageData.knivesCount) _knivesStuck++;
  }

  /// Rolls back a thrown knife that missed the board (overshoot/off-screen).
  /// Keeps knivesThrown and knivesStuck aligned.
  void rollbackThrow() {
    if (_knivesThrown > 0) _knivesThrown--;
  }

  void nextStage() {
    final previous = _cachedStageData;
    _trackTheme(previous.theme.id);
    _currentStage++;
    _knivesThrown = 0;
    _knivesStuck = 0;
    _cachedStageData = _buildStageData(_currentStage, previous: previous);
  }

  void reset() {
    _currentStage = 1;
    _knivesThrown = 0;
    _knivesStuck = 0;
    _recentThemes.clear();
    _runSeed = _nextRunSeed();
    _cachedStageData = _buildStageData(_currentStage);
  }

  void _trackTheme(BoardThemeId id) {
    _recentThemes.add(id);
    if (_recentThemes.length > 3) _recentThemes.removeAt(0);
  }

  int _nextRunSeed() {
    if (_fixedRunSeed != null) return _fixedRunSeed;
    return _runSeedRandom.nextInt(0x7fffffff);
  }

  StageData _buildStageData(int stage, {StageData? previous}) {
    StageData candidate = getStageData(stage,
        seed: _seedForStage(stage), recentThemes: List.of(_recentThemes));
    if (stage <= 1 || previous == null) return candidate;

    for (int attempt = 1; attempt <= 5; attempt++) {
      if (!_isTooSimilarToPrevious(candidate, previous)) break;
      candidate = getStageData(stage,
          seed: _seedForStage(stage, salt: attempt),
          recentThemes: List.of(_recentThemes));
    }
    return candidate;
  }

  int _seedForStage(int stage, {int salt = 0}) {
    // Mix run seed and stage number to keep stages stable inside a run
    // while making new runs produce different layouts.
    final mix = _runSeed ^
        (stage * 0x9E3779B9) ^
        (salt * 0x85EBCA6B);
    return mix & 0x7fffffff;
  }

  bool _isTooSimilarToPrevious(StageData current, StageData previous) {
    // Block on any single visible-to-player attribute matching, not just all at once.
    final sameTheme = current.theme.id == previous.theme.id;
    final sameKnifeCount = current.knivesCount == previous.knivesCount;
    final sameDirectionMode = current.reverseDirection == previous.reverseDirection &&
        current.directionChanges == previous.directionChanges;
    final closeSpeed =
        (current.rotationSpeed - previous.rotationSpeed).abs() < 0.25;

    // Two attributes matching is enough to trigger a re-roll.
    int matchScore = 0;
    if (sameTheme) matchScore++;
    if (sameKnifeCount) matchScore++;
    if (sameDirectionMode) matchScore++;
    if (closeSpeed) matchScore++;
    if (current.applesCount == previous.applesCount) matchScore++;
    if (current.preStuckKnivesCount == previous.preStuckKnivesCount) matchScore++;

    if (matchScore >= 4) return true;

    // Bonus stages should differ in visual hazard profile too.
    if (current.isBoss && previous.isBoss) {
      final closeSpikeCount =
          (current.bossSpikeAngles.length - previous.bossSpikeAngles.length).abs() <= 1;
      final closeAppleCount =
          (current.appleAngles.length - previous.appleAngles.length).abs() <= 1;
      if (closeSpikeCount && closeAppleCount && closeSpeed) return true;
    }
    return false;
  }
}
