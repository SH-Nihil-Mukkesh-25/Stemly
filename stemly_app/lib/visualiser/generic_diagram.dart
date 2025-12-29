import 'package:flutter/material.dart';

class GenericDiagramWidget extends StatelessWidget {
  final List<Map<String, dynamic>> primitives;
  final Color baseColor;

  const GenericDiagramWidget({
    super.key,
    required this.primitives,
    this.baseColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomPaint(
        painter: DiagramPainter(primitives, baseColor),
        child: Container(),
      ),
    );
  }
}

class DiagramPainter extends CustomPainter {
  final List<Map<String, dynamic>> primitives;
  final Color baseColor;

  DiagramPainter(this.primitives, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = baseColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Coordinate conversion: Assume standard 100x100 grid from API, scale to size
    // OR just use relative percentages. 
    // Let's assume input is 0-100 coordinates.
    double scaleX = size.width / 100;
    double scaleY = size.height / 100;

    for (var p in primitives) {
      String type = p["type"] ?? "unknown";
      
      if (type == "rect") {
        double x = (p["x"] as num).toDouble() * scaleX;
        double y = (p["y"] as num).toDouble() * scaleY;
        double w = (p["w"] as num).toDouble() * scaleX;
        double h = (p["h"] as num).toDouble() * scaleY;
        
        Rect rect = Rect.fromLTWH(x, y, w, h);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, paint);
      } 
      else if (type == "circle") {
        double x = (p["x"] as num).toDouble() * scaleX;
        double y = (p["y"] as num).toDouble() * scaleY;
        double r = (p["r"] as num).toDouble() * scaleX;

        canvas.drawCircle(Offset(x, y), r, fillPaint);
        canvas.drawCircle(Offset(x, y), r, paint);
      }
      else if (type == "line") {
        double x1 = (p["x1"] as num).toDouble() * scaleX;
        double y1 = (p["y1"] as num).toDouble() * scaleY;
        double x2 = (p["x2"] as num).toDouble() * scaleX;
        double y2 = (p["y2"] as num).toDouble() * scaleY;
        
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        
        // Arrow head logic? simple lines for now.
      }
      else if (type == "text") {
        double x = (p["x"] as num).toDouble() * scaleX;
        double y = (p["y"] as num).toDouble() * scaleY;
        String text = p["text"] ?? "";
        
        TextSpan span = TextSpan(
          text: text, 
          style: TextStyle(color: baseColor, fontSize: 14, fontWeight: FontWeight.bold)
        );
        TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
