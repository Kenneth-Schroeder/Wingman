import 'package:flutter/material.dart';
import 'ScoreInstance.dart';

class ArrowPainter extends CustomPainter {
  ArrowPainter(this._offset, this._radius, this._spot); // TODO include default position
  ArrowPainter.fromInstance(
      ScoreInstance instance, this._spot, Offset targetCenter, double targetRadius, this._isDragged, this._scaleFactor)
      : this._offset = instance.getCartesianCoordinates(targetRadius) + targetCenter,
        this._radius = instance.arrowRadius * targetRadius;

  final Offset _offset;
  final double _radius;
  final bool _spot;
  bool _isDragged = true;
  double _scaleFactor;

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

    Paint paint3 = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    double factor = 3.3;
    double wingRadius = _radius * 2.5;

    if (_isDragged) {
      canvas.drawLine(_offset, _offset + Offset(0, -_radius * 6), paint3);
      canvas.drawCircle(_offset + Offset(0, -_radius * 6), _radius, innerPaint);
    }

    canvas.drawCircle(_offset, _radius, innerPaint);

    //canvas.drawLine(_offset, _offset + Offset(_radius, 0), paint3);
    canvas.drawOval(Rect.fromLTWH(_offset.dx - wingRadius / (factor * 2), _offset.dy, wingRadius / factor, wingRadius), innerPaint);
    canvas.drawOval(
        Rect.fromLTWH(_offset.dx - wingRadius / (factor * 2), _offset.dy - wingRadius, wingRadius / factor, wingRadius), innerPaint);

    canvas.drawOval(Rect.fromLTWH(_offset.dx, _offset.dy - wingRadius / (factor * 2), wingRadius, wingRadius / factor), innerPaint);
    canvas.drawOval(
        Rect.fromLTWH(_offset.dx - wingRadius, _offset.dy - wingRadius / (factor * 2), wingRadius, wingRadius / factor), innerPaint);

    canvas.drawCircle(_offset, wingRadius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
