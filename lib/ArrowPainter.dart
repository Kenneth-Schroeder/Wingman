import 'package:flutter/material.dart';

class ArrowPainter extends CustomPainter {
  ArrowPainter(this._offset, this._radius, this._spot) {}

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
