import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../utils/momo_deeplink_helper.dart';
import '../utils/momo_launcher.dart';

/// Modal Sheet Nạp Quỹ MoMo & Nộp Biên Lai (Dành cho Thành viên).
/// Thiết kế 2 bước rõ ràng: Bước 1 mở MoMo (kèm QR & Copy fallback) -> Bước 2 tải biên lai & cảm xúc DailyYou.
class DepositReceiptSheet extends StatefulWidget {
  const DepositReceiptSheet({
    super.key,
    required this.fundName,
    this.momoLink,
    this.phoneNumber,
    this.qrData,
  });

  final String fundName;
  final String? momoLink;
  final String? phoneNumber;
  final String? qrData;

  @override
  State<DepositReceiptSheet> createState() => _DepositReceiptSheetState();
}

class _DepositReceiptSheetState extends State<DepositReceiptSheet> {
  final _noteCtrl = TextEditingController(text: 'Nhịn 2 ly trà sữa góp quỹ đúng hạn!');
  final _moods = const ['🔥', '😎', '🚀', '💪', '🎉'];
  int _selectedMood = 0;
  bool _showQrFallback = false;
  bool _hasReceiptPhoto = false;

  Future<void> _launchMoMo(String link, String copySummary) async {
    final launched = await MoMoLauncher.openMoMo(
      context,
      deeplink: link,
      copySummary: copySummary,
    );
    if (!launched && mounted) {
      setState(() => _showQrFallback = true);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const transferNote = 'An nop quy Da Lat ky 6';

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
                    child: const Text('Đóng', style: TextStyle(color: AppColors.onPrimaryContainer)),
                  ),
                  const Text(
                    'Nạp quỹ ${MockTripData.currentCycleLabel}',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
              const SizedBox(height: 8),

              // BƯỚC 1: Mở MoMo + Fallback QR / Copy
              const AppSectionHeader(title: 'Bước 1 — Chuyển tiền vào Quỹ nhóm MoMo'),
              AppInsetCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      widget.fundName,
                      style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MockTripData.formatVnd(MockTripData.perMemberCycleAmount),
                      style: AppTheme.monoAmount(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nội dung gợi ý: $transferNote',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    AppPrimaryButton(
                      label: 'Mở ứng dụng MoMo ngay',
                      icon: Icons.open_in_new,
                      backgroundColor: AppColors.momo,
                      onPressed: () {
                        final link = (widget.momoLink?.isNotEmpty == true)
                            ? widget.momoLink!
                            : (widget.phoneNumber?.isNotEmpty == true
                                ? MoMoDeeplinkHelper.buildFallbackLink(widget.phoneNumber!)
                                : MockTripData.momoFundLink);
                        _launchMoMo(
                          link,
                          widget.phoneNumber?.isNotEmpty == true
                              ? widget.phoneNumber!
                              : transferNote,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _showQrFallback = !_showQrFallback),
                            icon: const Icon(Icons.qr_code_2, size: 18),
                            label: Text(_showQrFallback ? 'Ẩn mã QR' : 'Hiện mã QR'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: const BorderSide(color: AppColors.outlineVariantSoft),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(text: '212000 - $transferNote'),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã sao chép số tiền & nội dung nộp quỹ')),
                              );
                            },
                            icon: const Icon(Icons.content_copy, size: 17),
                            label: const Text('Sao chép'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurface,
                              side: const BorderSide(color: AppColors.outlineVariantSoft),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showQrFallback) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariantSoft),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: (widget.qrData?.isNotEmpty == true)
                                  ? widget.qrData!
                                  : ((widget.momoLink?.isNotEmpty == true)
                                      ? widget.momoLink!
                                      : MockTripData.momoFundLink),
                              version: QrVersions.auto,
                              size: 150,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Quét bằng app MoMo nếu Deeplink không tự mở',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // BƯỚC 2: Tải biên lai & ghi nhận Streak DailyYou
              const AppSectionHeader(title: 'Bước 2 — Tải biên lai & Ghi nhận Streak'),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // TODO(Module 2): Mở image_picker chọn ảnh chụp màn hình giao dịch MoMo
                  setState(() => _hasReceiptPhoto = true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _hasReceiptPhoto
                        ? AppColors.mintContainer
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasReceiptPhoto ? AppColors.mint : AppColors.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasReceiptPhoto ? Icons.check_circle : Icons.cloud_upload_outlined,
                        color: _hasReceiptPhoto ? AppColors.onMintContainer : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hasReceiptPhoto
                            ? 'Đã chọn ảnh biên lai MoMo (IMG_2026.jpg)'
                            : 'Chụp / Tải ảnh biên lai giao dịch MoMo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _hasReceiptPhoto
                              ? AppColors.onMintContainer
                              : AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cảm xúc & ghi chú ngắn kiểu DailyYou
              AppInsetCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_moods.length, (index) {
                        final active = _selectedMood == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = index),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                              border: active
                                  ? Border.all(color: AppColors.primary, width: 1.5)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(_moods[index], style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Ghi chú ngắn cho chuỗi kỷ luật...',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AppPrimaryButton(
                label: 'Gửi Trưởng nhóm xác nhận',
                onPressed: () {
                  // TODO(Module 2): Upload ảnh lên Firebase Storage & tạo bản ghi chờ duyệt
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi biên lai! Trạng thái chuyển sang Chờ Trưởng nhóm duyệt.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
