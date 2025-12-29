import 'dart:ui';
import 'package:flutter/material.dart';

class GraphWidget extends StatelessWidget {
  final double a;
  final double b;
  final double c;

  const GraphWidget({
    super.key,
    required this.a,
    required this.b,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: CustomPaint(
        painter: GraphPainter(a: a, b: b, c: c),
        child: Container(),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final double a;
  final double b;
  final double c;

  GraphPainter({required this.a, required this.b, required this.c});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    // 1. Draw Axes
    canvas.drawLine(Offset(0, h/2), Offset(w, h/2), paint); // X-axis
    canvas.drawLine(Offset(w/2, 0), Offset(w/2, h), paint); // Y-axis
    
    // Grid lines (every 20 pixels)
    paint.color = Colors.grey.withOpacity(0.2);
    for (double i = center.dx; i < w; i += 20) canvas.drawLine(Offset(i, 0), Offset(i, h), paint);
    for (double i = center.dx; i > 0; i -= 20) canvas.drawLine(Offset(i, 0), Offset(i, h), paint);
    for (double i = center.dy; i < h; i += 20) canvas.drawLine(Offset(0, i), Offset(w, i), paint);
    for (double i = center.dy; i > 0; i -= 20) canvas.drawLine(Offset(0, i), Offset(w, i), paint);

    // 2. Plot Function: y = ax^2 + bx + c
    paint.color = Colors.blue;
    paint.strokeWidth = 2.5;
    
    final path = Path();
    bool first = true;
    
    // Scale factor: 20 pixels = 1 unit
    const double scale = 20.0;
    
    for (double px = 0; px <= w; px++) {
      // Screen x to Math x
      double x = (px - center.dx) / scale;
      
      // Calculate Math y
      double y = (a * x * x) + (b * x) + c;
      
      // Math y to Screen y (Note: Screen Y is inverted)
      double py = center.dy - (y * scale);
      
      if (first) {
        path.moveTo(px, py);
        first = false;
      } else {
        path.lineTo(px, py);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // 3. Draw Equation Text
    final eq = "y = ${a.toStringAsFixed(1)}x² + ${b.toStringAsFixed(1)}x + ${c.toStringAsFixed(1)}";
    final textPainter = TextPainter(
      text: TextSpan(
        text: eq,
        style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(16, 16));
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.a != a || oldDelegate.b != b || oldDelegate.c != c;
  }
}
