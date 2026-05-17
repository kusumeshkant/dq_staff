import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_spacing.dart';

/// Loading state widgets for DQ Staff.
class DsLoading extends StatelessWidget {
  final String? message;

  const DsLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: AppTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Overlay that dims content while loading.
class DsLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const DsLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x4D000000),
              child: Center(child: DsLoading()),
            ),
          ),
      ],
    );
  }
}

/// Shimmer placeholder for list items.
class DsShimmerCard extends StatelessWidget {
  final double height;

  const DsShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassWhite07,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.glassWhite10),
      ),
    );
  }
}
