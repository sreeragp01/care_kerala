import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Official CareLink Kerala Brand Identity Components
/// Modeled directly after the official branding design system:
/// - Palette: Trust Navy (#0A4D8C), Care Teal (#00BFA6), Health Green (#34D399), Peace Blue (#E3F2FD)
/// - Emblem: Kerala Palm Tree, House Roof, Heart, Caregiver & Patient in Wheelchair, Embracing Hands
/// - Wordmark: "CareLink" with ECG Heartbeat Pulse & Heart, "— K E R A L A —", "Care • Connect • Compassion"

class CareLinkBrandLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;
  final bool isDark;
  final bool useAssetImage;

  const CareLinkBrandLogo({
    super.key,
    this.size = 80,
    this.showWordmark = true,
    this.showTagline = false,
    this.isDark = false,
    this.useAssetImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Icon Emblem
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.brandSplashNavy, AppColors.brandSplashDark]
                  : [AppColors.brandPeaceBlue, Colors.white],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandTeal.withValues(alpha: isDark ? 0.25 : 0.18),
                blurRadius: size * 0.18,
                offset: Offset(0, size * 0.06),
              ),
            ],
            border: Border.all(
              color: isDark ? AppColors.brandTeal.withValues(alpha: 0.3) : AppColors.brandTeal.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.24),
            child: useAssetImage
                ? Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildVectorEmblem(size),
                  )
                : _buildVectorEmblem(size),
          ),
        ),

        if (showWordmark) ...[
          SizedBox(height: size * 0.12),
          CareLinkWordmark(
            fontSize: size * 0.28,
            isDark: isDark,
            showSubtitle: true,
            showTagline: showTagline,
          ),
        ],
      ],
    );
  }

  Widget _buildVectorEmblem(double s) {
    return Center(
      child: CustomPaint(
        size: Size(s * 0.75, s * 0.75),
        painter: _CareLinkEmblemPainter(isDark: isDark),
      ),
    );
  }
}

/// Official CareLink Wordmark & ECG Heartbeat Line
class CareLinkWordmark extends StatelessWidget {
  final double fontSize;
  final bool isDark;
  final bool showSubtitle;
  final bool showTagline;

