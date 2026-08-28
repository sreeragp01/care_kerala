import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/map_marker_model.dart';

class InteractiveMapCanvas extends StatefulWidget {
  final List<MapMarkerModel> markers;
  final MapMarkerModel? selectedMarker;
  final MapMarkerModel? activeNavigationTarget;
  final bool isNavigating;
  final double navigationProgress; // 0.0 to 1.0
  final Function(MapMarkerModel) onMarkerSelected;
  final VoidCallback? onMapTapped;
  final bool isSatelliteMode;
  final bool isNightMode;

  const InteractiveMapCanvas({
    super.key,
    required this.markers,
    this.selectedMarker,
    this.activeNavigationTarget,
    this.isNavigating = false,
    this.navigationProgress = 0.0,
    required this.onMarkerSelected,
    this.onMapTapped,
    this.isSatelliteMode = false,
    this.isNightMode = false,
  });

  @override
  State<InteractiveMapCanvas> createState() => _InteractiveMapCanvasState();
}

class _InteractiveMapCanvasState extends State<InteractiveMapCanvas>
    with TickerProviderStateMixin {
  late final TransformationController _transformController;
  late final AnimationController _pulseController;
  AnimationController? _cameraFlightController;
  Animation<Matrix4>? _cameraMatrixAnimation;

  static const double canvasWidth = 1400.0;
  static const double canvasHeight = 1100.0;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Initial center on nurse base
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedMarker != null) {
        animateToMarker(widget.selectedMarker!, zoom: 1.2);
      } else {
        animateToCoordinates(11.2588, 75.7804, zoom: 1.0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMarker != null &&
        widget.selectedMarker?.id != oldWidget.selectedMarker?.id &&
        !widget.isNavigating) {
      animateToMarker(widget.selectedMarker!, zoom: 1.3);
    }
  }

  @override
  void dispose() {
    _cameraFlightController?.dispose();
    _transformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void animateToMarker(MapMarkerModel marker, {double zoom = 1.3}) {
    animateToCoordinates(marker.latitude, marker.longitude, zoom: zoom);
  }

  void animateToCoordinates(double lat, double lng, {double zoom = 1.3}) {
    final targetPos = _latLngToCanvas(lat, lng, canvasWidth, canvasHeight);
    final size = MediaQuery.of(context).size;

    final targetTranslationX = -targetPos.dx * zoom + size.width / 2;
    final targetTranslationY = -targetPos.dy * zoom + size.height / 2.4;

    final targetMatrix = Matrix4.identity()
      ..translateByVector3(Matrix4.translationValues(targetTranslationX, targetTranslationY, 0.0).getTranslation())
      ..multiply(Matrix4.diagonal3Values(zoom, zoom, 1.0));

    _animateCameraToMatrix(targetMatrix);
  }

  void _animateCameraToMatrix(Matrix4 targetMatrix) {
    _cameraFlightController?.dispose();
    _cameraFlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final startMatrix = _transformController.value.clone();
    _cameraMatrixAnimation = Matrix4Tween(
      begin: startMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _cameraFlightController!,
      curve: Curves.easeOutCubic,
    ));

    _cameraMatrixAnimation!.addListener(() {
      _transformController.value = _cameraMatrixAnimation!.value;
    });

    _cameraFlightController!.forward();
  }

  void zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(1.3, 1.3, 1.0));
    _animateCameraToMatrix(matrix);
  }

  void zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(0.75, 0.75, 1.0));
    _animateCameraToMatrix(matrix);
  }

  void resetView() {
    animateToCoordinates(11.2588, 75.7804, zoom: 1.1); // Kozhikode PHC Hub
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.4,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(500),
          child: GestureDetector(
            onTap: widget.onMapTapped,
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  // Layer 1: Static Base Terrain & Highways (GPU Cached with RepaintBoundary)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(canvasWidth, canvasHeight),
                      painter: _StaticKeralaGisPainter(
                        isSatellite: widget.isSatelliteMode,
                        isNight: widget.isNightMode,
                      ),
                    ),
                  ),

                  // Layer 2: Dynamic Animated GPS Polyline, Radar Pulsing & Vehicle Tracker
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(canvasWidth, canvasHeight),
                        painter: _DynamicGisRoutePainter(
                          pulseVal: _pulseController.value,
                          navigationProgress: widget.navigationProgress,
                          isNavigating: widget.isNavigating,
                          activeTarget: widget.activeNavigationTarget,
                        ),
                      );
                    },
                  ),

                  // Layer 3: Interactive Visual Pin Markers
                  ...widget.markers.map((marker) {
                    final pos = _latLngToCanvas(
                      marker.latitude,
                      marker.longitude,
                      canvasWidth,
                      canvasHeight,
                    );
                    final isSelected = widget.selectedMarker?.id == marker.id;
                    final isTarget = widget.activeNavigationTarget?.id == marker.id;

                    return Positioned(
                      left: pos.dx - 40,
                      top: pos.dy - 52,
                      child: GestureDetector(
                        onTap: () {
                          widget.onMarkerSelected(marker);
                          animateToMarker(marker, zoom: 1.35);
                        },
                        child: _buildMarkerWidget(marker, isSelected, isTarget),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // Floating Compass & Quick Control HUD
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              _buildMapHudButton(Icons.add_rounded, zoomIn, tooltip: 'Zoom In'),
              const SizedBox(height: 8),
              _buildMapHudButton(Icons.remove_rounded, zoomOut, tooltip: 'Zoom Out'),
              const SizedBox(height: 8),
              _buildMapHudButton(Icons.navigation_rounded, resetView, tooltip: 'Center on Kozhikode Hub'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapHudButton(IconData icon, VoidCallback onTap, {required String tooltip}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isNightMode;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? const Color(0xFF1E2620) : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerWidget(MapMarkerModel marker, bool isSelected, bool isTarget) {
    final isDark = widget.isNightMode;

    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? marker.color
                  : (isDark ? const Color(0xFF232A25) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: marker.color, width: isSelected ? 2.2 : 1.5),
              boxShadow: [
                BoxShadow(
                  color: marker.color.withValues(alpha: isSelected ? 0.5 : 0.25),
                  blurRadius: isSelected ? 10 : 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: isSelected ? Colors.white : marker.color,
                  child: Icon(
                    marker.icon,
                    size: 10,
                    color: isSelected ? marker.color : Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  marker.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF1E2620)),
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(12, 8),
            painter: _TrianglePointerPainter(color: marker.color),
          ),
        ],
      ),
    );
  }

  static Offset _latLngToCanvas(double lat, double lng, double w, double h) {
    const minLat = 11.2300;
    const maxLat = 11.2900;
    const minLng = 75.7500;
    const maxLng = 75.8200;

    final normalizedX = ((lng - minLng) / (maxLng - minLng)).clamp(0.05, 0.95);
    final normalizedY = (1.0 - ((lat - minLat) / (maxLat - minLat))).clamp(0.05, 0.95);

    return Offset(normalizedX * w, normalizedY * h);
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;

  _TrianglePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePointerPainter oldDelegate) => oldDelegate.color != color;
}

/// Static Layer: Cached Kerala Terrain, Water Bodies & Road Networks
class _StaticKeralaGisPainter extends CustomPainter {
  final bool isSatellite;
  final bool isNight;

  _StaticKeralaGisPainter({required this.isSatellite, required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Base Landmass Color
    final bgPaint = Paint();
    if (isSatellite) {
      bgPaint.color = const Color(0xFF1B2C1E); // Tropical Green
    } else if (isNight) {
      bgPaint.color = const Color(0xFF121B16); // Dark Night
    } else {
      bgPaint.color = const Color(0xFFF4F8F4); // Clean Mint Surface
    }
    canvas.drawRect(rect, bgPaint);

    // 2. Arabian Sea Coastline (West Edge)
    final seaPaint = Paint()
      ..color = isNight
          ? const Color(0xFF09141E)
          : (isSatellite ? const Color(0xFF0E2238) : const Color(0xFFD0E6F8));
    final seaPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.14, 0)
      ..cubicTo(
        size.width * 0.17, size.height * 0.35,
        size.width * 0.10, size.height * 0.65,
        size.width * 0.16, size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(seaPath, seaPaint);

    // 3. Chaliyar River Backwater Channel
    final riverPaint = Paint()
      ..color = isNight ? const Color(0xFF0D1E2A) : const Color(0xFFB8DEFD)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(size.width, size.height * 0.72)
      ..cubicTo(
        size.width * 0.65, size.height * 0.75,
        size.width * 0.35, size.height * 0.68,
        size.width * 0.12, size.height * 0.70,
      );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Urban Village Blocks
    final gridPaint = Paint()
      ..color = (isNight ? Colors.white : Colors.black).withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 65) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 65) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 5. Kerala Highway & Link Networks
    final roadCasingPaint = Paint()
      ..color = isNight ? const Color(0xFF384C3F) : const Color(0xFFD2DDD2)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final majorRoadPaint = Paint()
      ..color = isNight
          ? const Color(0xFF26362B)
          : (isSatellite ? const Color(0xFF425646) : const Color(0xFFFFFFFF))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Mavoor Road (SH 34)
    final mavoorRoad = Path()
      ..moveTo(size.width * 0.18, size.height * 0.20)
      ..cubicTo(
        size.width * 0.40, size.height * 0.38,
        size.width * 0.62, size.height * 0.46,
        size.width * 0.92, size.height * 0.54,
      );
    canvas.drawPath(mavoorRoad, roadCasingPaint);
    canvas.drawPath(mavoorRoad, majorRoadPaint);

    // Wayanad Road Trunk (NH 766)
    final wayanadRoad = Path()
      ..moveTo(size.width * 0.32, size.height * 0.92)
      ..cubicTo(
        size.width * 0.46, size.height * 0.60,
        size.width * 0.56, size.height * 0.30,
        size.width * 0.72, size.height * 0.08,
      );
    canvas.drawPath(wayanadRoad, roadCasingPaint);
    canvas.drawPath(wayanadRoad, majorRoadPaint);

    // Beach Promenade Road
    final beachRoad = Path()
      ..moveTo(size.width * 0.15, 0)
      ..cubicTo(
        size.width * 0.18, size.height * 0.35,
        size.width * 0.12, size.height * 0.65,
        size.width * 0.17, size.height,
      );
    canvas.drawPath(beachRoad, roadCasingPaint);
    canvas.drawPath(beachRoad, majorRoadPaint);
  }

  @override
  bool shouldRepaint(_StaticKeralaGisPainter oldDelegate) =>
      oldDelegate.isSatellite != isSatellite || oldDelegate.isNight != isNight;
}

/// Dynamic Layer: Animated Route Polyline, Real-Time Pulsing GPS Beacon & Live Vehicle Simulation
class _DynamicGisRoutePainter extends CustomPainter {
  final double pulseVal;
  final double navigationProgress;
  final bool isNavigating;
  final MapMarkerModel? activeTarget;

  _DynamicGisRoutePainter({
    required this.pulseVal,
    required this.navigationProgress,
    required this.isNavigating,
    this.activeTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nurseBasePos = Offset(size.width * 0.48, size.height * 0.48);

    final targetPos = activeTarget != null
        ? _InteractiveMapCanvasState._latLngToCanvas(
            activeTarget!.latitude,
            activeTarget!.longitude,
            size.width,
            size.height,
          )
        : Offset(size.width * 0.72, size.height * 0.34);

    final routePath = Path()
      ..moveTo(nurseBasePos.dx, nurseBasePos.dy)
      ..cubicTo(
        nurseBasePos.dx + (targetPos.dx - nurseBasePos.dx) * 0.3,
        nurseBasePos.dy + (targetPos.dy - nurseBasePos.dy) * 0.1,
        nurseBasePos.dx + (targetPos.dx - nurseBasePos.dx) * 0.6,
        nurseBasePos.dy + (targetPos.dy - nurseBasePos.dy) * 0.8,
        targetPos.dx,
        targetPos.dy,
      );

    // Route Outer Glow
    final routeGlowPaint = Paint()
      ..color = AppColors.primaryGreen.withValues(alpha: 0.28)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routeGlowPaint);

    // Route Core Path
    final routePaint = Paint()
      ..color = isNavigating ? const Color(0xFF00E676) : AppColors.primaryGreen
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routePaint);

    // Vehicle & GPS Position along Path
    final metrics = routePath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final currentDistance = metric.length * (isNavigating ? navigationProgress : 0.0);
      final tangent = metric.getTangentForOffset(currentDistance);

      if (tangent != null) {
        final vehiclePos = tangent.position;
        final angle = -tangent.angle;

        // Radar GPS Wave
        final ringRadius = 14.0 + (pulseVal * 20.0);
        final ringAlpha = (1.0 - pulseVal).clamp(0.0, 1.0);
        final pulsePaint = Paint()
          ..color = (isNavigating ? const Color(0xFF00E676) : AppColors.primaryGreen)
              .withValues(alpha: ringAlpha * 0.45)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(vehiclePos, ringRadius, pulsePaint);

        // Vehicle Base Pin
        final shadowPaint = Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.fill;
        canvas.drawCircle(vehiclePos + const Offset(0, 2), 15, shadowPaint);

        final vehicleBasePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(vehiclePos, 13, vehicleBasePaint);

        final vehicleCenterPaint = Paint()
          ..color = isNavigating ? const Color(0xFF00C853) : AppColors.primaryGreen
          ..style = PaintingStyle.fill;
        canvas.drawCircle(vehiclePos, 9, vehicleCenterPaint);

        // Heading Direction Arrow
        canvas.save();
        canvas.translate(vehiclePos.dx, vehiclePos.dy);
        canvas.rotate(angle + math.pi / 2);
        final arrowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final arrowPath = Path()
          ..moveTo(0, -5)
          ..lineTo(3.5, 3.5)
          ..lineTo(0, 1.5)
          ..lineTo(-3.5, 3.5)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_DynamicGisRoutePainter oldDelegate) {
    return oldDelegate.pulseVal != pulseVal ||
        oldDelegate.navigationProgress != navigationProgress ||
        oldDelegate.isNavigating != isNavigating ||
        oldDelegate.activeTarget != activeTarget;
  }
}
