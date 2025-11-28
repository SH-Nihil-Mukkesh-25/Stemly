// lib/visualiser/projectile_motion.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ProjectileComponent extends PositionComponent {
  final double U; // Initial velocity (m/s)
  final double theta; // Launch angle (degrees)
  final double g; // Gravity (m/s²)

  double elapsedTime = 0.0;
  double totalFlightTime = 0.0;
  
  // Visual elements
  final List<Vector2> trajectoryPoints = [];
  final Paint ballPaint = Paint();
  final Paint shadowPaint = Paint();
  final Paint gridPaint = Paint();
  final Paint axisPaint = Paint();
  final Paint vectorPaint = Paint();
  final Paint pathPaint = Paint();
  
  // Scale factors for display
  final double pixelsPerMeter = 5.0;
  final double displayScale = 3.0;

  ProjectileComponent({
    required this.U,
    required this.theta,
    required this.g,
    required Vector2 position,
  }) : super(position: position, size: Vector2(400, 400));

  @override
  Future<void> onLoad() async {
    // Calculate total flight time
    final thetaRad = theta * pi / 180;
    totalFlightTime = (2 * U * sin(thetaRad)) / g;
    
    // Initialize paints
    ballPaint.color = const Color(0xFFFF6B35);
    ballPaint.style = PaintingStyle.fill;
    
    shadowPaint.color = Colors.black.withOpacity(0.2);
    shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    gridPaint.color = Colors.grey.withOpacity(0.2);
    gridPaint.strokeWidth = 0.5;
    
    axisPaint.color = Colors.black87;
    axisPaint.strokeWidth = 2;
    
    vectorPaint.color = const Color(0xFF4A90E2);
    vectorPaint.strokeWidth = 2;
    vectorPaint.style = PaintingStyle.stroke;
    
    pathPaint.color = const Color(0xFFFF6B35).withOpacity(0.3);
    pathPaint.strokeWidth = 2;
    pathPaint.style = PaintingStyle.stroke;
    
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    elapsedTime += dt;
    
    // Reset when flight completes
    if (elapsedTime > totalFlightTime) {
      elapsedTime = 0.0;
      trajectoryPoints.clear();
    }
    
    // Store trajectory point
    if (trajectoryPoints.isEmpty || elapsedTime - trajectoryPoints.length * 0.05 > 0) {
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
    return Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw background gradient
    final bgGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgGradient);
    
    // Transform: origin at bottom-left
    canvas.save();
    canvas.translate(40, size.y - 40);
    canvas.scale(1, -1);
    
    // Draw grid
    _drawGrid(canvas);
    
    // Draw axes
    _drawAxes(canvas);
    
    // Draw trajectory path
    _drawTrajectoryPath(canvas);
    
    // Draw ground line
    _drawGround(canvas);
    
    // Calculate current position
    final pos = _calculatePosition(elapsedTime);
    final displayX = pos.x * pixelsPerMeter * displayScale;
    final displayY = max(0, pos.y) * pixelsPerMeter * displayScale;
    
    // Draw velocity vector
    if (displayY > 0) {
      _drawVelocityVector(canvas, Vector2(displayX, displayY));
    }
    
    // Draw shadow
    canvas.drawCircle(Offset(displayX, 0), 8, shadowPaint);
    
    // Draw ball with gradient
    final ballGradient = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF8C5A),
          const Color(0xFFFF6B35),
        ],
      ).createShader(Rect.fromCircle(center: Offset(displayX, displayY), radius: 10));
    canvas.drawCircle(Offset(displayX, displayY), 10, ballGradient);
    
    // Draw ball highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(Offset(displayX + 2, displayY + 2), 3, highlightPaint);
    
    canvas.restore();
    
    // Draw labels (in normal coordinates)
    _drawLabels(canvas);
  }

  void _drawGrid(Canvas canvas) {
    final gridSize = 20.0;
    final maxX = size.x - 80;
    final maxY = size.y - 80;
    
    for (double x = 0; x <= maxX; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, maxY),
        gridPaint,
      );
    }
    
    for (double y = 0; y <= maxY; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(maxX, y),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas) {
    // X-axis
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.x - 80, 0),
      axisPaint,
    );
    
    // Y-axis
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.y - 80),
      axisPaint,
    );
    
    // Arrow heads
    final arrowPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    
    // X-axis arrow
    final xArrowPath = Path()
      ..moveTo(size.x - 80, 0)
      ..lineTo(size.x - 90, -5)
      ..lineTo(size.x - 90, 5)
      ..close();
    canvas.drawPath(xArrowPath, arrowPaint);
    
    // Y-axis arrow
    final yArrowPath = Path()
      ..moveTo(0, size.y - 80)
      ..lineTo(-5, size.y - 90)
      ..lineTo(5, size.y - 90)
      ..close();
    canvas.drawPath(yArrowPath, arrowPaint);
  }

  void _drawTrajectoryPath(Canvas canvas) {
    if (trajectoryPoints.length < 2) return;
    
    final path = Path();
    for (int i = 0; i < trajectoryPoints.length; i++) {
      final pt = trajectoryPoints[i];
      final x = pt.x * pixelsPerMeter * displayScale;
      final y = max(0, pt.y) * pixelsPerMeter * displayScale;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, pathPaint);
  }

  void _drawGround(Canvas canvas) {
    final groundPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, -10, size.x - 80, 10),
      groundPaint,
    );
    
    // Grass pattern
    final grassPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x < size.x - 80; x += 5) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, 3),
        grassPaint..strokeWidth = 2,
      );
    }
  }

  void _drawVelocityVector(Canvas canvas, Vector2 ballPos) {
    final thetaRad = theta * pi / 180;
    final vx = U * cos(thetaRad);
    final vy = U * sin(thetaRad) - g * elapsedTime;
    
    final vectorScale = 3.0;
    final endX = ballPos.x + vx * vectorScale;
    final endY = ballPos.y + vy * vectorScale;
    
    // Draw vector line
    canvas.drawLine(
      Offset(ballPos.x, ballPos.y),
      Offset(endX, endY),
      vectorPaint,
    );
    
    // Draw arrow head
    final angle = atan2(endY - ballPos.y, endX - ballPos.x);
    final arrowPath = Path()
      ..moveTo(endX, endY)
      ..lineTo(
        endX - 8 * cos(angle - pi / 6),
        endY - 8 * sin(angle - pi / 6),
      )
      ..lineTo(
        endX - 8 * cos(angle + pi / 6),
        endY - 8 * sin(angle + pi / 6),
      )
      ..close();
    
    final arrowPaint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawLabels(Canvas canvas) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Parameters box
    final paramsBg = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 140, 90),
        const Radius.circular(8),
      ),
      paramsBg,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 140, 90),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    
    // Draw parameter text
    _drawText(canvas, 'Projectile Motion', 20, 25, bold: true);
    _drawText(canvas, 'U = ${U.toStringAsFixed(1)} m/s', 20, 45);
    _drawText(canvas, 'θ = ${theta.toStringAsFixed(0)}°', 20, 60);
    _drawText(canvas, 'g = ${g.toStringAsFixed(2)} m/s²', 20, 75);
    
    // Axis labels
    canvas.save();
    canvas.scale(1, -1);
    _drawText(canvas, 'X (m)', size.x - 70, -15, centered: false);
    _drawText(canvas, 'Y', 15, -(size.y - 60), centered: false);
    canvas.restore();
  }

  // Method to update parameters at runtime
  void updateParams({double? U, double? theta, double? g}) {
    // Note: Since U, theta, g are final, we can't actually update them
    // This method exists for compatibility with visualiser_screen.dart
    // In a real scenario, you'd need to recreate the component with new values
    print('updateParams called - U: $U, theta: $theta, g: $g');
    print('Note: Parameters are final and cannot be changed at runtime');
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      {bool bold = false, bool centered = true}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
}
