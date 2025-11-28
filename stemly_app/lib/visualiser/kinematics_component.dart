// lib/visualiser/kinematics_component.dart
import 'dart:math';

import 'package:flutter/material.dart';

class KinematicsWidget extends StatefulWidget {
  final double u;
  final double a;
  final double tMax;

  const KinematicsWidget({
    super.key,
    required this.u,
    required this.a,
    required this.tMax,
  });

  @override
  State<KinematicsWidget> createState() => _KinematicsWidgetState();
}

class _KinematicsWidgetState extends State<KinematicsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.tMax * 1000).toInt()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: KinematicsPainter(
            u: widget.u,
            a: widget.a,
            tMax: widget.tMax,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class KinematicsPainter extends CustomPainter {
  final double u;
  final double a;
  final double tMax;
  final double progress;

  KinematicsPainter({
    required this.u,
    required this.a,
    required this.tMax,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * tMax;
    
    // Physics: x = ut + 0.5at^2
    final x = u * t + 0.5 * a * t * t;
    final v = u + a * t;
    
    // Max distance for scaling (assume max possible x at tMax)
    // We need to handle negative direction too
    final maxDist = max((u * tMax + 0.5 * a * tMax * tMax).abs(), 100.0);
    
    final margin = 40.0;
    final scale = (size.width - 2 * margin) / maxDist;
    final centerY = size.height / 2;
    final startX = margin;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.blueGrey.shade50,
    );

    // Road
    canvas.drawRect(
      Rect.fromLTWH(0, centerY + 20, size.width, 60),
      Paint()..color = Colors.grey.shade800,
    );
    
    // Road markings
    final dashPaint = Paint()..color = Colors.white..strokeWidth = 2;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, centerY + 50), Offset(i + 20, centerY + 50), dashPaint);
    }

    // Car Position
    // If x is negative, we might go off screen left. Let's clamp or center?
    // Let's assume motion starts at startX and goes right. 
    // If x is negative, it goes left.
    // Let's put origin at left margin.
    
    final carX = startX + x * scale;
    final carY = centerY + 20; // On the road

    // Draw Car
    _drawCar(canvas, carX, carY, v);

    // Draw Info
    _drawInfoPanel(canvas, t, x, v);
  }

  void _drawCar(Canvas canvas, double x, double y, double v) {
    // Simple car shape
    final carWidth = 60.0;
    final carHeight = 30.0;
    
    // Wheels
    canvas.drawCircle(Offset(x + 15, y), 8, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(x + 45, y), 8, Paint()..color = Colors.black);

    // Body
    final bodyRect = Rect.fromLTWH(x, y - carHeight, carWidth, carHeight - 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(8)),
      Paint()..color = Colors.redAccent,
    );
    
    // Roof
    canvas.drawRect(
      Rect.fromLTWH(x + 15, y - carHeight - 15, 30, 15),
      Paint()..color = Colors.redAccent,
    );
    
    // Velocity Vector
    if (v.abs() > 0.1) {
      final arrowLen = v.clamp(-50, 50) * 2.0;
      final arrowY = y - carHeight - 30;
      final arrowX = x + carWidth / 2;
      
      final p = Paint()..color = Colors.blue..strokeWidth = 3..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(arrowX, arrowY), Offset(arrowX + arrowLen, arrowY), p);
      
      // Arrowhead
      final dir = arrowLen.sign;
      canvas.drawLine(Offset(arrowX + arrowLen, arrowY), Offset(arrowX + arrowLen - 5 * dir, arrowY - 5), p);
      canvas.drawLine(Offset(arrowX + arrowLen, arrowY), Offset(arrowX + arrowLen - 5 * dir, arrowY + 5), p);
      
      _drawText(canvas, 'v', arrowX + arrowLen/2, arrowY - 15, color: Colors.blue, bold: true);
    }
  }

  void _drawInfoPanel(Canvas canvas, double t, double x, double v) {
    final rect = Rect.fromLTWH(10, 10, 200, 100);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..style = PaintingStyle.stroke..color = Colors.black12,
    );

    _drawText(canvas, 'Kinematics (1D)', 20, 20, size: 14, bold: true, color: Colors.indigo);
    _drawText(canvas, 'Time: ${t.toStringAsFixed(1)} s', 20, 45);
    _drawText(canvas, 'Displacement: ${x.toStringAsFixed(1)} m', 20, 65);
    _drawText(canvas, 'Velocity: ${v.toStringAsFixed(1)} m/s', 20, 85);
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
  bool shouldRepaint(KinematicsPainter oldDelegate) => true;
}