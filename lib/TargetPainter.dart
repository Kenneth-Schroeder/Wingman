import 'package:flutter/material.dart';
import 'TrainingInstance.dart';

class TargetPainter extends CustomPainter {
  TargetPainter(this._offset, this._radius, this._targetType);

  Offset _offset;
  final double _radius;
  final TargetType _targetType;

  void drawCircle(Canvas canvas, Color color, double strokeWidth, PaintingStyle style, Offset offset, double radius) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = style;

    canvas.drawCircle(offset, radius, paint);
  }

  void paintFullTarget(Canvas canvas, double radius) {
    // colored rings
    drawCircle(canvas, Colors.white, 1.0, PaintingStyle.fill, _offset, radius * 10 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.fill, _offset, radius * 8 / 10);
    drawCircle(canvas, Colors.blue, 1.0, PaintingStyle.fill, _offset, radius * 6 / 10);
    drawCircle(canvas, Colors.red, 1.0, PaintingStyle.fill, _offset, radius * 4 / 10);
    drawCircle(canvas, Colors.yellow, 1.0, PaintingStyle.fill, _offset, radius * 2 / 10);

    // separator lines
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 10 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 9 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 8 / 10);
    drawCircle(canvas, Colors.white, 1.0, PaintingStyle.stroke, _offset, radius * 7 / 10);
    drawCircle(canvas, Colors.blue, 1.0, PaintingStyle.stroke, _offset, radius * 6 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 5 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 4 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 3 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 2 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 1 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 0.5 / 10);

    // center cross
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double crossSize = radius * 0.1 / 10;

    canvas.drawLine(_offset - Offset(crossSize, 0), _offset + Offset(crossSize, 0), paint);
    canvas.drawLine(_offset - Offset(0, crossSize), _offset + Offset(0, crossSize), paint);
  }

  void paintSingleSpot(Canvas canvas, double radius) {
    // colored rings
    drawCircle(canvas, Colors.blue, 1.0, PaintingStyle.fill, _offset, radius * 5 / 10);
    drawCircle(canvas, Colors.red, 1.0, PaintingStyle.fill, _offset, radius * 4 / 10);
    drawCircle(canvas, Colors.yellow, 1.0, PaintingStyle.fill, _offset, radius * 2 / 10);

    // separator lines
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 5 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 4 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 3 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 2 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 1 / 10);
    drawCircle(canvas, Colors.black, 1.0, PaintingStyle.stroke, _offset, radius * 0.5 / 10);

    // center cross
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double crossSize = radius * 0.1 / 10;

    canvas.drawLine(_offset - Offset(crossSize, 0), _offset + Offset(crossSize, 0), paint);
    canvas.drawLine(_offset - Offset(0, crossSize), _offset + Offset(0, crossSize), paint);
  }

  void paintTripleSpot(Canvas canvas, double radius) {
    paintSingleSpot(canvas, radius);
    _offset += Offset(0, radius * 1.1);
    paintSingleSpot(canvas, radius);
    _offset -= Offset(0, radius * 1.1 * 2);
    paintSingleSpot(canvas, radius);
    _offset += Offset(0, radius * 1.1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // TODO make sure we don't exceed size?

    switch (_targetType) {
      case TargetType.Full:
        paintFullTarget(canvas, _radius);
        break;
      case TargetType.SingleSpot:
        paintSingleSpot(canvas, _radius);
        break;
      case TargetType.TripleSpot:
        paintTripleSpot(canvas, _radius);
        break;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
