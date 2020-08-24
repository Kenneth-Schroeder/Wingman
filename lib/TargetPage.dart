import 'package:flutter/material.dart';
import 'package:fluttertraining/ScoreInstance.dart';
import 'database_service.dart';
import 'package:fluttertraining/TrainingInstance.dart';
import 'TargetPainter.dart';
import 'ArrowPainter.dart';
import 'SizeConfig.dart';
import 'dart:math';

class TargetPage extends StatefulWidget {
  TargetPage(this.training, {Key key}) : super(key: key);

  final TrainingInstance training;

  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  DatabaseService dbService = DatabaseService();
  double arrowX = 20;
  double arrowY = 20;
  double arrowRadius = 10;
  bool _dragging;

  Widget createTarget() {
    SizeConfig().init(context);
    return CustomPaint(painter: TargetPainter(SizeConfig().threeSideCenter(), SizeConfig().minDim() / 2.2, false));
  }

  bool _insideArrowBounds(double x, double y) {
    return sqrt((x - arrowX) * (x - arrowX) + (y - arrowY) * (y - arrowY)) <= arrowRadius;
  }

  Widget loadArrows() {
    return GestureDetector(
      onPanStart: (details) {
        _dragging = _insideArrowBounds(
          details.localPosition.dx,
          details.localPosition.dy,
        );
      },
      onPanEnd: (details) {
        _dragging = false;
      },
      onPanUpdate: (details) {
        if (_dragging) {
          setState(() {
            arrowX += details.delta.dx;
            arrowY += details.delta.dy;
          });
        }
      },
      child: CustomPaint(
        painter: ArrowPainter(Offset(arrowX, arrowY), arrowRadius, false),
        child: Container(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Score Recording"),
      ),
      body: new Stack(
        children: [createTarget(), loadArrows()],
      ),
    );
  }
}
