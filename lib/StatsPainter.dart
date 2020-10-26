import 'package:flutter/material.dart';
import 'ScoreInstance.dart';
import 'dart:math';

class StatsPainter extends CustomPainter {
  StatsPainter(this.normGroupCenter, this.normRestCenter, this.targetRadiusScaleFactor, [this.confidenceVectors]) {}
  StatsPainter.fromTargetLocation(this.normGroupCenter, this.targetCenter, this.targetRadius, this.confidenceVectors) {
    useCanvasSize = false;
  }

  Offset normGroupCenter; // assuming 1 pixel or cm target
  Offset normRestCenter = Offset(0, 0);
  Offset targetCenter;
  double targetRadius;
  bool useCanvasSize = true;
  double targetRadiusScaleFactor = 1.0;
  List<Offset> confidenceVectors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width != 0 && useCanvasSize) {
      targetCenter = Offset(size.width / 2, size.height / 2);
      targetRadius = min(size.height, size.width) / 2.0 * targetRadiusScaleFactor;
      if (confidenceVectors != null && confidenceVectors.isNotEmpty) {
        confidenceVectors.first *= targetRadius;
        confidenceVectors.last *= targetRadius;
      }
    }

    Offset groupCenter = targetCenter + normGroupCenter * targetRadius;
    Offset restCenter = targetCenter + normRestCenter * targetRadius;
    double dotRadius = targetRadius / 40;

    Paint paintFill = Paint()
      ..color = Colors.purpleAccent
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    Paint paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = targetRadius / 30
      ..style = PaintingStyle.stroke;

    Paint transPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    if (normRestCenter != Offset(0, 0)) {
      canvas.drawLine(groupCenter, restCenter, paint);
      paintFill.color = Colors.blueGrey;
      canvas.drawCircle(restCenter, dotRadius, paintFill);
      paintFill.color = Colors.purpleAccent;
    }

    if (confidenceVectors != null && confidenceVectors.isNotEmpty) {
      double len1 = sqrt(pow(confidenceVectors.first.dx, 2) + pow(confidenceVectors.first.dy, 2));
      double len2 = sqrt(pow(confidenceVectors.last.dx, 2) + pow(confidenceVectors.last.dy, 2));

      canvas.save();
      canvas.translate(groupCenter.dx, groupCenter.dy);
      canvas.rotate(atan2(confidenceVectors.first.dy, confidenceVectors.first.dx));
      canvas.drawOval(Rect.fromCenter(center: Offset(0, 0), height: len2 * 1.5, width: len1 * 1.5), transPaint);
      canvas.restore();
    }

    canvas.drawCircle(groupCenter, dotRadius, paintFill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
