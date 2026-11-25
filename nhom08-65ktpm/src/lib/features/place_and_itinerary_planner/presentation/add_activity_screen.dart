import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';

/// Màn hình Thêm hoạt động mới — chuyển từ Stitch (th_m_ho_t_ng_m_i).
class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  int _catIndex = 0;
  bool _remindBefore = true;
  final _cats = const ['Ăn uống', 'Di chuyển', 'Tham quan', 'Lưu trú'];
  final _titleCtrl = TextEditingController(text: 'Ăn tối Lẩu Gà Lá É');
  final _placeCtrl = TextEditingController(text: '5 Đường 3/4, TP. Đà Lạt');
  final _costCtrl = TextEditingController(text: '680.000đ');
  final _noteCtrl = TextEditingController(text: 'Đặt bàn trước cho 4 người.');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _placeCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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
        title: const Text('Thêm hoạt động'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO(Module 3): Lưu PlacePlan vào Firestore & cộng dồn chi phí dự kiến
              context.pop();
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
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = _catIndex == index;
                return ChoiceChip(
                  label: Text(_cats[index]),
                  selected: active,
                  onSelected: (_) => setState(() => _catIndex = index),
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
          AppInsetCard(
            child: Column(
              children: [
                _FieldRow(label: 'Hoạt động', controller: _titleCtrl),
                const Divider(indent: 16),
                const ListTile(
                  title: Text('Bắt đầu'),
                  trailing: Text('18:30', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const Divider(indent: 16),
                const ListTile(
                  title: Text('Kết thúc'),
                  trailing: Text('20:30', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const Divider(indent: 16),
                _FieldRow(label: 'Địa điểm', controller: _placeCtrl),
                const Divider(indent: 16),
                _FieldRow(label: 'Chi phí dự kiến', controller: _costCtrl),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppInsetCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppInsetCard(
            child: SwitchListTile(
              title: const Text('Nhắc trước 15 phút'),
              value: _remindBefore,
              activeColor: AppColors.mint,
              onChanged: (v) => setState(() => _remindBefore = v),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
