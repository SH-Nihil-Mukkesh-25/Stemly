// lib/visualiser/projectile_motion.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ProjectileMotionWidget extends StatefulWidget {
  final double U;
  final double theta;
  final double g;
  
  const ProjectileMotionWidget({
    super.key,
    required this.U,
    required this.theta,
    required this.g,
  });
  
  @override
  State<ProjectileMotionWidget> createState() => _ProjectileMotionWidgetState();
}

class _ProjectileMotionWidgetState extends State<ProjectileMotionWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double totalFlightTime;
  final List<Offset> trajectoryPoints = [];
  
  @override
  void initState() {
    super.initState();
    
    final thetaRad = widget.theta * pi / 180;
    totalFlightTime = (2 * widget.U * sin(thetaRad)) / widget.g;
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (totalFlightTime * 1000 + 1000).toInt()),
    )..repeat();
    
    _controller.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ProjectileMotionPainter(
        U: widget.U,
        theta: widget.theta,
        g: widget.g,
        progress: _controller.value,
        totalFlightTime: totalFlightTime,
      ),
      child: Container(),
    );
  }
}

class ProjectileMotionPainter extends CustomPainter {
  final double U;
  final double theta;
  final double g;
  final double progress;
  final double totalFlightTime;
  
  ProjectileMotionPainter({
    required this.U,
    required this.theta,
    required this.g,
    required this.progress,
    required this.totalFlightTime,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final thetaRad = theta * pi / 180;
    final range = (U * U * sin(2 * thetaRad)) / g;
    final maxHeight = (U * U * sin(thetaRad) * sin(thetaRad)) / (2 * g);
    
    // Calculate scale
    final marginX = size.width * 0.1;
    final marginY = size.height * 0.15;
    final scaleX = (size.width - 2 * marginX) / range;
    final scaleY = (size.height - 2 * marginY) / maxHeight;
    final scale = min(scaleX, scaleY);
    
    final originX = marginX;
    final originY = size.height - marginY;
    
    // Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE3F2FD), Color(0xFFFAFAFA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, originY, size.width, size.height - originY),
      Paint()..color = const Color(0xFF8BC34A),
    );
    
    // Grid
    _drawGrid(canvas, originX, originY, scale, range, maxHeight);
    
    // Axes
    _drawAxes(canvas, size, originX, originY, scale, range, maxHeight);
    
    // Trajectory
    _drawTrajectory(canvas, originX, originY, scale);
    
    // Ball
    final elapsedTime = progress * (totalFlightTime + 1.0);
    if (elapsedTime <= totalFlightTime) {
      final pos = _calculatePosition(elapsedTime);
      _drawBall(canvas, originX, originY, scale, pos);
      _drawVelocityVector(canvas, originX, originY, scale, pos, elapsedTime);
    }
    
    // Info panel
    _drawInfoPanel(canvas, size, range, maxHeight);
  }
  
  Offset _calculatePosition(double t) {
    final thetaRad = theta * pi / 180;
    final x = U * cos(thetaRad) * t;
    final y = max(0.0, U * sin(thetaRad) * t - 0.5 * g * t * t);
    return Offset(x, y);
  }
  
  void _drawGrid(Canvas canvas, double originX, double originY, double scale, double range, double maxHeight) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    
    // Vertical lines
    for (double x = 0; x <= range; x += 5) {
      canvas.drawLine(
        Offset(originX + x * scale, originY),
        Offset(originX + x * scale, originY - maxHeight * scale * 1.2),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y <= maxHeight * 1.2; y += 5) {
      canvas.drawLine(
        Offset(originX, originY - y * scale),
        Offset(originX + range * scale, originY - y * scale),
        gridPaint,
      );
    }
  }
  
  void _drawAxes(Canvas canvas, Size size, double originX, double originY, double scale, double range, double maxHeight) {
    final axisPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2;
    
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
    
    // Labels
    _drawText(canvas, 'Distance (m)', originX + range * scale / 2, originY + 30, size: 14, bold: true);
  }
  
  void _drawTrajectory(Canvas canvas, double originX, double originY, double scale) {
    // Draw full trajectory path
    final path = Path();
    final steps = 50;
    
    for (int i = 0; i <= steps; i++) {
      final t = (i / steps) * totalFlightTime;
      final pos = _calculatePosition(t);
      final x = originX + pos.dx * scale;
      final y = originY - pos.dy * scale;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF6B35).withOpacity(0.4)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }
  
  void _drawBall(Canvas canvas, double originX, double originY, double scale, Offset pos) {
    final x = originX + pos.dx * scale;
    final y = originY - pos.dy * scale;
    
    // Shadow
    canvas.drawCircle(
      Offset(x, originY),
      12,
      Paint()..color = Colors.black.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    
    // Ball
    canvas.drawCircle(
      Offset(x, y),
      15,
      Paint()..shader = const RadialGradient(
        colors: [Color(0xFFFF8C5A), Color(0xFFFF6B35)],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 15)),
    );
    
    // Highlight
    canvas.drawCircle(
      Offset(x - 4, y - 4),
      5,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }
  
  void _drawVelocityVector(Canvas canvas, double originX, double originY, double scale, Offset pos, double t) {
    final thetaRad = theta * pi / 180;
    final vx = U * cos(thetaRad);
    final vy = U * sin(thetaRad) - g * t;
    
    final x = originX + pos.dx * scale;
    final y = originY - pos.dy * scale;
    
    final vectorScale = 0.15 * scale;
    final endX = x + vx * vectorScale;
    final endY = y - vy * vectorScale;
    
    // Vector line
    canvas.drawLine(
      Offset(x, y),
      Offset(endX, endY),
      Paint()..color = const Color(0xFF2196F3)..strokeWidth = 3,
    );
    
    // Arrow head
    final angle = atan2(endY - y, endX - x);
    final arrowPath = Path()
      ..moveTo(endX, endY)
      ..lineTo(endX - 10 * cos(angle - pi / 6), endY - 10 * sin(angle - pi / 6))
      ..lineTo(endX - 10 * cos(angle + pi / 6), endY - 10 * sin(angle + pi / 6))
      ..close();
    
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFF2196F3));
    
    // Velocity magnitude
    final v = sqrt(vx * vx + vy * vy);
    _drawText(canvas, 'v = ${v.toStringAsFixed(1)} m/s', endX + 10, endY - 10, 
        size: 12, color: const Color(0xFF2196F3), bold: true);
  }
  
  void _drawInfoPanel(Canvas canvas, Size size, double range, double maxHeight) {
    final panelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 10, 200, 140),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(panelRect, Paint()..color = Colors.white.withOpacity(0.95));
    canvas.drawRRect(
      panelRect,
      Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    
    _drawText(canvas, 'Projectile Motion', 20, 30, size: 16, bold: true, color: const Color(0xFF1976D2));
    _drawText(canvas, 'U = ${U.toStringAsFixed(1)} m/s', 20, 55, size: 13);
    _drawText(canvas, 'θ = ${theta.toStringAsFixed(0)}°', 20, 75, size: 13);
    _drawText(canvas, 'g = ${g.toStringAsFixed(2)} m/s²', 20, 95, size: 13);
    _drawText(canvas, 'Range: ${range.toStringAsFixed(1)} m', 20, 115, size: 13, color: const Color(0xFFFF6B35), bold: true);
    _drawText(canvas, 'Max H: ${maxHeight.toStringAsFixed(1)} m', 20, 135, size: 13, color: const Color(0xFFFF6B35), bold: true);
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
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
  
  @override
  bool shouldRepaint(ProjectileMotionPainter oldDelegate) => true;
}