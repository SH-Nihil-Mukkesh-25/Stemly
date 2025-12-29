import 'dart:math';
import 'package:flutter/material.dart';

class AtomWidget extends StatelessWidget {
  final double protons;
  final double neutrons;

  const AtomWidget({
    super.key,
    required this.protons,
    required this.neutrons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: CustomPaint(
        painter: AtomPainter(
          protons: protons.toInt(),
          neutrons: neutrons.toInt(),
          animationValue: 0.0, // Static for now, can add animation later
        ),
        child: Container(),
      ),
    );
  }
}

class AtomPainter extends CustomPainter {
  final int protons;
  final int neutrons;
  final double animationValue;

  AtomPainter({required this.protons, required this.neutrons, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    // 1. Draw Nucleus
    paint.color = Colors.redAccent;
    canvas.drawCircle(center, 12, paint);
    
    // Protons count text
    final textPainter = TextPainter(
      text: TextSpan(
        text: "${protons}p",
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));

    // 2. Draw Shells and Electrons
    // Shell capacity: 2, 8, 18
    int remainingElectrons = protons; // Neutral atom assume electrons = protons
    int shellIndex = 1;
    
    while (remainingElectrons > 0) {
      int capacity = 2 * shellIndex * shellIndex;
      int electronsInShell = min(remainingElectrons, capacity);
      
      double radius = 30.0 + (shellIndex * 25.0);
      
      // Draw Shell Circle
      paint.color = Colors.grey.withOpacity(0.3);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
      
      // Draw Electrons
      paint.style = PaintingStyle.fill;
      paint.color = Colors.blueAccent;
      
      for (int i = 0; i < electronsInShell; i++) {
        double angle = (2 * pi / electronsInShell) * i - (pi / 2);
        // Add some offset based on shell to make it look nicer
        if (shellIndex % 2 == 0) angle += pi / 4; 
        
        double ex = center.dx + radius * cos(angle);
        double ey = center.dy + radius * sin(angle);
        
        canvas.drawCircle(Offset(ex, ey), 5, paint);
      }
      
      remainingElectrons -= electronsInShell;
      shellIndex++;
    }
    
    // Element Name (Basic lookup)
    String element = _getElementSymbol(protons);
    final symbolPainter = TextPainter(
      text: TextSpan(
        text: element,
        style: TextStyle(
          color: Colors.black.withOpacity(0.1),
          fontSize: 80,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    symbolPainter.layout();
    symbolPainter.paint(canvas, Offset(20, 20));
  }
  
  String _getElementSymbol(int z) {
    const symbols = ["n", "H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca"];
    if (z > 0 && z < symbols.length) return symbols[z];
    return "?";
  }

  @override
  bool shouldRepaint(covariant AtomPainter oldDelegate) {
    return oldDelegate.protons != protons || oldDelegate.neutrons != neutrons;
  }
}
