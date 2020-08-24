import 'package:flutter/material.dart';
import 'package:fluttertraining/ScoreInstance.dart';
import 'database_service.dart';
import 'package:fluttertraining/TrainingInstance.dart';
import 'TargetPainter.dart';
import 'ArrowPainter.dart';
import 'SizeConfig.dart';
import 'dart:math';
import 'ScoreInstance.dart';

class TargetPage extends StatefulWidget {
  TargetPage(this.training, {Key key}) : super(key: key);

  final TrainingInstance training;

  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  DatabaseService dbService = DatabaseService();
  List<ScoreInstance> arrows;

  Offset targetCenter;
  double targetRadius;
  double arrowRadius = 10;
  int _draggedArrow = -1;

  @override
  void initState() {
    super.initState();

    arrows = [
      // check if arrows exist in database
      // if not, create them here
      // then arrowpainter can take care of positioning relative to target
      ScoreInstance(0, 1),
      ScoreInstance(0, 2),
      ScoreInstance(0, 3),
    ];
  }

  Widget createTarget() {
    return CustomPaint(painter: TargetPainter(targetCenter, targetRadius, false));
  }

  double polarDistance(double r1, double a1, double r2, double a2) {
    return sqrt(r1 * r1 + r2 * r2 - 2 * r1 * r2 * cos(a1 - a2));
  }

  List argMin(List<double> numbers) {
    double minValue = double.maxFinite;
    int minIndex = 0;

    for (var i = 0; i < numbers.length; i++) {
      if (numbers[i] < minValue) {
        minValue = numbers[i];
        minIndex = i;
      }
    }

    return [minValue, minIndex];
  }

  List localCartesianToRelativePolar(double x, double y) {
    double rX = x - targetCenter.dx; // x coordinate relative to target center
    double rY = y - targetCenter.dy; // y coordinate relative to target center

    double pRadius = sqrt(rX * rX + rY * rY);
    double pAngle = atan2(rY, rX);

    return [pRadius, pAngle];
  }

  int _touchedArrowIndex(double x, double y) {
    // determine distance to all arrows and return arrow with lowest dist IF within radius
    double touchPRadius = localCartesianToRelativePolar(x, y)[0];
    double touchPAngle = localCartesianToRelativePolar(x, y)[1];

    List<double> distances = [];
    arrows.forEach(
        (arrow) => distances.add(polarDistance(touchPRadius, touchPAngle, arrow.pRadius * targetRadius, arrow.pAngle)));

    if (argMin(distances)[0] <= arrowRadius) {
      return argMin(distances)[1];
    }

    return -1;
    // return sqrt((x - arrowX) * (x - arrowX) + (y - arrowY) * (y - arrowY)) <= arrowRadius;
  }

  Widget loadArrows() {
    List<CustomPaint> arrowPainters = [];
    arrows.forEach((element) {
      arrowPainters.add(
        CustomPaint(
          painter: ArrowPainter.fromInstance(element, arrowRadius, false, targetCenter, targetRadius),
          child: Container(),
        ),
      );
    });

    return GestureDetector(
        onPanStart: (details) {
          _draggedArrow = _touchedArrowIndex(details.localPosition.dx, details.localPosition.dy);
        },
        onPanEnd: (details) {
          _draggedArrow = -1;
        },
        onPanUpdate: (details) {
          if (_draggedArrow != -1) {
            arrows[_draggedArrow].moveByOffset(details.delta, targetRadius);
            setState(() {});
          }
        },
        child: new Stack(
          children: arrowPainters,
        ));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    targetCenter = SizeConfig().threeSideCenter();
    targetRadius = SizeConfig().minDim() / 2.2;

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
