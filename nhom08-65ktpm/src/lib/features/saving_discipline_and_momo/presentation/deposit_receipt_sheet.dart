import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../models/saving_plan.dart';
import '../providers/receipt_approval_provider.dart';
import '../utils/momo_deeplink_helper.dart';
import '../utils/momo_launcher.dart';
import 'widgets/module_provider_scope.dart';

/// Modal Sheet Nạp Quỹ MoMo & Nộp Biên Lai (Dành cho Thành viên).
/// Thiết kế 2 bước rõ ràng: Bước 1 mở MoMo (kèm QR & Copy fallback) -> Bước 2 tải biên lai & cảm xúc DailyYou.
class DepositReceiptSheet extends StatelessWidget {
  const DepositReceiptSheet({
    super.key,
    required this.fundName,
    this.tripId = 'trip_demo_01',
    this.memberId = 'member_demo_01',
    this.memberName = 'Thành viên',
    this.amount = 212000,
    this.installmentIndex = 1,
    this.cycleLabel = 'Kỳ hiện tại',
    this.termDueDate,
    this.termFrequency,
    this.momoLink,
    this.phoneNumber,
    this.qrData,
  });

  final String fundName;
  final String tripId;
  final String memberId;
  final String memberName;
  final double amount;
  final int installmentIndex;
  final String cycleLabel;
  final DateTime? termDueDate;
  final SavingFrequency? termFrequency;
  final String? momoLink;
  final String? phoneNumber;
  final String? qrData;

  @override
  Widget build(BuildContext context) {
    return ModuleProviderScope(
      child: _DepositReceiptContent(
        fundName: fundName,
        tripId: tripId,
        memberId: memberId,
        memberName: memberName,
        amount: amount,
        installmentIndex: installmentIndex,
        cycleLabel: cycleLabel,
        termDueDate: termDueDate,
        termFrequency: termFrequency,
        momoLink: momoLink,
        phoneNumber: phoneNumber,
        qrData: qrData,
      ),
    );
  }
}

class _DepositReceiptContent extends ConsumerStatefulWidget {
  const _DepositReceiptContent({
    required this.fundName,
    required this.tripId,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.installmentIndex,
    required this.cycleLabel,
    this.termDueDate,
    this.termFrequency,
    this.momoLink,
    this.phoneNumber,
    this.qrData,
  });

  final String fundName;
  final String tripId;
  final String memberId;
  final String memberName;
  final double amount;
  final int installmentIndex;
  final String cycleLabel;
  final DateTime? termDueDate;
  final SavingFrequency? termFrequency;
  final String? momoLink;
  final String? phoneNumber;
  final String? qrData;

  @override
  ConsumerState<_DepositReceiptContent> createState() => _DepositReceiptContentState();
}

class _DepositReceiptContentState extends ConsumerState<_DepositReceiptContent> {
  final _noteCtrl = TextEditingController(text: 'Nhịn 2 ly trà sữa góp quỹ đúng hạn!');
  final _moods = const ['🔥', '😎', '🚀', '💪', '🎉'];
  int _selectedMood = 0;
  bool _showQrFallback = false;
  bool _isSubmitting = false;
  File? _receiptImage;
  String? _errorMessage;

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

  Future<void> _pickReceiptImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Chụp ảnh biên lai mới'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _receiptImage = File(picked.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Không thể chọn ảnh biên lai: $e');
    }
  }

  Future<void> _submitReceipt() async {
    if (_isSubmitting) return;
    if (_receiptImage == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn ảnh chụp biên lai giao dịch MoMo';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(receiptApprovalProvider(widget.tripId).notifier).submitDeposit(
            memberId: widget.memberId,
            memberName: widget.memberName,
            amount: widget.amount,
            installmentIndex: widget.installmentIndex,
            termDueDate: widget.termDueDate,
            termFrequency: widget.termFrequency,
            receiptImage: _receiptImage,
            note: _noteCtrl.text,
            emotionTag: _moods[_selectedMood],
          );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi biên lai! Trạng thái chuyển sang Chờ Trưởng nhóm duyệt.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gửi biên lai thất bại: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transferNote = MoMoDeeplinkHelper.buildTransferNote(
      tripId: widget.tripId,
      memberName: widget.memberName,
    );
    final formattedAmount = MoMoDeeplinkHelper.formatVnd(widget.amount.round());
    final effectiveLink = (widget.momoLink?.isNotEmpty == true)
        ? widget.momoLink!
        : (widget.phoneNumber?.isNotEmpty == true
            ? MoMoDeeplinkHelper.buildFallbackLink(widget.phoneNumber!)
            : '');
    final qrData = (widget.qrData?.isNotEmpty == true) ? widget.qrData! : effectiveLink;
    final receiptFileName = _receiptImage?.path.split(Platform.pathSeparator).last;

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
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Đóng', style: TextStyle(color: AppColors.onPrimaryContainer)),
                  ),
                  Expanded(
                    child: Text(
                      'Nạp quỹ ${widget.cycleLabel}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                      formattedAmount,
                      style: AppTheme.monoAmount(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nội dung gợi ý: $transferNote',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    AppPrimaryButton(
                      label: 'Mở ứng dụng MoMo ngay',
                      icon: Icons.open_in_new,
                      backgroundColor: AppColors.momo,
                      onPressed: effectiveLink.isEmpty
                          ? null
                          : () {
                              _launchMoMo(
                                effectiveLink,
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
                            onPressed: qrData.isEmpty
                                ? null
                                : () => setState(() => _showQrFallback = !_showQrFallback),
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
                                ClipboardData(text: '${widget.amount.round()} - $transferNote'),
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
                    if (_showQrFallback && qrData.isNotEmpty) ...[
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
                              data: qrData,
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
                onTap: _isSubmitting ? null : _pickReceiptImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: _receiptImage != null
                        ? AppColors.mintContainer
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _receiptImage != null ? AppColors.mint : AppColors.outline,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_receiptImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _receiptImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _receiptImage != null
                                ? Icons.check_circle
                                : Icons.cloud_upload_outlined,
                            color: _receiptImage != null
                                ? AppColors.onMintContainer
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _receiptImage != null
                                  ? 'Đã chọn: $receiptFileName (chạm để đổi)'
                                  : 'Chụp / Tải ảnh biên lai giao dịch MoMo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _receiptImage != null
                                    ? AppColors.onMintContainer
                                    : AppColors.onPrimaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              AppPrimaryButton(
                label: _isSubmitting ? 'Đang tải biên lai...' : 'Gửi Trưởng nhóm xác nhận',
                onPressed: _isSubmitting ? null : _submitReceipt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
