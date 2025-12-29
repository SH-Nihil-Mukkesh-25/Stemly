import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:function_tree/function_tree.dart';
import 'dart:math';

class EquationPlotterWidget extends StatefulWidget {
  final String equation;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final Color plotColor;

  const EquationPlotterWidget({
    super.key,
    required this.equation,
    this.minX = -10,
    this.maxX = 10,
    this.minY = -10,
    this.maxY = 10,
    this.plotColor = Colors.blue,
  });

  @override
  State<EquationPlotterWidget> createState() => _EquationPlotterWidgetState();
}

class _EquationPlotterWidgetState extends State<EquationPlotterWidget> {
  List<FlSpot> spots = [];
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _calculatePoints();
  }

  @override
  void didUpdateWidget(covariant EquationPlotterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equation != widget.equation ||
        oldWidget.minX != widget.minX ||
        oldWidget.maxX != widget.maxX) {
      _calculatePoints();
    }
  }

  void _calculatePoints() {
    spots.clear();
    hasError = false;
    
    // Resolution: 100 points
    final step = (widget.maxX - widget.minX) / 100;

    for (double x = widget.minX; x <= widget.maxX; x += step) {
      try {
        // Interpret the equation "x^2" -> replace x with actual value
        // function_tree handles basic math
        // Parse function once outside loop for performance, but inside here for simplicity/safety
        final f = widget.equation.toSingleVariableFunction('x');
        final y = f(x);
        
        if (y.isFinite && !y.isNaN) {
          // Clamp y to prevent chart explosion
          if (y >= widget.minY && y <= widget.maxY) {
             spots.add(FlSpot(x, y.toDouble()));
          }
        }
      } catch (e) {
        // Silent error or flagging
        hasError = true;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (hasError && spots.isEmpty) {
      return Center(
        child: Text(
          "Invalid Equation: ${widget.equation}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                },
                interval: (widget.maxX - widget.minX) / 5,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                },
                interval: (widget.maxY - widget.minY) / 5,
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          minX: widget.minX,
          maxX: widget.maxX,
          minY: widget.minY,
          maxY: widget.maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: widget.plotColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: widget.plotColor.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    );
  }
}
