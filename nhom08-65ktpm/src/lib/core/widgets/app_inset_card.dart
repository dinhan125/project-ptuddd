import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Card trắng viền nhạt chuẩn iOS Inset Grouped giống thiết kế Stitch.
class AppInsetCard extends StatelessWidget {
  const AppInsetCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.backgroundColor = AppColors.surfaceContainer,
    this.borderColor = AppColors.outlineVariantSoft,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}