  const CareLinkWordmark({
    super.key,
    this.fontSize = 24,
    this.isDark = false,
    this.showSubtitle = true,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final navyColor = isDark ? Colors.white : AppColors.brandNavy;
    final tealColor = AppColors.brandTeal;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "CareLink ♡ / ﮩـﮩـ"
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "Care"
            Text(
              'Care',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: navyColor,
                letterSpacing: -0.5,
              ),
            ),
            // "Link"
            Text(
              'Link',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: tealColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),

            // ECG Heartbeat + Heart Graphic
            CustomPaint(
              size: Size(fontSize * 1.8, fontSize * 0.9),
              painter: _EcgHeartPainter(color: tealColor),
            ),
          ],
        ),

        if (showSubtitle) ...[
          const SizedBox(height: 2),
          // "— K E R A L A —"
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: fontSize * 0.8, height: 1.5, color: navyColor.withValues(alpha: 0.6)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  'K E R A L A',
                  style: TextStyle(
                    fontSize: fontSize * 0.38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                    color: navyColor,
                  ),
                ),
              ),
              Container(width: fontSize * 0.8, height: 1.5, color: navyColor.withValues(alpha: 0.6)),
            ],
          ),
        ],

        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Care  •  Connect  •  Compassion',
            style: TextStyle(
              fontSize: fontSize * 0.34,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact Brand Header for AppBars across all screens
class CareLinkHeaderBar extends StatelessWidget {
  final bool isDark;

  const CareLinkHeaderBar({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini Emblem Icon
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [AppColors.brandNavy, AppColors.brandTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Brand Name + Pulse Line
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Care',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.brandNavy,
                  ),
                ),
                const Text(
                  'Link',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: 3),
                CustomPaint(
                  size: const Size(24, 12),
                  painter: _EcgHeartPainter(color: AppColors.brandTeal, strokeWidth: 1.5),
                ),
              ],
            ),
            const Text(
              'K E R A L A',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: AppColors.brandTeal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom Vector ECG Pulse + Heart Icon Painter
class _EcgHeartPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _EcgHeartPainter({required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final h = size.height;
    final w = size.width;

    // ECG pulse line
    path.moveTo(0, h * 0.55);
    path.lineTo(w * 0.20, h * 0.55);
    path.lineTo(w * 0.30, h * 0.15); // Spike up
    path.lineTo(w * 0.42, h * 0.90); // Spike down
    path.lineTo(w * 0.52, h * 0.35); // Small spike
    path.lineTo(w * 0.60, h * 0.55); // Return to baseline

    canvas.drawPath(path, paint);

    // Heart Outline on the right
    final heartPath = Path();
    final centerX = w * 0.80;
    final centerY = h * 0.55;
    final r = h * 0.38;

    heartPath.moveTo(centerX, centerY + r * 0.8);
    heartPath.cubicTo(
      centerX - r * 1.2, centerY - r * 0.2,
      centerX - r * 1.0, centerY - r * 1.0,
      centerX, centerY - r * 0.5,
    );
    heartPath.cubicTo(
      centerX + r * 1.0, centerY - r * 1.0,
      centerX + r * 1.2, centerY - r * 0.2,
      centerX, centerY + r * 0.8,
    );

    canvas.drawPath(heartPath, paint);
  }

  @override
  bool shouldRepaint(covariant _EcgHeartPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Vector Painter fallback for CareLink Kerala Emblem
class _CareLinkEmblemPainter extends CustomPainter {
  final bool isDark;

  _CareLinkEmblemPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // House roof paint
    final roofPaint = Paint()
      ..color = AppColors.brandNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roofPath = Path();
    roofPath.moveTo(w * 0.20, h * 0.45);
    roofPath.lineTo(w * 0.65, h * 0.12);
    roofPath.lineTo(w * 0.88, h * 0.35);
    canvas.drawPath(roofPath, roofPaint);

    // Embracing Care Hand Paint
    final handPaint = Paint()
      ..color = AppColors.brandTeal
      ..style = PaintingStyle.fill;

    final handPath = Path();
    handPath.moveTo(w * 0.15, h * 0.70);
    handPath.cubicTo(w * 0.25, h * 0.95, w * 0.65, h * 0.98, w * 0.88, h * 0.65);
    handPath.cubicTo(w * 0.75, h * 0.75, w * 0.50, h * 0.85, w * 0.30, h * 0.72);
    handPath.close();
    canvas.drawPath(handPath, handPaint);

    // Central Heart
    final heartPaint = Paint()
      ..color = AppColors.brandHealthGreen
      ..style = PaintingStyle.fill;

    final heartPath = Path();
    final cx = w * 0.52;
    final cy = h * 0.50;
    final hr = w * 0.22;

    heartPath.moveTo(cx, cy + hr);
    heartPath.cubicTo(cx - hr * 1.2, cy - hr * 0.1, cx - hr * 1.1, cy - hr * 1.0, cx, cy - hr * 0.4);
    heartPath.cubicTo(cx + hr * 1.1, cy - hr * 1.0, cx + hr * 1.2, cy - hr * 0.1, cx, cy + hr);
    canvas.drawPath(heartPath, heartPaint);

    // Palm fronds on the left
    final palmPaint = Paint()
      ..color = AppColors.brandHealthGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.22, h * 0.60), Offset(w * 0.22, h * 0.25), palmPaint);
    canvas.drawLine(Offset(w * 0.22, h * 0.25), Offset(w * 0.10, h * 0.18), palmPaint);
    canvas.drawLine(Offset(w * 0.22, h * 0.25), Offset(w * 0.32, h * 0.20), palmPaint);
    canvas.drawLine(Offset(w * 0.22, h * 0.25), Offset(w * 0.12, h * 0.32), palmPaint);
  }

  @override
  bool shouldRepaint(covariant _CareLinkEmblemPainter oldDelegate) => false;
}
