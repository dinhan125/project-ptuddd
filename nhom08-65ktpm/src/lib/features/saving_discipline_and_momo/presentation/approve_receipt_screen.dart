import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_status_badge.dart';

/// Màn hình Duyệt Biên Lai Nạp Quỹ (Dành cho Trưởng nhóm / Fund Host).
class ApproveReceiptScreen extends StatefulWidget {
  const ApproveReceiptScreen({super.key});

  @override
  State<ApproveReceiptScreen> createState() => _ApproveReceiptScreenState();
}

class _ApproveReceiptScreenState extends State<ApproveReceiptScreen> {
  int _filterIndex = 0; // 0: Chờ duyệt | 1: Đã duyệt | 2: Từ chối
  late final Map<String, String> _statusOverrides;

  @override
  void initState() {
    super.initState();
    _statusOverrides = {
      for (final r in MockTripData.receiptRequests) r.id: r.status,
    };
  }

  void _approve(MockReceiptRequest req) {
    // TODO(Module 2): Cập nhật Firestore (status = approved, cộng quỹ & cộng Streak)
    setState(() => _statusOverrides[req.id] = 'approved');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xác nhận biên lai của ${req.memberName} (+212.000đ)')),
    );
  }

  Future<void> _rejectWithReason(MockReceiptRequest req) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối biên lai'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do (VD: Ảnh mờ, thiếu mã giao dịch...)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _statusOverrides[req.id] = 'rejected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetStatus = switch (_filterIndex) {
      0 => 'pending',
      1 => 'approved',
      _ => 'rejected',
    };
    final list = MockTripData.receiptRequests
        .where((r) => _statusOverrides[r.id] == targetStatus)
        .toList();
    final pendingCount = _statusOverrides.values.where((s) => s == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text('Duyệt biên lai ($pendingCount)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSegmentedControl(
            segments: ['Chờ duyệt ($pendingCount)', 'Đã duyệt', 'Từ chối'],
            selectedIndex: _filterIndex,
            onChanged: (i) => setState(() => _filterIndex = i),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(
                child: Text(
                  'Không có biên lai nào trong mục này.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            )
          else
            ...list.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AppInsetCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(
                                req.memberInitials,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.memberName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${req.cycleLabel} • ${req.submittedAt}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              MockTripData.formatVnd(req.amount),
                              style: AppTheme.monoAmount(fontSize: 16, color: AppColors.momo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Khung xem trước ảnh biên lai MoMo
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineVariantSoft),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.momoContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long, color: AppColors.momo),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mã GD MoMo: ${req.momoTransId}',
                                      style: AppTheme.monoAmount(fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${req.moodEmoji} ${req.note}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Phóng to biên lai',
                                icon: const Icon(Icons.zoom_in, color: AppColors.primary),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('TODO(Module 2): Mở hộp thoại xem ảnh biên lai gốc'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (targetStatus == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => _rejectWithReason(req),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.errorContainer,
                                    foregroundColor: AppColors.onErrorContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Từ chối'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _approve(req),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.mint,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Xác nhận hợp lệ'),
                                ),
                              ),
                            ],
                          )
                        else
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppStatusBadge(
                              label: targetStatus == 'approved' ? 'Đã xác nhận' : 'Đã từ chối',
                              tone: targetStatus == 'approved'
                                  ? AppBadgeTone.mint
                                  : AppBadgeTone.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
