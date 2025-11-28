// lib/visualiser/free_fall_component.dart
import 'dart:math';
import 'package:flutter/material.dart';

class FreeFallWidget extends StatefulWidget {
  final double h;
  final double g;

  const FreeFallWidget({
    super.key,
    required this.h,
    required this.g,
  });

  @override
  State<FreeFallWidget> createState() => _FreeFallWidgetState();
}

class _FreeFallWidgetState extends State<FreeFallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double totalFallTime;

  @override
  void initState() {
    super.initState();
    totalFallTime = sqrt(2 * widget.h / widget.g);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (totalFallTime * 1000 + 1500).toInt()),
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
          painter: FreeFallPainter(
            h: widget.h,
            g: widget.g,
            progress: _controller.value,
            totalFallTime: totalFallTime,
          ),
          child: Container(),
        );
      },
    );
  }
}

class FreeFallPainter extends CustomPainter {
  final double h;
  final double g;
  final double progress;
  final double totalFallTime;

  FreeFallPainter({
    required this.h,
    required this.g,
    required this.progress,
    required this.totalFallTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Time calculation
    final totalDuration = totalFallTime + 1.5; // fall time + pause
    final currentTime = progress * totalDuration;
    final elapsedTime = min(currentTime, totalFallTime);
    
    // Physics calculations
    final currentHeight = max(0.0, h - 0.5 * g * elapsedTime * elapsedTime);
    final currentVelocity = g * elapsedTime;

    // Layout calculations
    final marginY = size.height * 0.15;
    final scale = (size.height - 2 * marginY) / h;
    final groundY = size.height - marginY;
    final centerX = size.width / 2;

    // Draw Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE3F2FD), Color(0xFFFAFAFA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Ground
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF8BC34A),
    );

    // Draw Ruler
    _drawRuler(canvas, centerX - 100, groundY, scale, h);

    // Draw Ball
    final ballY = groundY - currentHeight * scale;
    _drawBall(canvas, centerX, ballY, groundY, currentVelocity);

    // Draw Height Indicator
    if (currentHeight > 0) {
      _drawHeightLine(canvas, centerX, groundY, ballY);
    }

    // Draw Velocity Meter
    _drawVelocityMeter(canvas, size, currentVelocity, sqrt(2 * g * h));

    // Draw Info Panel
    _drawInfoPanel(canvas, currentHeight, currentVelocity);

    // Impact Effect
    if (currentTime > totalFallTime && currentTime < totalFallTime + 0.5) {
      final impactProgress = (currentTime - totalFallTime) / 0.5;
      _drawImpact(canvas, centerX, groundY, impactProgress);
    }
  }

  void _drawRuler(Canvas canvas, double x, double groundY, double scale, double maxHeight) {
    // Ruler background
    canvas.drawRect(
      Rect.fromLTWH(x - 15, groundY - maxHeight * scale - 20, 50, maxHeight * scale + 40),
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // Main line
    canvas.drawLine(
      Offset(x, groundY),
      Offset(x, groundY - maxHeight * scale),
      Paint()..color = Colors.black87..strokeWidth = 2,
    );

    // Ticks
    final step = maxHeight > 20 ? 5.0 : 1.0;
    for (double m = 0; m <= maxHeight; m += step) {
      final y = groundY - m * scale;
      canvas.drawLine(
        Offset(x - 5, y),
        Offset(x + 5, y),
        Paint()..color = Colors.black87..strokeWidth = 1,
      );
      
      if (m % (step * 2) == 0) {
         _drawText(canvas, '${m.toInt()}m', x + 15, y - 6, size: 10);
      }
    }
  }

  void _drawBall(Canvas canvas, double x, double y, double groundY, double velocity) {
    // Shadow
    final shadowSize = 15 + (groundY - y) * 0.05;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, groundY), width: shadowSize, height: shadowSize / 2),
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    // Motion blur (simple trail)
    if (velocity > 5) {
      for (int i = 1; i <= 3; i++) {
        canvas.drawCircle(
          Offset(x, y - i * 5),
          15 - i * 2.0,
          Paint()..color = const Color(0xFFE91E63).withOpacity(0.2 - i * 0.05),
        );
      }
    }

    // Ball
    final gradient = RadialGradient(
      colors: [const Color(0xFFF48FB1), const Color(0xFFE91E63)],
      center: Alignment(-0.3, -0.3),
    );
    
    canvas.drawCircle(
      Offset(x, y),
      15,
      Paint()..shader = gradient.createShader(Rect.fromCircle(center: Offset(x, y), radius: 15)),
    );
  }

  void _drawHeightLine(Canvas canvas, double x, double groundY, double ballY) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    // Dashed line
    double dashHeight = 5, dashSpace = 5, startY = ballY;
    while (startY < groundY) {
      canvas.drawLine(Offset(x, startY), Offset(x, min(startY + dashHeight, groundY)), paint);
      startY += dashHeight + dashSpace;
    }
  }

  void _drawVelocityMeter(Canvas canvas, Size size, double velocity, double maxVelocity) {
    final meterX = size.width - 60;
    final meterY = 60.0;
    final meterHeight = 150.0;
    final meterWidth = 30.0;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(meterX, meterY, meterWidth, meterHeight),
      Paint()..color = Colors.grey.shade300,
    );

    // Fill
    final fillHeight = (velocity / maxVelocity).clamp(0.0, 1.0) * meterHeight;
    canvas.drawRect(
      Rect.fromLTWH(meterX, meterY + meterHeight - fillHeight, meterWidth, fillHeight),
      Paint()..color = Color.lerp(Colors.green, Colors.red, velocity / maxVelocity)!,
    );

    // Border
    canvas.drawRect(
      Rect.fromLTWH(meterX, meterY, meterWidth, meterHeight),
      Paint()..style = PaintingStyle.stroke..color = Colors.black54,
    );

    _drawText(canvas, 'Vel', meterX, meterY - 20, size: 12, bold: true);
    _drawText(canvas, '${velocity.toStringAsFixed(1)}', meterX, meterY + meterHeight + 5, size: 12);
  }

  void _drawInfoPanel(Canvas canvas, double height, double velocity) {
    final rect = Rect.fromLTWH(10, 10, 160, 80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8)),
      Paint()..style = PaintingStyle.stroke..color = Colors.black12,
    );

    _drawText(canvas, 'Free Fall', 20, 20, size: 14, bold: true, color: Colors.blue);
    _drawText(canvas, 'Height: ${height.toStringAsFixed(1)} m', 20, 45);
    _drawText(canvas, 'Velocity: ${velocity.toStringAsFixed(1)} m/s', 20, 65);
  }

  void _drawImpact(Canvas canvas, double x, double y, double progress) {
    final radius = 10 + progress * 30;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.orange.withOpacity(opacity),
    );
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
  bool shouldRepaint(FreeFallPainter oldDelegate) => 
      oldDelegate.progress != progress || 
      oldDelegate.h != h || 
      oldDelegate.g != g;
}
