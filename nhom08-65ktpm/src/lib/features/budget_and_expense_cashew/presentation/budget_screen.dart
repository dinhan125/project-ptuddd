import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';

/// Tab 4 — Ngân sách Cashew & Quyết toán (Module 4):
/// Nâng cấp từ Stitch (qu_nh_m_c_ng_n_l_t_4n3), bổ sung Hũ ngân sách Cashew,
/// Biểu đồ đối chiếu Dự kiến vs. Tích lũy vs. Thực chi và hộp thoại xác nhận Thanh toán tối giản.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _debt1Paid = false;

  Future<void> _confirmPayDebt() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đã thanh toán'),
        content: const Text('Xác nhận Nguyễn Xuân Bình đã chuyển 350.000đ cho Đỗ Đình An?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _debt1Paid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = MockTripData.envelopes.fold<int>(0, (sum, e) => sum + e.spent);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => context.go('/trips'),
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer),
          label: const Text('Chuyến đi', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        title: const Text('Ngân sách'),
        actions: [
          IconButton(
            tooltip: 'Thêm hóa đơn / Quét OCR',
            icon: const Icon(Icons.add, color: AppColors.primary, size: 26),
            onPressed: () => context.push('/trip/budget/add'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Thẻ tổng quan + Biểu đồ đối chiếu 3 cột (Dự kiến vs. Tích lũy vs. Thực chi)
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thực chi nhóm',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  MockTripData.formatVnd(totalSpent),
                  style: AppTheme.monoAmount(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),

                // Biểu đồ thanh ngang đối chiếu 3 chỉ số (TODO: thay bằng fl_chart nếu cần)
                _ComparisonBar(
                  label: 'Kế hoạch',
                  amount: MockTripData.totalTargetFund,
                  ratio: 1.0,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _ComparisonBar(
                  label: 'Quỹ MoMo',
                  amount: MockTripData.currentSavedFund,
                  ratio: MockTripData.currentSavedFund / MockTripData.totalTargetFund,
                  color: AppColors.momo,
                ),
                const SizedBox(height: 8),
                _ComparisonBar(
                  label: 'Thực chi',
                  amount: totalSpent,
                  ratio: (totalSpent / MockTripData.totalTargetFund).clamp(0.0, 1.0),
                  color: AppColors.mint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Hũ ngân sách dự kiến kiểu Cashew
          const AppSectionHeader(title: 'Hũ ngân sách (Cashew Envelopes)'),
          AppInsetCard(
            child: Column(
              children: List.generate(MockTripData.envelopes.length, (idx) {
                final env = MockTripData.envelopes[idx];
                final pct = env.planned == 0 ? 0.0 : (env.spent / env.planned).clamp(0.0, 1.0);
                final isNearLimit = pct >= 0.85;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(env.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${MockTripData.formatVnd(env.spent)} / ${MockTripData.formatVnd(env.planned)}',
                                style: AppTheme.monoAmount(
                                  fontSize: 13,
                                  color: isNearLimit
                                      ? AppColors.onAmberContainer
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceContainerHigh,
                              valueColor: AlwaysStoppedAnimation(
                                isNearLimit ? AppColors.amber : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (idx < MockTripData.envelopes.length - 1) const Divider(indent: 16),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Thanh toán tối giản (có xác nhận an toàn)
          const AppSectionHeader(title: 'Thanh toán tối giản'),
          AppInsetCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Nguyễn Xuân Bình trả Đỗ Đình An'),
                  subtitle: _debt1Paid
                      ? const Text(
                          'Đã thanh toán',
                          style: TextStyle(color: AppColors.onMintContainer),
                        )
                      : GestureDetector(
                          onTap: _confirmPayDebt,
                          child: const Text(
                            'Xác nhận đã trả',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                  trailing: Text('350.000đ', style: AppTheme.monoAmount()),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('Đỗ Tùng Khánh trả Đỗ Đình An'),
                  subtitle: const AppStatusBadge(label: 'Đã thanh toán', tone: AppBadgeTone.mint),
                  trailing: Text(
                    '330.000đ',
                    style: AppTheme.monoAmount(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Chi tiêu gần đây
          const AppSectionHeader(title: 'Chi tiêu gần đây'),
          AppInsetCard(
            child: Column(
              children: List.generate(MockTripData.expenses.length, (idx) {
                final ex = MockTripData.expenses[idx];
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                      title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${ex.payerName} trả • ${ex.splitCount} người'),
                      trailing: Text(
                        MockTripData.formatVnd(ex.amount),
                        style: AppTheme.monoAmount(),
                      ),
                      onTap: () => context.push('/trip/budget/detail'),
                    ),
                    if (idx < MockTripData.expenses.length - 1) const Divider(indent: 56),
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

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int amount;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            MockTripData.formatVnd(amount),
            textAlign: TextAlign.right,
            style: AppTheme.monoAmount(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
