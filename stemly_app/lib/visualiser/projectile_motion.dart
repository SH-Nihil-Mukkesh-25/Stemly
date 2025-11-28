// lib/visualiser/projectile_motion.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ProjectileMotionGame extends FlameGame {
  final double U;
  final double theta;
  final double g;
  
  ProjectileMotionGame({
    required this.U,
    required this.theta,
    required this.g,
  });
  
  @override
  Color backgroundColor() => const Color(0xFFF5F5F5);
  
  @override
  Future<void> onLoad() async {
    await add(ProjectileVisualizer(U: U, theta: theta, g: g));
  }
}

class ProjectileVisualizer extends Component with HasGameRef {
  final double U;
  final double theta;
  final double g;
  
  double elapsedTime = 0.0;
  double totalFlightTime = 0.0;
  final List<Vector2> trajectoryPoints = [];
  
  // Visual paints
  final Paint ballPaint = Paint();
  final Paint gridPaint = Paint();
  final Paint axisPaint = Paint();
  final Paint pathPaint = Paint();
  final Paint textPaint = Paint();
  final Paint groundPaint = Paint();
  
  ProjectileVisualizer({
    required this.U,
    required this.theta,
    required this.g,
  });
  
  @override
  Future<void> onLoad() async {
    final thetaRad = theta * pi / 180;
    totalFlightTime = (2 * U * sin(thetaRad)) / g;
    
    // Initialize paints
    ballPaint
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;
    
    gridPaint
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    
    axisPaint
      ..color = Colors.black87
      ..strokeWidth = 2;
    
    pathPaint
      ..color = const Color(0xFFFF6B35).withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    groundPaint
      ..color = const Color(0xFF8BC34A);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    elapsedTime += dt;
    
    if (elapsedTime > totalFlightTime + 1.0) {
      elapsedTime = 0.0;
      trajectoryPoints.clear();
    }
    
    // Add trajectory point
    if (elapsedTime <= totalFlightTime) {
      final pos = _calculatePosition(elapsedTime);
      if (pos.y >= 0) {
        trajectoryPoints.add(pos);
      }
    }
  }
  
  Vector2 _calculatePosition(double t) {
    final thetaRad = theta * pi / 180;
    final x = U * cos(thetaRad) * t;
    final y = U * sin(thetaRad) * t - 0.5 * g * t * t;
    return Vector2(x, max(0.0, y));
  }
  
  @override
  void render(Canvas canvas) {
    final size = gameRef.size;
    
    // Calculate range and max height for scaling
    final thetaRad = theta * pi / 180;
    final range = (U * U * sin(2 * thetaRad)) / g;
    final maxHeight = (U * U * sin(thetaRad) * sin(thetaRad)) / (2 * g);
    
    // Calculate scale to fit screen with margins
    final marginX = size.x * 0.15;
    final marginY = size.y * 0.2;
    final scaleX = (size.x - 2 * marginX) / range;
    final scaleY = (size.y - 2 * marginY) / maxHeight;
    final scale = min(scaleX, scaleY);
    
    // Origin at bottom-left with margin
    final originX = marginX;
    final originY = size.y - marginY;
    
    canvas.save();
    
    // Draw grid
    _drawGrid(canvas, size, originX, originY, scale, range, maxHeight);
    
    // Draw ground
    _drawGround(canvas, size, originY);
    
    // Draw axes
    _drawAxes(canvas, originX, originY, scale, range, maxHeight);
    
    // Draw trajectory path
    if (trajectoryPoints.isNotEmpty) {
      _drawTrajectory(canvas, originX, originY, scale);
    }
    
    // Draw ball
    if (elapsedTime <= totalFlightTime) {
      final pos = _calculatePosition(elapsedTime);
      _drawBall(canvas, originX, originY, scale, pos);
      
      // Draw velocity vector
      _drawVelocityVector(canvas, originX, originY, scale, pos);
    }
    
    canvas.restore();
    
    // Draw info panel
    _drawInfoPanel(canvas, size);
  }
  
