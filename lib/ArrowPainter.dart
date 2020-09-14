import 'package:flutter/material.dart';
import 'ScoreInstance.dart';

class ArrowPainter extends CustomPainter {
  ArrowPainter(this._offset, this._radius, this._spot); // TODO include default position
  ArrowPainter.fromInstance(ScoreInstance instance, this._spot, Offset targetCenter, double targetRadius)
      : this._offset = instance.getCartesianCoordinates(targetRadius) + targetCenter,
        this._radius = instance.arrowRadius * targetRadius;

  final Offset _offset;
  final double _radius;
  final bool _spot;

  @override
  void paint(Canvas canvas, Size size) {
    // TODO make sure we don't exceed size?
    Paint paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Paint innerPaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    double factor = 1.7;

    canvas.drawOval(Rect.fromLTWH(_offset.dx - _radius / (factor * 2), _offset.dy, _radius / factor, _radius), innerPaint);
    canvas.drawOval(Rect.fromLTWH(_offset.dx - _radius / (factor * 2), _offset.dy - _radius, _radius / factor, _radius), innerPaint);

    canvas.drawOval(Rect.fromLTWH(_offset.dx, _offset.dy - _radius / (factor * 2), _radius, _radius / factor), innerPaint);
    canvas.drawOval(Rect.fromLTWH(_offset.dx - _radius, _offset.dy - _radius / (factor * 2), _radius, _radius / factor), innerPaint);

    canvas.drawCircle(_offset, _radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
