import 'package:flutter/material.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';

/// Modal Sheet Thiết lập Kế hoạch & Liên kết Quỹ nhóm MoMo (Dành cho Trưởng nhóm).
class SetupMomoSheet extends StatefulWidget {
  const SetupMomoSheet({super.key, required this.initialFundName});

  final String initialFundName;

  @override
  State<SetupMomoSheet> createState() => _SetupMomoSheetState();
}

class _SetupMomoSheetState extends State<SetupMomoSheet> {
  int _cycleMode = 1; // 0: Ngày | 1: Tuần | 2: Tháng
  late final TextEditingController _fundNameCtrl;
  final _fundLinkCtrl = TextEditingController(text: MockTripData.momoFundLink);
  bool _hasQrImage = true;

  @override
  void initState() {
    super.initState();
    _fundNameCtrl = TextEditingController(text: widget.initialFundName);
  }

  @override
  void dispose() {
    _fundNameCtrl.dispose();
    _fundLinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (cycleLabel, perMemberAmount) = switch (_cycleMode) {
      0 => ('ngày', 30200),
      1 => ('tuần', 212000),
      _ => ('tháng', 845000),
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy', style: TextStyle(color: AppColors.onPrimaryContainer)),
                  ),
                  const Text(
                    'Thiết lập Quỹ MoMo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO(Module 2): Lưu cấu hình SavingPlan & MoMo link lên Firestore
                      Navigator.pop(context, _fundNameCtrl.text.trim());
                    },
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Khối 1: Saving Plan Generator
              const AppSectionHeader(title: '1. Kế hoạch chia kỳ đóng quỹ'),
              AppSegmentedControl(
                segments: const ['Theo ngày', 'Theo tuần', 'Theo tháng'],
                selectedIndex: _cycleMode,
                onChanged: (i) => setState(() => _cycleMode = i),
              ),
              const SizedBox(height: 10),
              AppInsetCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mức đóng đề xuất / người',
                          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tổng 8.450.000đ • 4 thành viên',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Text(
                      '${MockTripData.formatVnd(perMemberAmount)}/$cycleLabel',
                      style: AppTheme.monoAmount(fontSize: 16, color: AppColors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Khối 2: Liên kết Quỹ nhóm MoMo
              const AppSectionHeader(title: '2. Liên kết Quỹ nhóm MoMo'),
              AppInsetCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _fundNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên Quỹ nhóm MoMo',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _fundLinkCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Đường dẫn (Link) Quỹ nhóm MoMo',
                          hintText: 'https://me.momo.vn/...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO(Module 2): Mở mobile_scanner quét QR Quỹ nhóm MoMo
                        setState(() => _hasQrImage = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('TODO(Module 2): Mở Camera quét QR MoMo')),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppColors.momo),
                      label: const Text('Quét QR MoMo', style: TextStyle(color: AppColors.onSurface)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        side: const BorderSide(color: AppColors.outlineVariantSoft),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO(Module 2): Chọn ảnh QR từ thư viện
                        setState(() => _hasQrImage = true);
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: const Text('Tải ảnh QR', style: TextStyle(color: AppColors.onSurface)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        side: const BorderSide(color: AppColors.outlineVariantSoft),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_hasQrImage) ...[
                const SizedBox(height: 12),
                AppInsetCard(
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_2, size: 44, color: AppColors.momo),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã nhận diện mã QR Quỹ nhóm MoMo',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Ứng dụng mở MoMo qua Deeplink/QR và đối soát bằng biên lai.',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Lưu cấu hình & Liên kết MoMo',
                backgroundColor: AppColors.momo,
                onPressed: () => Navigator.pop(context, _fundNameCtrl.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
