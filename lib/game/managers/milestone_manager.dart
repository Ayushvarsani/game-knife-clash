import 'package:shared_preferences/shared_preferences.dart';
import '../../data/mocks/milestones.dart';

class MilestoneManager {
  static const _keyPrefix = 'milestone_unlocked_';

  final Set<String> _unlocked = {};
  // Newly unlocked this session — consumed by UI toast
  final List<Milestone> _pendingToasts = [];

  List<Milestone> get pendingToasts => List.unmodifiable(_pendingToasts);
  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final m in kMilestones) {
      if (prefs.getBool('$_keyPrefix${m.id}') == true) {
        _unlocked.add(m.id);
      }
    }
  }

  /// Check session stats and unlock any newly-earned milestones.
  /// Returns list of newly unlocked milestones (empty if none).
  Future<List<Milestone>> evaluate({
    required int lifetimeApples,
    required int perfectThrowsThisRun,
    required int currentStage,
    required int comboStreak,
    required bool reachedBoss,
  }) async {
    final newly = <Milestone>[];
    for (final m in kMilestones) {
      if (_unlocked.contains(m.id)) continue;
      bool earned = false;
      switch (m.trigger) {
        case MilestoneTrigger.firstBoss:
          earned = reachedBoss;
        case MilestoneTrigger.apples10:
          earned = lifetimeApples >= 10;
        case MilestoneTrigger.perfectRun5:
          earned = perfectThrowsThisRun >= 5;
        case MilestoneTrigger.stage10:
          earned = currentStage >= 10;
        case MilestoneTrigger.combo9:
          earned = comboStreak >= 9;
      }
      if (earned) {
        _unlocked.add(m.id);
        _pendingToasts.add(m);
        newly.add(m);
      }
    }
    if (newly.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      for (final m in newly) {
        await prefs.setBool('$_keyPrefix${m.id}', true);
      }
    }
    return newly;
  }

  /// Call after the UI has consumed and displayed all pending toasts.
  void clearToasts() => _pendingToasts.clear();
}