  void _drawGrid(Canvas canvas, Vector2 size, double originX, double originY, double scale, double range, double maxHeight) {
    final gridSize = 5.0; // meters
    
    // Vertical lines
    for (double x = 0; x <= range; x += gridSize) {
      final screenX = originX + x * scale;
      canvas.drawLine(
        Offset(screenX, originY),
        Offset(screenX, originY - maxHeight * scale * 1.2),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y <= maxHeight * 1.2; y += gridSize) {
      final screenY = originY - y * scale;
      canvas.drawLine(
        Offset(originX, screenY),
        Offset(originX + range * scale, screenY),
        gridPaint,
      );
    }
  }
  
  void _drawGround(Canvas canvas, Vector2 size, double originY) {
    canvas.drawRect(
      Rect.fromLTWH(0, originY, size.x, size.y - originY),
      groundPaint,
    );
  }
  
  void _drawAxes(Canvas canvas, double originX, double originY, double scale, double range, double maxHeight) {
    // X-axis
    canvas.drawLine(
      Offset(originX, originY),
      Offset(originX + range * scale, originY),
      axisPaint,
    );
    
    // Y-axis
    canvas.drawLine(
      Offset(originX, originY),
      Offset(originX, originY - maxHeight * scale * 1.2),
      axisPaint,
    );
    
    // Axis labels
    _drawText(canvas, 'Distance (m)', originX + range * scale / 2, originY + 30, size: 14, bold: true);
    
    canvas.save();
    canvas.translate(originX - 40, originY - maxHeight * scale * 0.6);
    canvas.rotate(-pi / 2);
    _drawText(canvas, 'Height (m)', 0, 0, size: 14, bold: true);
    canvas.restore();
  }
  
  void _drawTrajectory(Canvas canvas, double originX, double originY, double scale) {
    final path = Path();
    
    for (int i = 0; i < trajectoryPoints.length; i++) {
      final pt = trajectoryPoints[i];
      final x = originX + pt.x * scale;
      final y = originY - pt.y * scale;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, pathPaint);
  }
  
  void _drawBall(Canvas canvas, double originX, double originY, double scale, Vector2 pos) {
    final x = originX + pos.x * scale;
    final y = originY - pos.y * scale;
    
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(x, originY), 12, shadowPaint);
    
    // Ball gradient
    final gradient = RadialGradient(
      colors: [
        const Color(0xFFFF8C5A),
        const Color(0xFFFF6B35),
      ],
    );
    
    final ballPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset(x, y), radius: 15));
    
    canvas.drawCircle(Offset(x, y), 15, ballPaint);
    
    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(Offset(x - 4, y - 4), 5, highlightPaint);
  }
  
  void _drawVelocityVector(Canvas canvas, double originX, double originY, double scale, Vector2 pos) {
    final thetaRad = theta * pi / 180;
    final vx = U * cos(thetaRad);
    final vy = U * sin(thetaRad) - g * elapsedTime;
    
    final x = originX + pos.x * scale;
    final y = originY - pos.y * scale;
    
    final vectorScale = 0.15 * scale;
    final endX = x + vx * vectorScale;
    final endY = y - vy * vectorScale;
    
    final vectorPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(x, y), Offset(endX, endY), vectorPaint);
    
    // Arrow head
    final angle = atan2(endY - y, endX - x);
    final arrowPath = Path()
      ..moveTo(endX, endY)
      ..lineTo(endX - 10 * cos(angle - pi / 6), endY - 10 * sin(angle - pi / 6))
      ..lineTo(endX - 10 * cos(angle + pi / 6), endY - 10 * sin(angle + pi / 6))
      ..close();
    
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFF2196F3));
    
    // Velocity label
    final v = sqrt(vx * vx + vy * vy);
    _drawText(canvas, 'v = ${v.toStringAsFixed(1)} m/s', endX + 10, endY - 10, 
        size: 12, color: const Color(0xFF2196F3), bold: true);
  }
  
  void _drawInfoPanel(Canvas canvas, Vector2 size) {
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, 200, 140),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(
      panelRect,
      Paint()..color = Colors.white.withOpacity(0.95),
    );
    
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    _drawText(canvas, 'Projectile Motion', 20, 30, size: 16, bold: true, color: const Color(0xFF1976D2));
    _drawText(canvas, 'Initial Velocity: ${U.toStringAsFixed(1)} m/s', 20, 55, size: 13);
    _drawText(canvas, 'Launch Angle: ${theta.toStringAsFixed(0)}°', 20, 75, size: 13);
    _drawText(canvas, 'Gravity: ${g.toStringAsFixed(2)} m/s²', 20, 95, size: 13);
    
    final thetaRad = theta * pi / 180;
    final range = (U * U * sin(2 * thetaRad)) / g;
    final maxHeight = (U * U * sin(thetaRad) * sin(thetaRad)) / (2 * g);
    
    _drawText(canvas, 'Range: ${range.toStringAsFixed(1)} m', 20, 115, size: 13, color: const Color(0xFFFF6B35), bold: true);
    _drawText(canvas, 'Max Height: ${maxHeight.toStringAsFixed(1)} m', 20, 135, size: 13, color: const Color(0xFFFF6B35), bold: true);
  }
  
  void _drawText(Canvas canvas, String text, double x, double y, 
      {double size = 12, bool bold = false, Color color = Colors.black87}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
  
  void updateParams({double? U, double? theta, double? g}) {
    print('updateParams called - values are immutable');
  }
}
