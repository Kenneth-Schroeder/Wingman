import 'package:flutter/material.dart';
import 'ScoreInstance.dart';
import 'dart:math';

class ArrowPainter extends CustomPainter {
  ArrowPainter.fromInstance(this.arrowInstance, this.targetCenter, this.targetRadius, this._dropOffset, this._isDragged, this.holeOnly) {
    this._radius = arrowInstance.relativeArrowRadius * targetRadius;
    this._text = arrowInstance.getLabel();
    this._isLocked = arrowInstance.isLocked == 1;
  }

  ArrowPainter.fromInstanceForSummary(this.arrowInstance, this.isTripleSpot, this.targetRadiusScaleFactor, this.mainColor) {
    this._text = arrowInstance.getLabel();

    this._isLocked = true;
    this._isDragged = false;
    this.displayLabels = false;
    flightScale = 0.0;
    useCanvasSize = true;
    fixedHoleSize = true;
  }

  ScoreInstance arrowInstance;
  Offset targetCenter;
  double targetRadius;
  bool displayLabels = true;
  bool isTripleSpot;
  Offset _offset;
  double _radius;
  String _text;
  bool _isDragged;
  bool _isLocked;
  Offset _dropOffset; // providing a negative dropoffset will create a circle around the arrows
  bool holeOnly = false;
  bool useCanvasSize = false;
  double targetRadiusScaleFactor = 1.0;
  Color mainColor = Colors.purple;
  double flightScale = 1.0;
  bool fixedHoleSize = false;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width != 0 && useCanvasSize) {
      this._dropOffset = Offset(0, min(size.height, size.width) / 4);
      targetCenter = Offset(size.width / 2, size.height / 2);
      targetRadius = min(size.height, size.width) / 2.0 * targetRadiusScaleFactor;
      this._radius = arrowInstance.relativeArrowRadius * targetRadius;
    }

    if (fixedHoleSize) {
      this._radius = _dropOffset.dy / 20;
    }

    if (isTripleSpot != null && isTripleSpot) {
      this._offset = arrowInstance.tripleSpotLocalRelativeCoordinates(targetRadius) + targetCenter;
    } else {
      this._offset = arrowInstance.getCartesianCoordinates(targetRadius) + targetCenter;
    }

    Paint paint = Paint()
      ..color = mainColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Paint innerPaint = Paint()
      ..color = mainColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    Paint paint3 = Paint()
      ..color = mainColor
      ..strokeWidth = _radius / 2
      ..style = PaintingStyle.stroke;

    double factor = 3.3;
    double wingRadius = -_dropOffset.dy / 7 * flightScale; //_radius * 10;

    if (_isDragged && !_isLocked) {
      canvas.drawLine(_offset, _offset + _dropOffset, paint3);
      canvas.drawCircle(_offset + _dropOffset, _radius, innerPaint);
    }

    canvas.drawCircle(_offset, _radius, innerPaint);

    Color textColor = Colors.black;
    if (holeOnly) {
      textColor = Colors.black26;
      innerPaint.color = Colors.black26;
      paint.color = Colors.black26;
      //return;
    }

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

    if (this.displayLabels) {
      String text = _text == "-1" ? "" : _text;
      double radius = wingRadius;

      TextStyle textStyle = TextStyle(
        fontSize: 18,
        color: textColor,
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

    final double pretendWidth = textPainter.width * 0.6;
    final double alpha = 2 * asin(pretendWidth / (2 * radius));

    final newAngle = _calculateRotationAngle(prevAngle, alpha);
    canvas.rotate(newAngle);

    double correction = (textPainter.width - pretendWidth) / 2.0;
    canvas.translate(-correction, 0);
    textPainter.paint(canvas, Offset(0, -textPainter.height));
    canvas.translate(correction, 0);
    canvas.translate(pretendWidth, 0);

    return alpha;
  }

  double _calculateRotationAngle(double prevAngle, double alpha) => (alpha + prevAngle) / 2;
}
