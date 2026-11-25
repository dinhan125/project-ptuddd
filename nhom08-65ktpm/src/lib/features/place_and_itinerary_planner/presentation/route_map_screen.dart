import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_status_badge.dart';

/// Giao diện Bản đồ Lộ trình & Khám phá Địa điểm (Module 3):
/// Đã bỏ phần SOS/Điểm tập hợp cũ, thay bằng tìm kiếm điểm đề xuất, lộ trình Polyline và GPS/Camera Check-in.
class RouteMapView extends StatefulWidget {
  const RouteMapView({super.key});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  int _selectedCat = 0;
  final _cats = const ['Tất cả', 'Tham quan', 'Ăn uống', 'Lưu trú'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thanh tìm kiếm địa điểm đề xuất (Places API)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariantSoft),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
                hintText: 'Khám phá quán ăn, điểm tham quan tại Đà Lạt...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Khung bản đồ lộ trình Polyline mẫu (TODO: Thay bằng GoogleMap của google_maps_flutter)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppInsetCard(
              borderRadius: 16,
              backgroundColor: const Color(0xFFE9F2FA),
              child: Stack(
                children: [
                  // Nền bản đồ & đường Polyline mô phỏng
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.route,
                          size: 64,
                          color: const Color(0x73007AFF),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bản đồ Lộ trình Ngày 1 (Polyline)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tổng quãng đường: 18,4 km • ~42 phút di chuyển',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'TODO(Module 3): Nhúng GoogleMap + Places/Overpass API tại đây',
                          style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: AppStatusBadge(
                      label: '4 điểm trong ngày 1',
                      tone: AppBadgeTone.primary,
                      icon: Icons.pin_drop,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom card điểm đến hiện tại + GPS/Camera Check-in
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppInsetCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đồi Chè Cầu Đất',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    AppStatusBadge(label: 'Đang diễn ra', tone: AppBadgeTone.mint),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cách vị trí hiện tại 120m • Dự kiến: Miễn phí',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'GPS & Camera Check-in điểm đến',
                  icon: Icons.camera_alt_outlined,
                  onPressed: () {
                    // TODO(Module 3): Kiểm tra tọa độ Geolocator & chụp ảnh Check-in
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('TODO(Module 3): Xác thực tọa độ GPS & chụp ảnh Check-in'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
