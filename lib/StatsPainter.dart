import 'package:flutter/material.dart';
import 'ScoreInstance.dart';
import 'dart:math';

class StatsPainter extends CustomPainter {
  StatsPainter(this.normGroupCenter, this.normRestCenter, this.targetRadiusScaleFactor) {}

  Offset normGroupCenter; // assuming 1 pixel or cm target
  Offset normRestCenter;
  Offset targetCenter;
  double targetRadius;
  bool useCanvasSize = true;
  double targetRadiusScaleFactor = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (normRestCenter == Offset(0, 0)) {
      return;
    }

    if (size.width != 0 && useCanvasSize) {
      targetCenter = Offset(size.width / 2, size.height / 2);
      targetRadius = min(size.height, size.width) / 2.0 * targetRadiusScaleFactor;
    }

    Offset groupCenter = targetCenter + normGroupCenter * targetRadius;
    Offset restCenter = targetCenter + normRestCenter * targetRadius;
    double dotRadius = targetRadius / 20;

    Paint paintFill = Paint()
      ..color = Colors.purpleAccent
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    Paint paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = targetRadius / 30
      ..style = PaintingStyle.stroke;

    canvas.drawLine(groupCenter, restCenter, paint);
    paintFill.color = Colors.blueGrey;
    canvas.drawCircle(restCenter, dotRadius, paintFill);
    paintFill.color = Colors.purpleAccent;
    canvas.drawCircle(groupCenter, dotRadius, paintFill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
