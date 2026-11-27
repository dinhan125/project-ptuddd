import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_segmented_control.dart';

/// MÃ n hÃ¬nh ThÃªm hÃ³a Ä‘Æ¡n má»›i â€” nÃ¢ng cáº¥p tá»« Stitch (th_m_h_a_n_m_i):
/// Bá»• sung nÃºt QuÃ©t hÃ³a Ä‘Æ¡n Camera OCR (ML Kit) vÃ  thanh phÃ­m mÃ¡y tÃ­nh nhanh kiá»ƒu Cashew.
class AddExpenseOcrScreen extends StatefulWidget {
  const AddExpenseOcrScreen({super.key});

  @override
  State<AddExpenseOcrScreen> createState() => _AddExpenseOcrScreenState();
}

class _AddExpenseOcrScreenState extends State<AddExpenseOcrScreen> {
  final _amountCtrl = TextEditingController(text: '680000');
  final _titleCtrl = TextEditingController(text: 'Ä‚n tá»‘i Láº©u GÃ  LÃ¡ Ã‰');
  int _selectedCat = 0;
  int _splitMode = 0; // 0: Chia Ä‘á»u | 1: TÃ¹y chá»‰nh
  final _cats = const ['Ä‚n uá»‘ng', 'Di chuyá»ƒn', 'LÆ°u trÃº', 'VÃ© tham quan'];
  final _checked = [true, true, true, true];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  int get _parsedAmount => int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final activeCount = _checked.where((e) => e).length;
    final perPerson = activeCount > 0 ? (_parsedAmount / activeCount).round() : 0;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Há»§y', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        leadingWidth: 68,
        title: const Text('ThÃªm hÃ³a Ä‘Æ¡n'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO(Module 4): LÆ°u Expense vÃ o Firestore & cáº­p nháº­t HÅ© ngÃ¢n sÃ¡ch
              context.pop();
            },
            child: const Text(
              'LÆ°u',
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
          // NÃºt QuÃ©t hÃ³a Ä‘Æ¡n tá»± Ä‘á»™ng Camera OCR (ML Kit)
          FilledButton.tonalIcon(
            onPressed: () {
              // TODO(Module 4): Má»Ÿ Camera + google_mlkit_text_recognition bÃ³c tÃ¡ch tá»•ng tiá»n
              setState(() => _amountCtrl.text = '680000');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('TODO(Module 4): Má»Ÿ Camera OCR tá»± Ä‘á»c tá»•ng tiá»n hÃ³a Ä‘Æ¡n'),
                ),
              );
            },
            icon: const Icon(Icons.document_scanner_outlined, size: 20),
            label: const Text('QuÃ©t hÃ³a Ä‘Æ¡n tá»± Ä‘á»™ng (Camera OCR)'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // Ã” nháº­p sá»‘ tiá»n lá»›n + thanh phÃ­m mÃ¡y tÃ­nh nhanh kiá»ƒu Cashew
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Sá»‘ tiá»n (VNÄ)',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: AppTheme.monoAmount(fontSize: 30, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
                const Divider(),
                const SizedBox(height: 8),
                // Thanh phÃ©p tÃ­nh nhanh Cashew
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['+', 'âˆ’', 'Ã—', 'Ã·', '+50k', '+100k']
                      .map((op) => ActionChip(
                            label: Text(op),
                            backgroundColor: AppColors.surfaceContainerLow,
                            side: const BorderSide(color: AppColors.outlineVariantSoft),
                            onPressed: () {
                              if (op == '+50k') {
                                setState(() => _amountCtrl.text = '${_parsedAmount + 50000}');
                              } else if (op == '+100k') {
                                setState(() => _amountCtrl.text = '${_parsedAmount + 100000}');
                              }
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Danh má»¥c
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = _selectedCat == index;
                return ChoiceChip(
                  label: Text(_cats[index]),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedCat = index),
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.surfaceContainer,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Chi tiáº¿t khoáº£n chi
          AppInsetCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Khoáº£n chi', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleCtrl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: AppColors.onSurfaceVariant),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 16),
                const ListTile(
                  title: Text('NgÆ°á»i tráº£'),
                  trailing: Text(
                    'Äá»— ÄÃ¬nh An',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chia tiá»n 4 thÃ nh viÃªn
          AppSegmentedControl(
            segments: const ['Chia Ä‘á»u', 'TÃ¹y chá»‰nh'],
            selectedIndex: _splitMode,
            onChanged: (i) => setState(() => _splitMode = i),
          ),
          const SizedBox(height: 10),
          AppInsetCard(
            child: Column(
              children: List.generate(MockTripData.members.length, (i) {
                final m = MockTripData.members[i];
                return Column(
                  children: [
                    CheckboxListTile(
                      value: _checked[i],
                      activeThumbColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(m.name),
                      secondary: Text(
                        _checked[i] ? MockTripData.formatVnd(perPerson) : '0Ä‘',
                        style: AppTheme.monoAmount(fontSize: 14),
                      ),
                      onChanged: (v) => setState(() => _checked[i] = v ?? false),
                    ),
                    if (i < MockTripData.members.length - 1) const Divider(indent: 52),
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

