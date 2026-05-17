import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_shadows.dart';

/// Design-system glass card — standard surface for DQ Staff.
class DsGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? borderRadius;
  final List<BoxShadow>? shadows;

  const DsGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.xl;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows ?? AppShadows.cardSubtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: AppBlur.medium, sigmaY: AppBlur.medium),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.glassWhite15,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.glassWhite20),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
