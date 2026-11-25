import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock_trip_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';

/// Màn hình Thành viên & Hồ sơ — cập nhật từ Stitch (th_nh_vi_n_h_s):
/// Đã bỏ mục Số khẩn cấp SOS, đồng bộ tên 4 thành viên Nhóm 8 và thêm trạng thái Quỹ nhóm MoMo.
class MembersProfileScreen extends StatelessWidget {
  const MembersProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text('Thành viên (${MockTripData.members.length})'),
        actions: [
          TextButton(
            onPressed: () => context.push('/trips/create'),
            child: const Text(
              'Mời',
              style: TextStyle(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionHeader(title: 'Danh sách thành viên'),
          AppInsetCard(
            child: Column(
              children: List.generate(MockTripData.members.length, (index) {
                final m = MockTripData.members[index];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: m.isHost
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainerHigh,
                        child: Text(
                          m.initials,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: m.isHost
                                ? AppColors.onPrimaryContainer
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        '${m.role} • Chuỗi ${m.streakWeeks} tuần 🔥',
                        style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      trailing: m.isOnline
                          ? const AppStatusBadge(label: 'Trực tuyến', tone: AppBadgeTone.mint)
                          : const Icon(Icons.chevron_right, color: AppColors.outline),
                    ),
                    if (index < MockTripData.members.length - 1) const Divider(indent: 72),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          const AppSectionHeader(title: 'Liên kết Quỹ & Quyết toán'),
          AppInsetCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text('Quỹ nhóm MoMo'),
                  subtitle: const Text(MockTripData.momoFundName),
                  trailing: const AppStatusBadge(
                    label: 'Đã liên kết',
                    tone: AppBadgeTone.momo,
                  ),
                  onTap: () => context.go('/trip/momo'),
                ),
                const Divider(indent: 16),
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Text('Tài khoản quyết toán cuối chuyến'),
                  trailing: Text(
                    'MB Bank • 0987654321',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
