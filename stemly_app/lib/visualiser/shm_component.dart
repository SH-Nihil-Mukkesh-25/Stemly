// lib/visualiser/shm_component.dart
import 'dart:math';
import 'package:flutter/material.dart';

class SHMWidget extends StatefulWidget {
  final double A;
  final double m;
  final double k;

  const SHMWidget({
    super.key,
    required this.A,
    required this.m,
    required this.k,
  });

  @override
  State<SHMWidget> createState() => _SHMWidgetState();
}

class _SHMWidgetState extends State<SHMWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double omega;
  late double period;

  @override
  void initState() {
    super.initState();
    omega = sqrt(widget.k / widget.m);
    period = 2 * pi / omega;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (period * 1000).toInt()),
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
          painter: SHMPainter(
            A: widget.A,
            m: widget.m,
            k: widget.k,
            progress: _controller.value,
            omega: omega,
          ),
          child: Container(),
        );
      },
    );
  }
}

class SHMPainter extends CustomPainter {
  final double A;
  final double m;
  final double k;
  final double progress;
  final double omega;

  SHMPainter({
    required this.A,
    required this.m,
    required this.k,
    required this.progress,
    required this.omega,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * (2 * pi / omega);
    final displacement = A * cos(omega * t);
    final velocity = -A * omega * sin(omega * t);

    final centerX = size.width * 0.3; // Spring on left side
    final centerY = size.height / 2;
    
    // Scale for visualization (pixels per meter)
    // Ensure amplitude fits within half height with some margin
    final scale = (size.height * 0.4) / (A * 1.5); 

    // Draw Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3E5F5), Color(0xFFFAFAFA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Ceiling
    final ceilingY = centerY - (A * scale) - 50;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 40, ceilingY - 10, 80, 10),
      Paint()..color = Colors.grey.shade700,
    );

    // Draw Equilibrium Line (Manual dashed line)
    final dashPaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    double dashX = centerX - 60;
    while (dashX < centerX + 60) {
      canvas.drawLine(
        Offset(dashX, centerY),
        Offset(min(dashX + 5, centerX + 60), centerY),
        dashPaint,
      );
      dashX += 10;
    }
    _drawText(canvas, 'Equilibrium', centerX - 80, centerY, size: 10, color: Colors.green);

    // Draw Spring
    final massY = centerY + displacement * scale;
    _drawSpring(canvas, centerX, ceilingY, massY - 20, 20);

    // Draw Mass
    _drawMass(canvas, centerX, massY);

    // Draw Velocity Vector
    _drawVelocityVector(canvas, centerX + 40, massY, velocity);

    // Draw Graph (Right side)
    _drawGraph(canvas, size, t, displacement);

    // Draw Info Panel
    _drawInfoPanel(canvas, displacement, velocity);
  }

  void _drawSpring(Canvas canvas, double x, double startY, double endY, double width) {
    final coils = 12;
    final height = endY - startY;
    final coilHeight = height / coils;
    
    final path = Path()..moveTo(x, startY);
    for (int i = 0; i < coils; i++) {
      final y = startY + i * coilHeight;
      path.lineTo(i.isEven ? x + width/2 : x - width/2, y + coilHeight/2);
      path.lineTo(x, y + coilHeight);
    }

    canvas.drawPath(
      path,
      Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }

  void _drawMass(Canvas canvas, double x, double y) {
    final size = 40.0;
    final rect = Rect.fromCenter(center: Offset(x, y), width: size, height: size);
    
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 5, y + 5), width: size, height: size/2),
      Paint()..color = Colors.black12,
    );

    // Block
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.blue.shade300, Colors.blue.shade700],
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(4)),
      Paint()..shader = gradient.createShader(rect),
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(4)),
      Paint()..style = PaintingStyle.stroke..color = Colors.black26,
    );

    _drawText(canvas, 'm', x - 5, y - 6, color: Colors.white, bold: true);
  }

  void _drawVelocityVector(Canvas canvas, double x, double y, double velocity) {
    final length = (velocity * 10).clamp(-50.0, 50.0);
    if (length.abs() < 2) return;

    final endY = y + length; // Positive velocity is down in screen coords if we consider down as positive y, but usually up is positive displacement. 
    // Wait, displacement = A cos(wt). Velocity = -A w sin(wt).
    // Screen Y increases downwards.
    // If displacement is positive (downwards in our drawing), y > centerY.
    // Let's stick to visual representation: arrow points in direction of motion.
    
    final paint = Paint()..color = Colors.red..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, y), Offset(x, y + length), paint);
    
    // Arrowhead
    final dir = length.sign;
    final arrowY = y + length;
    final path = Path()
      ..moveTo(x, arrowY)
      ..lineTo(x - 3, arrowY - 5 * dir)
      ..lineTo(x + 3, arrowY - 5 * dir)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.red);
    
    _drawText(canvas, 'v', x + 5, y + length/2, color: Colors.red, size: 10);
  }

  void _drawGraph(Canvas canvas, Size size, double t, double displacement) {
    final graphRect = Rect.fromLTWH(size.width * 0.6, size.height * 0.2, size.width * 0.35, size.height * 0.6);
    
    // Background
    canvas.drawRect(graphRect, Paint()..color = Colors.white70);
    canvas.drawRect(graphRect, Paint()..style = PaintingStyle.stroke..color = Colors.black12);

    // Axes
    final midY = graphRect.center.dy;
    canvas.drawLine(
      Offset(graphRect.left, midY),
      Offset(graphRect.right, midY),
      Paint()..color = Colors.black26,
    );

    // Plot
    // We want to show a window of time, e.g., 2 periods.
    // But this is a stateless painter frame. We can compute the curve.
    final path = Path();
    final timeWindow = 2 * (2 * pi / omega);
    final points = 50;
    
    for (int i = 0; i <= points; i++) {
      final timeOffset = (i / points) * timeWindow;
      // We want the current time 't' to be at the right or middle?
      // Let's make it a scrolling graph where t is at the right edge?
      // Or just static sine wave? Static is easier to understand for "Position vs Time".
      // Let's show t moving through the wave.
      
      final plotT = t - timeWindow + timeOffset;
      final val = A * cos(omega * plotT);
      
      // Map to rect
      final px = graphRect.left + (i / points) * graphRect.width;
      // Scale amplitude to fit graph height
      final py = midY + (val / A) * (graphRect.height * 0.4);
      
      if (i == 0) path.moveTo(px, py);
      else path.lineTo(px, py);
    }

    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..color = Colors.blue..strokeWidth = 2);
    
    // Current point marker
    // The last point in our loop corresponds to time 't'
    final currentVal = displacement;
    final cx = graphRect.right;
    final cy = midY + (currentVal / A) * (graphRect.height * 0.4);
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = Colors.red);
    
    _drawText(canvas, 'Position vs Time', graphRect.left, graphRect.top - 20, bold: true);
  }

  void _drawInfoPanel(Canvas canvas, double displacement, double velocity) {
    final rect = Rect.fromLTWH(10, 10, 180, 90);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..style = PaintingStyle.stroke..color = Colors.black12,
    );

    _drawText(canvas, 'SHM', 20, 20, size: 14, bold: true, color: Colors.purple);
    _drawText(canvas, 'Displacement: ${displacement.toStringAsFixed(2)} m', 20, 45);
    _drawText(canvas, 'Velocity: ${velocity.toStringAsFixed(2)} m/s', 20, 65);
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
  bool shouldRepaint(SHMPainter oldDelegate) => true;
}