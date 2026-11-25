import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_inset_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../models/deposit_record.dart';
import '../../models/member_streak.dart';
import '../../providers/saving_plan_provider.dart';
import '../../providers/saving_streak_provider.dart';
import '../../utils/saving_streak_calculator.dart';
import 'saving_journal_dialog.dart';

/// DailyYou-style interactive Saving Streak Calendar widget.
class DailyYouStreakCalendar extends ConsumerStatefulWidget {
  const DailyYouStreakCalendar({
    super.key,
    required this.tripId,
    required this.memberId,
  });

  final String tripId;
  final String memberId;

  @override
  ConsumerState<DailyYouStreakCalendar> createState() =>
      _DailyYouStreakCalendarState();
}

class _DailyYouStreakCalendarState
    extends ConsumerState<DailyYouStreakCalendar> {
  late DateTime _visibleMonth;
  bool _isCheckingIn = false;

  SavingPlanParams get _params => SavingPlanParams(
        tripId: widget.tripId,
        memberId: widget.memberId,
      );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _returnToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
    });
  }

  Widget _buildTodayPill() {
    return TextButton(
      onPressed: _returnToToday,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: const Text(
        'Hôm nay',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _openJournalForDay(
    DateTime date, {
    String? existingEmoji,
    String? existingNote,
    bool alreadyCheckedIn = false,
  }) async {
    if (_isCheckingIn) return;
    final result = await showDialog<SavingJournalDialogResult>(
      context: context,
      builder: (_) => SavingJournalDialog(
        date: date,
        initialEmoji: existingEmoji,
        initialNote: existingNote,
        alreadyCheckedIn: alreadyCheckedIn,
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _isCheckingIn = true);
    try {
      await ref.read(savingStreakProvider(_params).notifier).checkIn(
            date: date,
            emoji: result.emoji,
            note: result.note,
          );
      if (mounted) {
        final now = DateTime.now();
        final isTodayDate =
            SavingStreakCalculator.formatIsoDate(date) ==
            SavingStreakCalculator.formatIsoDate(now);
        if (isTodayDate) {
          _returnToToday();
        }
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.mintContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.mint),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.onMintContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alreadyCheckedIn
                        ? 'Đã cập nhật nhật ký tích góp ${result.emoji}!'
                        : 'Điểm danh thành công ${result.emoji}!',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onMintContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu điểm danh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(savingStreakStreamProvider(_params));
    final depositsAsync = ref.watch(memberDepositsStreamProvider(_params));
    final journals = ref.watch(savingJournalProvider(_params));

    final streak = streakAsync.value ??
        MemberStreak(memberId: widget.memberId, tripId: widget.tripId);
    final deposits = depositsAsync.value ?? const <DepositRecord>[];

    final today = DateTime.now();
    final todayIso = SavingStreakCalculator.formatIsoDate(today);
    final checkedInToday = streak.depositDates.contains(todayIso);
    final days = SavingStreakCalculator.buildMonthCalendar(
      month: _visibleMonth,
      streak: streak,
      deposits: deposits,
      journals: journals,
      today: today,
    );

    final firstWeekdayOffset =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday - 1;
    final totalCells = firstWeekdayOffset + days.length;
    final currentMonth = DateTime(today.year, today.month);
    final isPastMonth = _visibleMonth.isBefore(currentMonth);
    final isFutureMonth = _visibleMonth.isAfter(currentMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'LỊCH CHUỖI KỶ LUẬT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: 'Chuỗi ${streak.currentStreak} ngày 🔥',
                tone: streak.currentStreak > 0
                    ? AppBadgeTone.mint
                    : AppBadgeTone.amber,
              ),
            ],
          ),
        ),
        AppInsetCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _changeMonth(-1),
                          ),
                          if (isFutureMonth) _buildTodayPill(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 96),
                      child: Text(
                        'Tháng ${_visibleMonth.month.toString().padLeft(2, '0')}/${_visibleMonth.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPastMonth) _buildTodayPill(),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Text(
                  'Kỷ lục: ${streak.longestStreak} ngày • Tổng: ${streak.totalDisciplinedDays} ngày',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  _WeekdayHeader('T2'),
                  _WeekdayHeader('T3'),
                  _WeekdayHeader('T4'),
                  _WeekdayHeader('T5'),
                  _WeekdayHeader('T6'),
                  _WeekdayHeader('T7'),
                  _WeekdayHeader('CN'),
                ],
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekdayOffset) {
                    return const SizedBox.shrink();
                  }
                  final cell = days[index - firstWeekdayOffset];
                  final isToday = cell.isoDate == todayIso;

                  final (bg, fg, badge) = switch (cell.status) {
                    StreakDayStatus.checkedIn => (
                        AppColors.mintContainer,
                        AppColors.onMintContainer,
                        cell.emotionEmoji ?? '✓',
                      ),
                    StreakDayStatus.pending => (
                        AppColors.amberContainer,
                        AppColors.onAmberContainer,
                        '⏳',
                      ),
                    StreakDayStatus.missed => (
                        AppColors.error.withValues(alpha: 0.12),
                        AppColors.error,
                        '•',
                      ),
                    StreakDayStatus.upcoming => (
                        AppColors.surfaceContainerLow,
                        AppColors.onSurfaceVariant,
                        '',
                      ),
                  };

                  final canTap = !cell.date.isAfter(
                    DateTime(today.year, today.month, today.day),
                  );
                  final hasNote =
                      cell.journalNote != null && cell.journalNote!.trim().isNotEmpty;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: canTap
                        ? () => _openJournalForDay(
                              cell.date,
                              existingEmoji: cell.emotionEmoji,
                              existingNote: cell.journalNote,
                              alreadyCheckedIn:
                                  cell.status == StreakDayStatus.checkedIn,
                            )
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday
                              ? AppColors.primary
                              : AppColors.outlineVariantSoft,
                          width: isToday ? 1.5 : 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${cell.date.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      isToday ? FontWeight.w800 : FontWeight.w600,
                                  color: fg,
                                ),
                              ),
                              if (badge.isNotEmpty)
                                Text(
                                  badge,
                                  style: TextStyle(fontSize: 11, color: fg),
                                ),
                            ],
                          ),
                          if (hasNote)
                            Positioned(
                              top: 3,
                              right: 3,
                              child: Icon(
                                Icons.sticky_note_2_rounded,
                                size: 9,
                                color: fg,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _CalendarLegendDot(color: AppColors.mint, label: 'Đúng hạn'),
                    _CalendarLegendDot(color: AppColors.amber, label: 'Chờ duyệt'),
                    _CalendarLegendDot(color: AppColors.error, label: 'Trễ hạn'),
                    _CalendarLegendDot(
                      color: AppColors.outlineVariant,
                      label: 'Sắp tới',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sticky_note_2_rounded,
                          size: 12,
                          color: AppColors.onMintContainer,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Có ghi chú',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: _isCheckingIn
                    ? 'Đang ghi nhận...'
                    : (checkedInToday
                        ? 'Cập nhật nhật ký hôm nay'
                        : 'Điểm danh hôm nay'),
                icon: checkedInToday
                    ? Icons.edit_note_rounded
                    : Icons.local_fire_department_rounded,
                backgroundColor:
                    checkedInToday ? AppColors.primary : AppColors.mint,
                onPressed: _isCheckingIn
                    ? null
                    : () {
                        final todayJournal = journals[todayIso];
                        _openJournalForDay(
                          today,
                          existingEmoji: todayJournal?.emoji,
                          existingNote: todayJournal?.note,
                          alreadyCheckedIn: checkedInToday,
                        );
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
