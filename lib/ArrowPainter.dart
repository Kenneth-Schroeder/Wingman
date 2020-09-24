import 'package:flutter/material.dart';
import 'ScoreInstance.dart';

class ArrowPainter extends CustomPainter {
  ArrowPainter.fromInstance(
      ScoreInstance instance, Offset targetCenter, double targetRadius, this._dropOffset, this._isDragged, this._scaleFactor)
      : this._offset = instance.getCartesianCoordinates(targetRadius) + targetCenter,
        this._radius = instance.arrowRadius * targetRadius;

  final Offset _offset;
  final double _radius;
  bool _isDragged = true;
  double _scaleFactor;
  Offset _dropOffset;

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
      canvas.drawLine(_offset, _offset + _dropOffset, paint3);
      canvas.drawCircle(_offset + _dropOffset, _radius, innerPaint);
    }

    canvas.drawCircle(_offset, _radius, innerPaint);

    //canvas.drawLine(_offset, _offset + Offset(_radius, 0), paint3);

    /*
    canvas.drawLine(_offset, _offset + Offset(-1, 0) * wingRadius, paint3);
    canvas.drawLine(_offset, _offset + Offset(0.5, 0.866) * wingRadius, paint3);
    canvas.drawLine(_offset, _offset + Offset(0.5, -0.866) * wingRadius, paint3);

    canvas.drawArc(
        _offset - Offset(wingRadius, wingRadius) & Size(wingRadius * 2, wingRadius * 2),
        pi, //radians
        1.8, //radians
        false,
        paint3);
    canvas.drawArc(
        _offset - Offset(wingRadius, wingRadius) & Size(wingRadius * 2, wingRadius * 2),
        5 / 3 * pi, //radians
        1.8, //radians
        false,
        paint3);
    canvas.drawArc(
        _offset - Offset(wingRadius, wingRadius) & Size(wingRadius * 2, wingRadius * 2),
        7 / 3 * pi, //radians
        1.8, //radians
        false,
        paint3);
        */
    //canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint)

    //canvas.drawOval(
    //    Rect.fromPoints(_offset + Offset(-1, 0) * wingRadius + Offset(0, _radius / 5), _offset - Offset(0, _radius / 5)), innerPaint);

    //canvas.drawOval(
    //    Rect.fromLTWH(_offset.dx - wingRadius / (factor * 2), _offset.dy - wingRadius, wingRadius / factor, wingRadius), innerPaint);

    //canvas.drawOval(Rect.fromLTWH(_offset.dx, _offset.dy - wingRadius / (factor * 2), wingRadius, wingRadius / factor), innerPaint);
    //canvas.drawOval(
    //    Rect.fromLTWH(_offset.dx - wingRadius, _offset.dy - wingRadius / (factor * 2), wingRadius, wingRadius / factor), innerPaint);

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
