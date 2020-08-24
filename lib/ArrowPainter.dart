import 'package:flutter/material.dart';
import 'ScoreInstance.dart';

class ArrowPainter extends CustomPainter {
  ArrowPainter(this._offset, this._radius, this._spot); // TODO include default position
  ArrowPainter.fromInstance(ScoreInstance instance, this._radius, this._spot, Offset targetCenter, double targetRadius)
      : this._offset = instance.getCartesianCoordinates(targetRadius) + targetCenter;

  final Offset _offset;
  final double _radius;
  final bool _spot;

  @override
  void paint(Canvas canvas, Size size) {
    // TODO make sure we don't exceed size?
    Paint paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    canvas.drawCircle(_offset, _radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
