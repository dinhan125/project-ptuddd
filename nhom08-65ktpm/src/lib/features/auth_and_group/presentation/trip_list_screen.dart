import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';

/// Màn hình Danh sách chuyến đi — nâng cấp từ Stitch (danh_s_ch_chuy_n_i)
/// bổ sung Countdown đếm ngược và 2 thanh tiến độ (Quỹ MoMo & Checklist chuẩn bị).
class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  int _selectedFilter = 0;
  final _filters = const ['Tất cả', 'Đang chuẩn bị', 'Sắp tới', 'Đã kết thúc'];

  @override
  Widget build(BuildContext context) {
    final fundPercent =
        (MockTripData.currentSavedFund / MockTripData.totalTargetFund).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 130,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primaryContainer,
                child: const Text(
                  'ĐA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đình An',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        title: const Text('Chuyến đi'),
        actions: [
          IconButton(
            tooltip: 'Quét QR tham gia nhóm',
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: () {
              // TODO(Module 1): Mở mobile_scanner quét mã QR mời nhóm
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('TODO(Module 1): Mở trình quét QR tham gia chuyến đi')),
              );
            },
          ),
          IconButton(
            tooltip: 'Tạo chuyến đi mới',
            icon: const Icon(Icons.add, color: AppColors.primary, size: 26),
            onPressed: () => context.push('/trips/create'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ô tìm kiếm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
                hintText: 'Tìm chuyến đi, địa điểm...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = _selectedFilter == index;
                return ChoiceChip(
                  label: Text(_filters[index]),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedFilter = index),
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.surfaceContainer,
                  side: BorderSide(
                    color: active ? Colors.transparent : AppColors.outlineVariantSoft,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Chuyến đi đang chuẩn bị (có Countdown + 2 tiến độ)
          const AppSectionHeader(title: 'Đang chuẩn bị'),
          GestureDetector(
            onTap: () => context.go('/trip/checklist'),
            child: AppInsetCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          MockTripData.tripName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const AppStatusBadge(
                        label: 'Còn ${MockTripData.daysUntilTrip} ngày',
                        tone: AppBadgeTone.amber,
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${MockTripData.tripDateRange} • 4 thành viên',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),

                  // 2 thanh tiến độ song song: Quỹ MoMo & Checklist
                  Row(
                    children: [
                      Expanded(
                        child: _MiniProgressBox(
                          label: 'Quỹ MoMo',
                          valueText: '${(fundPercent * 100).round()}%',
                          progress: fundPercent,
                          color: AppColors.momo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: _MiniProgressBox(
                          label: 'Checklist',
                          valueText: '67%',
                          progress: 0.67,
                          color: AppColors.mint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppStatusBadge(
                        label: 'Đã liên kết Quỹ MoMo',
                        tone: AppBadgeTone.momo,
                        icon: Icons.link,
                      ),
                      Text(
                        MockTripData.formatVnd(MockTripData.totalTargetFund),
                        style: AppTheme.monoAmount(fontSize: 16, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chuyến đi sắp tới
          const AppSectionHeader(title: 'Sắp tới'),
          AppInsetCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.beach_access, color: AppColors.primary),
              ),
              title: const Text(
                'Phú Quốc Cuối Năm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('28/12 – 31/12/2026 • 4 người • Còn 42 ngày'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
              onTap: () => context.go('/trip/checklist'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgressBox extends StatelessWidget {
  const _MiniProgressBox({
    required this.label,
    required this.valueText,
    required this.progress,
    required this.color,
  });

  final String label;
  final String valueText;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariantSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              Text(valueText, style: AppTheme.monoAmount(fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
