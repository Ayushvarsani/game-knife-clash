import '../../game/utils/stage_data.dart';

/// Generates a deterministic daily challenge from today's date.
/// The seed is derived from the date string (yyyyMMdd) so every player
/// on the same day gets identical stage layout.
class DailyChallengeGenerator {
  /// Returns the date key string for [date] in yyyyMMdd format.
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Returns stage data for today's daily challenge.
  /// Difficulty cycles through the week: Mon–Fri stages 2–6, Sat boss stage 5,
  /// Sun hard boss stage 10. Each day still gets a unique random layout.
  static StageData todaysChallenge(DateTime date) {
    final key = dateKey(date);
    final seed = key.codeUnits.fold(0, (acc, c) => acc * 31 + c);
    // weekday: 1=Mon … 7=Sun
    final stage = switch (date.weekday) {
      1 => 2,  // Monday: easy
      2 => 3,  // Tuesday
      3 => 4,  // Wednesday
      4 => 5,  // Thursday: boss
      5 => 6,  // Friday
      6 => 10, // Saturday: hard boss
      _ => 8,  // Sunday: hard normal
    };
    return getStageData(stage, seed: seed);
  }

  /// Today's date key, always in UTC so players in all timezones share the same challenge.
  static String todaysKey() => dateKey(DateTime.now().toUtc());
}
