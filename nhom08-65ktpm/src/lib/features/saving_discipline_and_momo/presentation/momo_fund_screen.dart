import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/momo_fund_config.dart';
import '../providers/momo_fund_provider.dart';
import 'deposit_receipt_sheet.dart';
import 'screens/momo_payment_screen.dart';
import 'setup_momo_sheet.dart';
import 'widgets/daily_you_streak_calendar.dart';

/// Tab 2 — Quỹ MoMo (Module 2 — Trọng tâm Liên kết Quỹ trong app với Quỹ nhóm MoMo).
/// Gồm: Thẻ liên kết MoMo, Tiến độ Gây dựng Quỹ, Kỳ đóng quỹ hiện tại,
/// Lịch chuỗi kỷ luật Saving Streak kiểu DailyYou, Hàng đợi duyệt biên lai & Tiến độ 4 thành viên.
class MomoFundScreen extends ConsumerStatefulWidget {
  const MomoFundScreen({
    super.key,
    this.tripId = 'trip_demo_01',
    this.memberId = 'member_demo_01',
  });

  final String tripId;
  final String memberId;

  @override
  ConsumerState<MomoFundScreen> createState() => _MomoFundScreenState();
}

class _MomoFundScreenState extends ConsumerState<MomoFundScreen> {
  bool _isLinked = MockTripData.isMomoLinked;
  String _fundName = MockTripData.momoFundName;

  Future<void> _openSetupMoMoSheet([MoMoFundConfig? currentConfig]) async {
    final updatedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetupMomoSheet(
        tripId: widget.tripId,
        initialFundName: currentConfig?.fundName ?? _fundName,
        initialPhoneNumber: currentConfig?.momoPhoneNumber ?? '',
        initialFundLink: currentConfig?.momoFundDeeplink ?? '',
      ),
    );
    if (updatedName != null && updatedName.isNotEmpty) {
      setState(() {
        _fundName = updatedName;
        _isLinked = true;
      });
    }
  }

  void _openPaymentScreen(MoMoFundConfig config) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MomoPaymentScreen(
          config: config,
          memberName: 'Thành viên',
        ),
      ),
    );
  }

  Future<void> _openDepositSheet([MoMoFundConfig? currentConfig]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositReceiptSheet(
        fundName: currentConfig?.fundName ?? _fundName,
        momoLink: currentConfig?.momoFundDeeplink ?? MockTripData.momoFundLink,
        phoneNumber: currentConfig?.momoPhoneNumber,
        qrData: currentConfig?.qrCodeUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fundConfigAsync = ref.watch(momoFundStreamProvider(widget.tripId));
    final fundConfig = fundConfigAsync.value;
    final isLinked = fundConfig != null || _isLinked;
    final fundName = fundConfig?.fundName ?? _fundName;

    final progress =
        (MockTripData.currentSavedFund / MockTripData.totalTargetFund).clamp(0.0, 1.0);
    final pendingCount =
        MockTripData.receiptRequests.where((r) => r.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => context.go('/trips'),
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer),
          label: const Text('Chuyến đi', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        title: const Text('Quỹ MoMo'),
        actions: [
          IconButton(
            tooltip: 'Thiết lập kế hoạch & Liên kết MoMo',
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () => _openSetupMoMoSheet(fundConfig),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Thẻ Liên kết Quỹ nhóm MoMo
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.momoContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'M',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.momo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLinked ? fundName : 'Chưa liên kết Quỹ nhóm MoMo',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          AppStatusBadge(
                            label: isLinked ? 'Đã liên kết Quỹ nhóm MoMo' : 'Cần Trưởng nhóm gắn link/QR',
                            tone: isLinked ? AppBadgeTone.mint : AppBadgeTone.amber,
                            icon: isLinked ? Icons.verified : Icons.link_off,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cấu hình liên kết MoMo',
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.onSurfaceVariant),
                      onPressed: () => _openSetupMoMoSheet(fundConfig),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: isLinked ? 'Mở MoMo nạp quỹ' : 'Gắn link / QR MoMo',
                        icon: isLinked ? Icons.open_in_new : Icons.qr_code_scanner,
                        backgroundColor: AppColors.momo,
                        onPressed: isLinked
                            ? () {
                                final effectiveConfig = fundConfig ??
                                    MoMoFundConfig(
                                      tripId: widget.tripId,
                                      fundName: fundName,
                                      hostUserId: 'host_01',
                                      hostName: 'Trưởng nhóm',
                                      momoPhoneNumber: '',
                                      momoFundDeeplink: MockTripData.momoFundLink,
                                      qrCodeUrl: MockTripData.momoFundLink,
                                      targetTotalAmount: MockTripData.totalTargetFund.toDouble(),
                                      updatedAt: DateTime.now(),
                                    );
                                _openPaymentScreen(effectiveConfig);
                              }
                            : () => _openSetupMoMoSheet(fundConfig),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Banner Hàng đợi duyệt biên lai (chỉ hiện với Trưởng nhóm / Fund Host)
          if (pendingCount > 0) ...[
            GestureDetector(
              onTap: () => context.push('/trip/momo/approve'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.amberContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions, color: AppColors.onAmberContainer, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Có $pendingCount biên lai nạp quỹ MoMo đang chờ Trưởng nhóm duyệt',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onAmberContainer,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.onAmberContainer),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Thẻ Tiến độ Gây dựng Quỹ & Kỳ đóng quỹ hiện tại
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ Quỹ tích lũy',
                      style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTheme.monoAmount(fontSize: 15, color: AppColors.onMintContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  MockTripData.formatVnd(MockTripData.currentSavedFund),
                  style: AppTheme.monoAmount(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Mục tiêu: ${MockTripData.formatVnd(MockTripData.totalTargetFund)} (4 thành viên)',
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.mint),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kỳ hiện tại (${MockTripData.currentCycleLabel})',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '212.000đ • Hạn ${MockTripData.currentCycleDue}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _openDepositSheet(fundConfig),
                      icon: const Icon(Icons.upload_file, size: 17),
                      label: const Text('Nộp biên lai'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Lịch Chuỗi Kỷ luật Tích góp (Saving Streak Calendar — kế thừa DailyYou)
          DailyYouStreakCalendar(
            tripId: widget.tripId,
            memberId: widget.memberId,
          ),
          const SizedBox(height: 24),

          // 5. Tiến độ đóng góp từng thành viên
          AppSectionHeader(
            title: 'Tiến độ thành viên (${MockTripData.currentCycleLabel})',
            trailing: GestureDetector(
              onTap: () => context.push('/trip/momo/approve'),
              child: const Text(
                'Duyệt biên lai',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          AppInsetCard(
            child: Column(
              children: List.generate(MockTripData.members.length, (idx) {
                final m = MockTripData.members[idx];
                final (badgeText, tone) = switch (m.currentCycleStatus) {
                  'confirmed' => ('Đã xác nhận', AppBadgeTone.mint),
                  'pending' => ('Chờ duyệt', AppBadgeTone.amber),
                  _ => ('Chưa đóng', AppBadgeTone.error),
                };
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        child: Text(
                          m.initials,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        '${MockTripData.formatVnd(m.contributedAmount)} / ${MockTripData.formatVnd(m.targetAmount)} • 🔥${m.streakWeeks}',
                        style: AppTheme.monoAmount(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      trailing: AppStatusBadge(label: badgeText, tone: tone),
                    ),
                    if (idx < MockTripData.members.length - 1) const Divider(indent: 72),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
