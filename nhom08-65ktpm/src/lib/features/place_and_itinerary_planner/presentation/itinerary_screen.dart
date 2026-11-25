import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_status_badge.dart';
import 'route_map_screen.dart';

/// Tab 3 — Lịch trình & Bản đồ (Module 3):
/// Chuyển từ Stitch (l_ch_tr_nh_l_t_4n3), dùng Segmented Control chuyển giữa Lịch trình & Bản đồ lộ trình.
class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  int _modeIndex = 0; // 0: Lịch trình | 1: Bản đồ lộ trình
  int _selectedDay = 0;
  final _days = const ['Ngày 1 (15/11)', 'Ngày 2 (16/11)', 'Ngày 3 (17/11)', 'Ngày 4 (18/11)'];

  @override
  Widget build(BuildContext context) {
    final dayItems =
        MockTripData.activities.where((a) => a.dayIndex == _selectedDay).toList();

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
            tooltip: 'Thêm hoạt động',
            icon: const Icon(Icons.add, color: AppColors.primary, size: 26),
            onPressed: () => context.push('/trip/itinerary/add'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppSegmentedControl(
              segments: const ['Lịch trình', 'Bản đồ lộ trình'],
              selectedIndex: _modeIndex,
              onChanged: (i) => setState(() => _modeIndex = i),
            ),
          ),
        ),
      ),
      body: _modeIndex == 1
          ? const RouteMapView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Chọn ngày
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final active = _selectedDay == index;
                      return ChoiceChip(
                        label: Text(_days[index]),
                        selected: active,
                        onSelected: (_) => setState(() => _selectedDay = index),
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
                const SizedBox(height: 14),

                // Cảnh báo trùng khung giờ (giữ nguyên điểm sáng từ Stitch)
                if (_selectedDay == 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.amberContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.onAmberContainer, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cảnh báo trùng khung giờ 14:00 – 15:30',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onAmberContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                AppSectionHeader(title: 'Lịch trình ${_days[_selectedDay]}'),
                if (dayItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Chưa có hoạt động cho ngày này. Bấm + để thêm.',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  AppInsetCard(
                    child: Column(
                      children: List.generate(dayItems.length, (idx) {
                        final act = dayItems[idx];
                        final (statusLabel, tone) = switch (act.status) {
                          'done' => ('Đã xong', AppBadgeTone.mint),
                          'ongoing' => ('Đang diễn ra', AppBadgeTone.primary),
                          'conflict' => ('Trùng giờ', AppBadgeTone.amber),
                          _ => ('Dự kiến', AppBadgeTone.neutral),
                        };
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 52,
                                    child: Text(
                                      act.timeRange.split(' ').first,
                                      style: AppTheme.monoAmount(
                                        fontSize: 14,
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          act.address,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            AppStatusBadge(label: statusLabel, tone: tone),
                                            const SizedBox(width: 8),
                                            Text(
                                              act.estimatedCost,
                                              style: AppTheme.monoAmount(
                                                fontSize: 13,
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (idx < dayItems.length - 1) const Divider(indent: 66),
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
