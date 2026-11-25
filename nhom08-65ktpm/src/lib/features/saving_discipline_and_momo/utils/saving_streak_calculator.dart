import '../models/deposit_record.dart';
import '../models/member_streak.dart';

/// Status of a single day cell in the DailyYou Saving Streak Calendar.
enum StreakDayStatus { checkedIn, pending, missed, upcoming }

/// Presentation-ready data for one day in the DailyYou Streak Calendar.
class StreakCalendarDay {
  final DateTime date;
  final String isoDate;
  final StreakDayStatus status;
  final String? emotionEmoji;
  final String? journalNote;

  const StreakCalendarDay({
    required this.date,
    required this.isoDate,
    required this.status,
    this.emotionEmoji,
    this.journalNote,
  });
}

/// Pure domain helper for DailyYou-style saving streak calculations.
class SavingStreakCalculator {
  const SavingStreakCalculator._();

  /// Formats a [DateTime] as local `YYYY-MM-DD`.
  static String formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses a `YYYY-MM-DD` string into a local midnight [DateTime].
  static DateTime? parseIsoDate(String isoDate) {
    final parts = isoDate.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Normalizes a list of ISO date strings into sorted, unique local dates.
  static List<DateTime> normalizeDates(Iterable<String> isoDates) {
    final unique = <String, DateTime>{};
    for (final raw in isoDates) {
      final parsed = parseIsoDate(raw);
      if (parsed != null) {
        unique[formatIsoDate(parsed)] = parsed;
      }
    }
    final list = unique.values.toList()..sort();
    return list;
  }

  /// Computes the longest consecutive-day streak in [isoDates].
  static int calculateLongestStreak(Iterable<String> isoDates) {
    final dates = normalizeDates(isoDates);
    if (dates.isEmpty) return 0;

    var longest = 1;
    var run = 1;
    for (var i = 1; i < dates.length; i++) {
      final diffDays = _calendarDayDiff(dates[i - 1], dates[i]);
      if (diffDays == 1) {
        run += 1;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }

  /// Computes the active consecutive-day streak relative to [referenceDate].
  ///
  /// A streak remains active if the most recent check-in is on [referenceDate]
  /// or 1 day prior (yesterday). If older than 1 day, the active streak is `0`.
  static int calculateCurrentStreak(
    Iterable<String> isoDates, {
    DateTime? referenceDate,
  }) {
    final dates = normalizeDates(isoDates);
    if (dates.isEmpty) return 0;

    final ref = _toLocalDay(referenceDate ?? DateTime.now());
    final latest = dates.last;
    final daysSinceLatest = _calendarDayDiff(latest, ref);
    if (daysSinceLatest > 1 || daysSinceLatest < 0) {
      // If latest is in the future, anchor from latest; if gap > 1 day, streak broke.
      if (daysSinceLatest > 1) return 0;
    }

    var streak = 1;
    for (var i = dates.length - 2; i >= 0; i--) {
      if (_calendarDayDiff(dates[i], dates[i + 1]) == 1) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Records a disciplined saving check-in on [checkInDate] and returns an updated [MemberStreak].
  static MemberStreak recordCheckIn(
    MemberStreak current,
    DateTime checkInDate, {
    DateTime? referenceDate,
  }) {
    final normalizedDay = _toLocalDay(checkInDate);
    final iso = formatIsoDate(normalizedDay);
    final updatedIsoSet = {...current.depositDates, iso};
    final sortedDates = normalizeDates(updatedIsoSet).map(formatIsoDate).toList();

    final ref = _toLocalDay(referenceDate ?? normalizedDay);
    final currentStreak = calculateCurrentStreak(sortedDates, referenceDate: ref);
    final longestCandidate = calculateLongestStreak(sortedDates);
    final longestStreak =
        longestCandidate > current.longestStreak ? longestCandidate : current.longestStreak;

    final latestDate = parseIsoDate(sortedDates.last);
    return current.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastDepositDate: latestDate,
      depositDates: sortedDates,
      totalDisciplinedDays: sortedDates.length,
    );
  }

  /// Builds calendar cells for [month] combining [streak], [deposits], and [journals].
  static List<StreakCalendarDay> buildMonthCalendar({
    required DateTime month,
    required MemberStreak streak,
    List<DepositRecord> deposits = const [],
    Map<String, ({String emoji, String note})> journals = const {},
    DateTime? planStartDate,
    DateTime? today,
  }) {
    final todayDay = _toLocalDay(today ?? DateTime.now());
    final approvedDepositDates = deposits
        .where((d) => d.status == DepositStatus.approved)
        .map((d) => formatIsoDate(_toLocalDay(d.depositDate)));
    final checkedSet = {...streak.depositDates, ...approvedDepositDates};
    final pendingSet = deposits
        .where((d) => d.status == DepositStatus.pending)
        .map((d) => formatIsoDate(_toLocalDay(d.depositDate)))
        .toSet();

    final firstActivityDay = _resolveFirstActivityDay(
      streak: streak,
      deposits: deposits,
      planStartDate: planStartDate,
    );

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = <StreakCalendarDay>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final iso = formatIsoDate(date);
      final journal = journals[iso];

      final StreakDayStatus status;
      if (checkedSet.contains(iso)) {
        status = StreakDayStatus.checkedIn;
      } else if (pendingSet.contains(iso)) {
        status = StreakDayStatus.pending;
      } else if (date.isAfter(todayDay)) {
        status = StreakDayStatus.upcoming;
      } else if (firstActivityDay != null &&
          !date.isBefore(firstActivityDay) &&
          date.isBefore(todayDay)) {
        status = StreakDayStatus.missed;
      } else {
        status = StreakDayStatus.upcoming;
      }

      cells.add(
        StreakCalendarDay(
          date: date,
          isoDate: iso,
          status: status,
          emotionEmoji: journal?.emoji,
          journalNote: journal?.note,
        ),
      );
    }

    return cells;
  }

  static DateTime? _resolveFirstActivityDay({
    required MemberStreak streak,
    required List<DepositRecord> deposits,
    DateTime? planStartDate,
  }) {
    final candidates = <DateTime>[
      ...normalizeDates(streak.depositDates),
      ...deposits.map((d) => _toLocalDay(d.depositDate)),
      if (planStartDate != null) _toLocalDay(planStartDate),
    ];
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  static DateTime _toLocalDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static int _calendarDayDiff(DateTime a, DateTime b) {
    final utcA = DateTime.utc(a.year, a.month, a.day);
    final utcB = DateTime.utc(b.year, b.month, b.day);
    return utcB.difference(utcA).inDays;
  }
}
