import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';

/// Result returned from [SavingJournalDialog] when a user logs an emotion tag and note.
class SavingJournalDialogResult {
  final String emoji;
  final String note;

  const SavingJournalDialogResult({
    required this.emoji,
    required this.note,
  });
}

/// DailyYou-style Emotion Tags & Saving Journal Dialog for a streak check-in day.
class SavingJournalDialog extends StatefulWidget {
  const SavingJournalDialog({
    super.key,
    required this.date,
    this.initialEmoji,
    this.initialNote,
    this.alreadyCheckedIn = false,
  });

  final DateTime date;
  final String? initialEmoji;
  final String? initialNote;
  final bool alreadyCheckedIn;

  @override
  State<SavingJournalDialog> createState() => _SavingJournalDialogState();
}

class _SavingJournalDialogState extends State<SavingJournalDialog> {
  static const _emotionTags = [
    (emoji: '🔥', label: 'Kỷ luật'),
    (emoji: '😎', label: 'Nhẹ nhàng'),
    (emoji: '🚀', label: 'Tăng tốc'),
    (emoji: '💪', label: 'Kiên trì'),
    (emoji: '🎉', label: 'Đạt mốc'),
  ];

  static const _emotePalette = [
    '🥳', '☕', '🧋', '💰', '💎', '🎯', '✈️', '🏖️',
    '🍜', '🌟', '🙌', '❤️', '🤑', '🍀', '📈', '🏆',
  ];

  String _selectedEmoji = _emotionTags.first.emoji;
  bool _isCustomMode = false;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEmoji?.trim();
    final isPreset =
        initial == null || _emotionTags.any((t) => t.emoji == initial);
    _isCustomMode = !isPreset;
    _selectedEmoji = initial != null && initial.isNotEmpty
        ? initial
        : _emotionTags.first.emoji;
    _noteCtrl.text = widget.initialNote ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        '${widget.date.day.toString().padLeft(2, '0')}/${widget.date.month.toString().padLeft(2, '0')}/${widget.date.year}';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Nhật ký tích góp • $dayLabel',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn cảm xúc hôm nay của bạn',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._emotionTags.map((tag) {
                    final isSelected = !_isCustomMode && _selectedEmoji == tag.emoji;
                    return ChoiceChip(
                      label: Text('${tag.emoji} ${tag.label}'),
                      selected: isSelected,
                      selectedColor: AppColors.mintContainer,
                      backgroundColor: AppColors.surfaceContainerLow,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.onMintContainer
                            : AppColors.onSurface,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.mint
                            : AppColors.outlineVariantSoft,
                      ),
                      onSelected: (_) => setState(() {
                        _isCustomMode = false;
                        _selectedEmoji = tag.emoji;
                      }),
                    );
                  }),
                  ChoiceChip(
                    label: Text(
                      _isCustomMode && _emotePalette.contains(_selectedEmoji)
                          ? '$_selectedEmoji Tùy chỉnh'
                          : '✨ Khác',
                    ),
                    selected: _isCustomMode,
                    selectedColor: AppColors.mintContainer,
                    backgroundColor: AppColors.surfaceContainerLow,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isCustomMode
                          ? AppColors.onMintContainer
                          : AppColors.onSurface,
                    ),
                    side: BorderSide(
                      color: _isCustomMode
                          ? AppColors.mint
                          : AppColors.outlineVariantSoft,
                    ),
                    onSelected: (_) => setState(() {
                      _isCustomMode = true;
                      if (!_emotePalette.contains(_selectedEmoji)) {
                        _selectedEmoji = _emotePalette.first;
                      }
                    }),
                  ),
                ],
              ),
              if (_isCustomMode) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariantSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn emote',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _emotePalette.map((emoji) {
                          final active = _selectedEmoji == emoji;
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _selectedEmoji = emoji),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.mintContainer
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active
                                      ? AppColors.mint
                                      : AppColors.outlineVariantSoft,
                                ),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 18)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Ghi chú tiết kiệm',
                  hintText: 'VD: Nhịn 2 ly trà sữa góp quỹ chuyến đi!',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariantSoft),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariantSoft),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: widget.alreadyCheckedIn
                    ? 'Cập nhật nhật ký'
                    : 'Điểm danh & Lưu chuỗi',
                backgroundColor: AppColors.mint,
                onPressed: () {
                  Navigator.of(context).pop(
                    SavingJournalDialogResult(
                      emoji: _selectedEmoji,
                      note: _noteCtrl.text.trim(),
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
