import 'dart:ui';
import 'package:flutter/material.dart';
import '../src/theme/app_theme.dart';

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
