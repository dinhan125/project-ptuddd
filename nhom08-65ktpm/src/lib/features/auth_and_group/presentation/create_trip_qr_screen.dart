import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';

/// Màn hình Tạo chuyến đi & Mã QR — chuyển từ Stitch (t_o_chuy_n_i_m_qr),
/// đã sửa lỗi tương phản nút "Chia sẻ" (chữ trắng trên nền xanh #007AFF).
class CreateTripQrScreen extends StatefulWidget {
  const CreateTripQrScreen({super.key});

  @override
  State<CreateTripQrScreen> createState() => _CreateTripQrScreenState();
}

class _CreateTripQrScreenState extends State<CreateTripQrScreen> {
  final _nameCtrl = TextEditingController(text: MockTripData.tripName);
  final _destCtrl = TextEditingController(text: MockTripData.tripDestination);
  final _startCtrl = TextEditingController(text: '15/11/2026');
  final _endCtrl = TextEditingController(text: '18/11/2026');
  final _budgetCtrl = TextEditingController(text: '8.450.000đ');
  bool _copied = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyInviteCode() async {
    await Clipboard.setData(const ClipboardData(text: MockTripData.inviteCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Hủy', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        leadingWidth: 68,
        title: const Text('Tạo chuyến đi'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO(Module 1): Lưu TripGoal vào Firestore
              context.go('/trip/checklist');
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ảnh bìa
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // TODO(Module 1): Mở image_picker chọn ảnh bìa chuyến đi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('TODO(Module 1): Chọn ảnh bìa từ thư viện')),
              );
            },
            child: Container(
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 26),
                  SizedBox(height: 6),
                  Text('Chọn ảnh bìa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(
                    'PNG, JPG tối đa 5MB',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const AppSectionHeader(title: 'Thông tin chuyến đi'),
          AppInsetCard(
            child: Column(
              children: [
                _InputRow(label: 'Tên', controller: _nameCtrl),
                const Divider(indent: 16),
                _InputRow(label: 'Địa điểm', controller: _destCtrl),
                const Divider(indent: 16),
                _InputRow(label: 'Ngày đi', controller: _startCtrl, isMono: true),
                const Divider(indent: 16),
                _InputRow(label: 'Ngày về', controller: _endCtrl, isMono: true),
                const Divider(indent: 16),
                _InputRow(
                  label: 'Mục tiêu quỹ',
                  controller: _budgetCtrl,
                  isMono: true,
                  valueColor: AppColors.onPrimaryContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const AppSectionHeader(title: 'Mời thành viên'),
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Khung QR mẫu (TODO: thay bằng QrImageView của qr_flutter)
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariantSoft),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 96, color: AppColors.onSurface),
                      Text(
                        'QR MỜI NHÓM',
                        style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mã mời nhóm',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  MockTripData.inviteCode,
                  style: AppTheme.monoAmount(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton.tonalIcon(
                          onPressed: _copyInviteCode,
                          icon: Icon(_copied ? Icons.check : Icons.content_copy, size: 18),
                          label: Text(_copied ? 'Đã sao chép' : 'Sao chép mã'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            foregroundColor: AppColors.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/trip/members'),
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: const Text('Chia sẻ'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    this.isMono = false,
    this.valueColor = AppColors.onSurfaceVariant,
  });

  final String label;
  final TextEditingController controller;
  final bool isMono;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: isMono
                  ? AppTheme.monoAmount(fontSize: 15, color: valueColor)
                  : TextStyle(fontSize: 16, color: valueColor),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
