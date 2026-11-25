import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_status_badge.dart';

/// Tab 1 — Chuẩn bị (Module 1):
/// Nâng cấp từ Đồ dùng chung của Stitch, bổ sung Countdown + 2 vòng tròn sẵn sàng,
/// Segmented Control (Việc theo mốc | Hành lý), Smart Templates và Camera chụp ảnh xác nhận.
class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  int _tabIndex = 0; // 0: Việc theo mốc | 1: Hành lý
  late List<MockChecklistItem> _items;

  @override
  void initState() {
    super.initState();
    _items = MockTripData.initialChecklist();
  }

  void _showTemplatesSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thư viện Mẫu Checklist (Smart Templates)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AppInsetCard(
                child: Column(
                  children: [
                    _TemplateTile(
                      icon: Icons.terrain,
                      title: 'Du lịch núi / Săn mây (Đà Lạt, Sa Pa)',
                      subtitle: 'Áo ấm, đèn pin, thuốc say xe, giày bám...',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('TODO(Module 1): Áp dụng mẫu Du lịch núi')),
                        );
                      },
                    ),
                    const Divider(indent: 56),
                    _TemplateTile(
                      icon: Icons.beach_access,
                      title: 'Du lịch biển (Phú Quốc, Nha Trang)',
                      subtitle: 'Kem chống nắng, đồ bơi, túi chống nước...',
                      onTap: () => Navigator.pop(context),
                    ),
                    const Divider(indent: 56),
                    _TemplateTile(
                      icon: Icons.two_wheeler,
                      title: 'Phượt xe máy / Cắm trại',
                      subtitle: 'Lều trại, bộ vá xe, áo mưa bộ, sạc dự phòng...',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((e) => e.isPacking == (_tabIndex == 1)).toList();
    final totalDone = _items.where((e) => e.isDone).length;
    final checklistProgress = _items.isEmpty ? 0.0 : totalDone / _items.length;
    final fundProgress =
        (MockTripData.currentSavedFund / MockTripData.totalTargetFund).clamp(0.0, 1.0);

    // Nhóm theo groupLabel
    final grouped = <String, List<MockChecklistItem>>{};
    for (final item in filtered) {
      grouped.putIfAbsent(item.groupLabel, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => context.go('/trips'),
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer),
          label: const Text('Chuyến đi', style: TextStyle(color: AppColors.onPrimaryContainer)),
        ),
        title: const Text(MockTripData.tripName),
        actions: [
          IconButton(
            tooltip: 'Thành viên & Hồ sơ',
            icon: const Icon(Icons.group_outlined, color: AppColors.primary),
            onPressed: () => context.push('/trip/members'),
          ),
          IconButton(
            tooltip: 'Thư viện mẫu',
            icon: const Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
            onPressed: _showTemplatesSheet,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thẻ Countdown & 2 vòng tròn tiến độ sẵn sàng trước giờ G
          AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đếm ngược khởi hành',
                          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Còn ${MockTripData.daysUntilTrip} ngày',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const AppStatusBadge(
                      label: MockTripData.tripDateRange,
                      tone: AppBadgeTone.primary,
                      icon: Icons.event,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ReadinessRingTile(
                        title: 'Quỹ MoMo',
                        percent: fundProgress,
                        color: AppColors.momo,
                        subtitle: '${(fundProgress * 100).round()}% mục tiêu',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ReadinessRingTile(
                        title: 'Chuẩn bị',
                        percent: checklistProgress,
                        color: AppColors.mint,
                        subtitle: '$totalDone/${_items.length} đầu việc',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Segmented Control: Việc theo mốc | Hành lý
          AppSegmentedControl(
            segments: const ['Việc theo mốc', 'Hành lý & Đồ chung'],
            selectedIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          const SizedBox(height: 20),

          // Các nhóm Checklist
          ...grouped.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionHeader(title: entry.key),
                    AppInsetCard(
                      child: Column(
                        children: List.generate(entry.value.length, (idx) {
                          final item = entry.value[idx];
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => item.isDone = !item.isDone),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: item.isDone
                                              ? AppColors.mintContainer
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: item.isDone
                                                ? AppColors.mint
                                                : AppColors.outline,
                                            width: 2,
                                          ),
                                        ),
                                        child: item.isDone
                                            ? const Icon(
                                                Icons.check,
                                                size: 15,
                                                color: AppColors.onMintContainer,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              decoration: item.isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: item.isDone
                                                  ? AppColors.onSurfaceVariant
                                                  : AppColors.onSurface,
                                            ),
                                          ),
                                          if (item.hasProofPhoto)
                                            const Padding(
                                              padding: EdgeInsets.only(top: 3),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.verified,
                                                      size: 13, color: AppColors.mint),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Đã chụp ảnh xác thực',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.onMintContainer,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Chụp ảnh xác nhận hoàn thành',
                                      icon: Icon(
                                        item.hasProofPhoto
                                            ? Icons.photo_camera
                                            : Icons.photo_camera_outlined,
                                        size: 20,
                                        color: item.hasProofPhoto
                                            ? AppColors.mint
                                            : AppColors.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        // TODO(Module 1): Mở Camera chụp minh chứng & lưu Storage
                                        setState(() {
                                          item.hasProofPhoto = true;
                                          item.isDone = true;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Đã đính kèm ảnh xác nhận: ${item.title}'),
                                          ),
                                        );
                                      },
                                    ),
                                    if (item.assignee != null)
                                      Text(
                                        item.assignee!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      )
                                    else
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                        ),
                                        onPressed: () =>
                                            setState(() => item.assignee = 'Đình An'),
                                        child: const Text(
                                          'Nhận việc',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (idx < entry.value.length - 1) const Divider(indent: 50),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ReadinessRingTile extends StatelessWidget {
  const _ReadinessRingTile({
    required this.title,
    required this.percent,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final double percent;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariantSoft),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 4.5,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Center(
                  child: Text(
                    '${(percent * 100).round()}%',
                    style: AppTheme.monoAmount(fontSize: 11, color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
      onTap: onTap,
    );
  }
}
