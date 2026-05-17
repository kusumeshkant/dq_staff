import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_spacing.dart';
import 'ds_button.dart';

/// Empty state widgets for DQ Staff.
class DsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const DsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.glassWhite10,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassWhite20),
              ),
              child: Icon(icon, size: AppSizes.iconXl, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: AppTypography.titleSmall, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!, style: AppTypography.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget.
class DsErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const DsErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorSubtle,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: const Icon(Icons.error_outline,
                  size: AppSizes.iconXl, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Something went wrong', style: AppTypography.titleSmall),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message!, style: AppTypography.bodySmall, textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              DsButton(label: 'Try Again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
