import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_buddy/features/saving_discipline_and_momo/models/deposit_record.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/member_streak.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_plan_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/providers/saving_streak_provider.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/saving_streak_calculator.dart';

void main() {
  group('SavingStreakCalculator Tests', () {
    test('returns 0 streaks for empty deposit dates', () {
      expect(SavingStreakCalculator.calculateCurrentStreak([]), 0);
      expect(SavingStreakCalculator.calculateLongestStreak([]), 0);
    });

    test('calculates active streak when latest check-in is today or yesterday', () {
      final today = DateTime(2026, 11, 26);
      final dates = ['2026-11-23', '2026-11-24', '2026-11-25'];

      expect(
        SavingStreakCalculator.calculateCurrentStreak(dates, referenceDate: today),
        3,
      );
      expect(SavingStreakCalculator.calculateLongestStreak(dates), 3);
    });

    test('resets active streak to 0 when gap exceeds 1 day while preserving longest', () {
      final today = DateTime(2026, 11, 28);
      final dates = ['2026-11-22', '2026-11-23', '2026-11-24', '2026-11-25'];

      expect(
        SavingStreakCalculator.calculateCurrentStreak(dates, referenceDate: today),
        0,
      );
      expect(SavingStreakCalculator.calculateLongestStreak(dates), 4);
    });

    test('recordCheckIn is idempotent for duplicate check-in on same day', () {
      final initial = MemberStreak(
        memberId: 'm1',
        tripId: 't1',
        currentStreak: 1,
        longestStreak: 1,
        lastDepositDate: DateTime(2026, 11, 25),
        depositDates: ['2026-11-25'],
        totalDisciplinedDays: 1,
      );

      final updated = SavingStreakCalculator.recordCheckIn(
        initial,
        DateTime(2026, 11, 25, 22, 30),
        referenceDate: DateTime(2026, 11, 25),
      );

      expect(updated.depositDates, ['2026-11-25']);
      expect(updated.currentStreak, 1);
      expect(updated.totalDisciplinedDays, 1);
    });

    test('recordCheckIn extends streak and updates longestStreak across consecutive days', () {
      final day1 = SavingStreakCalculator.recordCheckIn(
        const MemberStreak(memberId: 'm1', tripId: 't1'),
        DateTime(2026, 11, 24),
      );
      final day2 = SavingStreakCalculator.recordCheckIn(
        day1,
        DateTime(2026, 11, 25),
      );
      final day3 = SavingStreakCalculator.recordCheckIn(
        day2,
        DateTime(2026, 11, 26),
      );

      expect(day3.currentStreak, 3);
      expect(day3.longestStreak, 3);
      expect(day3.totalDisciplinedDays, 3);
      expect(day3.depositDates, ['2026-11-24', '2026-11-25', '2026-11-26']);
    });

    test('buildMonthCalendar marks checkedIn, pending, missed, and upcoming days', () {
      final streak = MemberStreak(
        memberId: 'm1',
        tripId: 't1',
        depositDates: ['2026-11-02', '2026-11-04'],
      );
      final deposits = [
        DepositRecord(
          id: 'd1',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          depositDate: DateTime(2026, 11, 5),
          status: DepositStatus.pending,
        ),
      ];

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: streak,
        deposits: deposits,
        journals: {
          '2026-11-02': (emoji: '🔥', note: 'Nhịn trà sữa'),
        },
        today: DateTime(2026, 11, 6),
      );

      expect(cells.length, 30);
      expect(cells[1].status, StreakDayStatus.checkedIn); // Nov 2
      expect(cells[1].emotionEmoji, '🔥');
      expect(cells[1].journalNote, 'Nhịn trà sữa');
      expect(cells[2].status, StreakDayStatus.missed); // Nov 3 (between Nov 2 and Nov 6)
      expect(cells[3].status, StreakDayStatus.checkedIn); // Nov 4
      expect(cells[4].status, StreakDayStatus.pending); // Nov 5
      expect(cells[6].status, StreakDayStatus.upcoming); // Nov 7
    });

    test('buildMonthCalendar marks approved deposit as checkedIn and uses planStartDate for missed', () {
      final deposits = [
        DepositRecord(
          id: 'd_app',
          tripId: 't1',
          memberId: 'm1',
          memberName: 'Bình',
          amount: 212000,
          depositDate: DateTime(2026, 11, 3),
          status: DepositStatus.approved,
        ),
      ];

      final cells = SavingStreakCalculator.buildMonthCalendar(
        month: DateTime(2026, 11),
        streak: const MemberStreak(memberId: 'm1', tripId: 't1'),
        deposits: deposits,
        planStartDate: DateTime(2026, 11, 2),
        today: DateTime(2026, 11, 5),
      );

      expect(cells[1].status, StreakDayStatus.missed); // Nov 2 (planStartDate, missed)
      expect(cells[2].status, StreakDayStatus.checkedIn); // Nov 3 (approved deposit)
      expect(cells[3].status, StreakDayStatus.missed); // Nov 4 (missed)
      expect(cells[4].status, StreakDayStatus.upcoming); // Nov 5 (today, not yet checked in)
    });

    test('backfilling an old date preserves currentStreak 0 relative to today', () {
      final updated = SavingStreakCalculator.recordCheckIn(
        const MemberStreak(memberId: 'm1', tripId: 't1'),
        DateTime(2026, 11, 10),
        referenceDate: DateTime(2026, 11, 26),
      );

      expect(updated.currentStreak, 0);
      expect(updated.longestStreak, 1);
      expect(updated.totalDisciplinedDays, 1);
    });
  });

  group('SavingStreakProvider Tests', () {
    test('checkIn updates repository streak and stores journal entry', () async {
      final repo = InMemorySavingRepository();
      final container = ProviderContainer(
        overrides: [savingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const params = SavingPlanParams(tripId: 't_streak', memberId: 'm_streak');
      final date = DateTime.now();
      final iso = SavingStreakCalculator.formatIsoDate(date);

      final updated = await container
          .read(savingStreakProvider(params).notifier)
          .checkIn(date: date, emoji: '💪', note: 'Bỏ bữa ăn vặt');

      expect(updated.currentStreak, 1);
      expect(updated.totalDisciplinedDays, 1);
      expect(updated.depositDates, [iso]);

      final journals = container.read(savingJournalProvider(params));
      expect(journals[iso]?.emoji, '💪');
      expect(journals[iso]?.note, 'Bỏ bữa ăn vặt');

      final persisted = await repo.getMemberStreak('t_streak', 'm_streak');
      expect(persisted.depositDates, [iso]);
    });
  });
}
