import 'package:flutter/material.dart';

class TargetPainter extends CustomPainter {
  TargetPainter(this._offset, this._radius, this._spot) {}

  final Offset _offset;
  final double _radius;
  final bool _spot;

  void drawCircle(Canvas canvas, Color color, double strokeWidth, PaintingStyle style, Offset offset, double radius) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = style;

    canvas.drawCircle(offset, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // TODO make sure we don't exceed size?
    double radius = _radius;

    if (!_spot) {
      drawCircle(canvas, Colors.white, 1.0, PaintingStyle.fill, _offset, radius * 10 / 10);
      drawCircle(canvas, Colors.black, 1.0, PaintingStyle.fill, _offset, radius * 8 / 10);
      drawCircle(canvas, Colors.blue, 1.0, PaintingStyle.fill, _offset, radius * 6 / 10);

      drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 10 / 10);
      drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 9 / 10);
      drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 8 / 10);
      drawCircle(canvas, Colors.white, 1.0, PaintingStyle.stroke, _offset, radius * 7 / 10);
      drawCircle(canvas, Colors.blue, 1.0, PaintingStyle.stroke, _offset, radius * 6 / 10);
    } else {
      radius *= 2;
    }

    drawCircle(canvas, Colors.blue, 1.0, PaintingStyle.fill, _offset, radius * 5 / 10);
    drawCircle(canvas, Colors.red, 1.0, PaintingStyle.fill, _offset, radius * 4 / 10);
    drawCircle(canvas, Colors.yellow, 1.0, PaintingStyle.fill, _offset, radius * 2 / 10);

    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 5 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 4 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 3 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 2 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 1 / 10);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
