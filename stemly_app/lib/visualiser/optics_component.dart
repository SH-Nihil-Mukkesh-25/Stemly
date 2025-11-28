// lib/visualiser/optics_component.dart
import 'dart:math';

import 'package:flutter/material.dart';

class OpticsWidget extends StatelessWidget {
  final double f;
  final double u;
  final double h_o;

  const OpticsWidget({
    super.key,
    required this.f,
    required this.u,
    required this.h_o,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: OpticsPainter(f: f, u: u, h_o: h_o),
      child: Container(),
    );
  }
}

class OpticsPainter extends CustomPainter {
  final double f;
  final double u;
  final double h_o;

  OpticsPainter({
    required this.f,
    required this.u,
    required this.h_o,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Lens formula: 1/v - 1/(-u) = 1/f  => 1/v + 1/u = 1/f => 1/v = 1/f - 1/u
    // u is object distance (usually negative in sign convention, but here input as positive distance)
    // Let's use standard sign convention: Light travels left to right.
    // Lens at origin (0,0).
    // Object at -u.
    // f is positive for convex.
    
    final objDist = u;
    final focalLen = f;
    
    // 1/v = 1/f - 1/u
    // If u < f, v is negative (virtual image)
    // If u = f, v is infinity
    // If u > f, v is positive (real image)
    
    double v = 0;
    if ((objDist - focalLen).abs() < 0.1) {
      v = 10000; // Infinity
    } else {
      v = 1 / (1/focalLen - 1/objDist);
    }
    
    // Magnification m = v/u
    final m = v / objDist;
    final h_i = m * h_o; // Image height (negative means inverted)

    // Scaling
    // We need to fit -u, +v, and lens in screen.
    // Total width needed approx u + v (if v>0) or max(u, |v|)
    final totalWidth = objDist + v.abs() + 20;
    final scale = (size.width * 0.8) / max(totalWidth, 50.0);
    
    final centerX = size.width / 2; // Lens center
    // Adjust center if v is very large? Let's keep lens at center for simplicity.
    
    final centerY = size.height / 2;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey.shade50,
    );

    // Principal Axis
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()..color = Colors.black54,
    );

    // Lens (Convex)
    _drawLens(canvas, centerX, centerY, 100);

    // Focus Points
    _drawPoint(canvas, centerX - f * scale, centerY, 'F1');
    _drawPoint(canvas, centerX + f * scale, centerY, 'F2');

    // Object
    final objX = centerX - objDist * scale;
    _drawArrow(canvas, objX, centerY, -h_o * scale * 3, Colors.blue, 'Object'); // *3 for visibility

    // Image
    if (v.abs() < 1000) {
      final imgX = centerX + v * scale;
      // h_i is negative for inverted real image.
      // Arrow drawing: positive height goes UP.
      // So we pass -h_i because h_i sign tells us orientation relative to axis?
      // Wait, m = v/u. If v>0 (real), m<0 (inverted). 
      // Actually m = v/u for lens? No, m = v/u.
      // If object is upright (+h_o), image height h_i = m * h_o.
      // If m is negative, h_i is negative (inverted).
      // My drawArrow takes length. If length < 0, it points up? No, let's standardize.
      
      _drawArrow(canvas, imgX, centerY, -h_i * scale * 3, Colors.red, 'Image');

      // Rays
      _drawRays(canvas, objX, centerY - h_o * scale * 3, imgX, centerY - h_i * scale * 3, centerX, centerY);
    }

    // Info
    _drawInfoPanel(canvas, v, m);
  }

  void _drawLens(Canvas canvas, double x, double y, double height) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(x, y - height/2);
    path.quadraticBezierTo(x + 20, y, x, y + height/2);
    path.quadraticBezierTo(x - 20, y, x, y - height/2);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..color = Colors.blue);
  }

  void _drawArrow(Canvas canvas, double x, double y, double height, Color color, String label) {
    // Height positive means UP? 
    // Usually y increases downwards.
    // So y - height means "up" if height is positive.
    
    final paint = Paint()..color = color..strokeWidth = 3;
    final tipY = y + height; // If height is -50, tip is at y-50 (UP)
    
    canvas.drawLine(Offset(x, y), Offset(x, tipY), paint);
    
    // Arrowhead
    final dir = height.sign; // -1 for UP
    // If UP, tip is at y-50. Arrowhead should point UP.
    
    final path = Path()
      ..moveTo(x, tipY)
      ..lineTo(x - 5, tipY - 10 * dir)
      ..lineTo(x + 5, tipY - 10 * dir)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    
    _drawText(canvas, label, x - 10, y + 10, color: color, bold: true);
  }

  void _drawPoint(Canvas canvas, double x, double y, String label) {
    canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.black);
    _drawText(canvas, label, x - 5, y + 5, size: 10);
  }

  void _drawRays(Canvas canvas, double ox, double oy, double ix, double iy, double cx, double cy) {
    final paint = Paint()..color = Colors.orange..strokeWidth = 1;
    
    // Ray 1: Parallel to axis, then through F2
    canvas.drawLine(Offset(ox, oy), Offset(cx, oy), paint);
    canvas.drawLine(Offset(cx, oy), Offset(ix, iy), paint);
    
    // Ray 2: Through Optical Center (undeviated)
    canvas.drawLine(Offset(ox, oy), Offset(ix, iy), paint);
  }

  void _drawInfoPanel(Canvas canvas, double v, double m) {
    final rect = Rect.fromLTWH(10, 10, 200, 100);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..style = PaintingStyle.stroke..color = Colors.black12,
    );

    _drawText(canvas, 'Convex Lens', 20, 20, size: 14, bold: true, color: Colors.blue);
    _drawText(canvas, 'Focal Length: ${f.toStringAsFixed(1)} cm', 20, 45);
    _drawText(canvas, 'Image Dist: ${v.toStringAsFixed(1)} cm', 20, 65);
    _drawText(canvas, 'Magnification: ${m.toStringAsFixed(2)}x', 20, 85);
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
  bool shouldRepaint(OpticsPainter oldDelegate) => true;
}