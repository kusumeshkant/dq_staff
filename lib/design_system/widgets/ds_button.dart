import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_spacing.dart';

/// Primary action button for DQ Staff.
///
/// Usage:
///   DsButton(label: 'Mark Ready', onPressed: _markReady)
///   DsButton.secondary(label: 'Cancel', onPressed: _cancel)
class DsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final bool isLoading;
  final double? width;
  final _ButtonVariant _variant;

  const DsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.width,
  }) : _variant = _ButtonVariant.primary;

  const DsButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.width,
  }) : _variant = _ButtonVariant.secondary;

  const DsButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.width,
  }) : _variant = _ButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final bg = switch (_variant) {
      _ButtonVariant.primary => AppColors.primary,
      _ButtonVariant.secondary => AppColors.glassWhite15,
      _ButtonVariant.destructive => AppColors.error,
    };
    final fgColor = switch (_variant) {
      _ButtonVariant.primary => Colors.white,
      _ButtonVariant.secondary => AppColors.textPrimary,
      _ButtonVariant.destructive => Colors.white,
    };
    final borderColor = switch (_variant) {
      _ButtonVariant.primary => AppColors.primaryDark,
      _ButtonVariant.secondary => AppColors.glassWhite20,
      _ButtonVariant.destructive => AppColors.errorBorder,
    };

    return SizedBox(
      width: width,
      height: AppSizes.buttonMd,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leadingIcon != null) ...[
                          Icon(leadingIcon,
                              size: AppSizes.iconSm, color: fgColor),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(label,
                            style:
                                AppTypography.button.copyWith(color: fgColor)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ButtonVariant { primary, secondary, destructive }
