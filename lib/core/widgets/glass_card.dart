import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// CareLink Kerala Frosted Glassmorphism Card Container
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? customFillColor;
  final Color? customBorderColor;
  final double blur;
  final double borderWidth;
  final bool hasGlow;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.customFillColor,
    this.customBorderColor,
    this.blur = 16.0,
    this.borderWidth = 1.0,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultFill = isDark ? const Color(0xE60A2946) : Colors.white;
    final defaultBorder = isDark ? const Color(0x3800BFA6) : AppColors.cardBorder;

    final effectiveFill = customFillColor ?? defaultFill;
    final effectiveBorder = customBorderColor ?? defaultBorder;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorder, width: borderWidth),
            boxShadow: [
              if (hasGlow)
                BoxShadow(
                  color: (glowColor ?? AppColors.brandTeal).withValues(alpha: isDark ? 0.35 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.35) : AppColors.brandNavy.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        ),
      );
    }

    if (margin != null) {
      return Container(
        margin: margin,
        child: content,
      );
    }

    return content;
  }
}

/// Brand Navy & Teal Ambient Background Scaffold Wrapper
class GlassScaffoldBackground extends StatelessWidget {
  final Widget child;
  final bool showAmbientGlow;

  const GlassScaffoldBackground({
    super.key,
    required this.child,
    this.showAmbientGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return Container(
        color: AppColors.background,
        child: child,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandSplashDark, // #051E34 Deep Brand Navy
            Color(0xFF082742), // #082742 Radiant Navy
            Color(0xFF03111E), // Obsidian Base
          ],
        ),
      ),
      child: Stack(
        children: [
          if (showAmbientGlow) ...[
            // Ambient Top-Right Cyan/Teal Bloom
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandTeal.withValues(alpha: 0.12),
                ),
              ),
            ),
            // Ambient Mid-Left Health Green Bloom
            Positioned(
              top: 300,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandHealthGreen.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Ambient Bottom-Right Peace Blue Bloom
            Positioned(
              bottom: -60,
              right: 40,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandNavy.withValues(alpha: 0.20),
                ),
              ),
            ),
          ],
          SafeArea(child: child),
        ],
      ),
    );
  }
}
