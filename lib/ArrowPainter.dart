import 'package:flutter/material.dart';
import 'ScoreInstance.dart';
import 'dart:math';

class ArrowPainter extends CustomPainter {
  ArrowPainter.fromInstance(ScoreInstance instance, Offset targetCenter, double targetRadius, this._dropOffset, this._isDragged)
      : this._offset = instance.getCartesianCoordinates(targetRadius) + targetCenter,
        this._radius = instance.relativeArrowRadius * targetRadius {
    this._text = instance.getLabel();
  }

  final Offset _offset;
  final double _radius;
  String _text;
  bool _isDragged = true;
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
      ..strokeWidth = _radius / 2
      ..style = PaintingStyle.stroke;

    double factor = 3.3;
    double wingRadius = -_dropOffset.dy / 7; //_radius * 10;

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

    String text = _text == "-1" ? "" : _text;
    double radius = wingRadius;

    TextStyle textStyle = TextStyle(
      fontSize: 18,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    double initialAngle = 0; //-textPainter.width / 2;

    canvas.translate(_offset.dx, _offset.dy - radius); // size.width / 2, size.height / 2 - radius);

    if (initialAngle != 0) {
      final d = 2 * radius * sin(initialAngle / 2);
      final rotationAngle = _calculateRotationAngle(0, initialAngle);
      canvas.rotate(rotationAngle);
      canvas.translate(d, 0);
    }

    double angle = initialAngle;
    for (int i = 0; i < text.length; i++) {
      angle = _drawLetter(canvas, text[i], angle, radius, textStyle, textPainter);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  // thanks to https://developers.mews.com/flutter-how-to-draw-text-along-arc/
  double _drawLetter(Canvas canvas, String letter, double prevAngle, double radius, TextStyle textStyle, TextPainter textPainter) {
    textPainter.text = TextSpan(text: letter, style: textStyle);
    textPainter.layout(
      minWidth: 0,
      maxWidth: double.maxFinite,
    );

    final double d = textPainter.width * 0.8;
    final double alpha = 2 * asin(d / (2 * radius));

    final newAngle = _calculateRotationAngle(prevAngle, alpha);
    canvas.rotate(newAngle);

    textPainter.paint(canvas, Offset(0, -textPainter.height));
    canvas.translate(d, 0);

    return alpha;
  }

  double _calculateRotationAngle(double prevAngle, double alpha) => (alpha + prevAngle) / 2;
}
