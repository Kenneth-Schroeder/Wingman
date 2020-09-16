import 'package:flutter/material.dart';
import 'package:fluttertraining/ScoreInstance.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'database_service.dart';
import 'package:fluttertraining/TrainingInstance.dart';
import 'TargetPainter.dart';
import 'ArrowPainter.dart';
import 'SizeConfig.dart';
import 'dart:math';
import 'ScoreInstance.dart';

class TargetPage extends StatefulWidget {
  TargetPage(this.training, this.scoresByEndMap, {Key key}) : super(key: key);

  final TrainingInstance training;
  Map<int, List<ScoreInstance>> scoresByEndMap;

  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  List<List<ScoreInstance>> arrows;

  Offset targetCenter;
  double targetRadius;
  int _draggedArrow = -1;

  int endIndex = 0;

  double _scaleFactor = 1.0;
  double _initialScaleFactor = 1.0;
  Offset _initialScaleCenter = Offset(0, 0);
  Offset _scaleCenterOffset = Offset(0, 0);
  Offset _scaleCenterDelta = Offset(0, 0);
  Offset _targetCenterOffset = Offset(0, 0);

  DatabaseService dbService;

  @override
  void initState() {
    super.initState();
    arrows = new List.generate(widget.scoresByEndMap.length, (i) => []);
    int counter = 0;
    widget.scoresByEndMap.forEach((key, value) {
      value.forEach((element) {
        arrows[counter].add(element);
      });
      counter++;
    });

    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    setState(() {});
  }

  Offset draggedTargetCenter() {
    return targetCenter + _targetCenterOffset;
  }

  double scaledTargetRadius() {
    return targetRadius * _scaleFactor;
  }

  Widget createTarget() {
    return CustomPaint(painter: TargetPainter(draggedTargetCenter(), scaledTargetRadius(), false));
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
    double rX = x - draggedTargetCenter().dx; // x coordinate relative to target center
    double rY = y - draggedTargetCenter().dy; // y coordinate relative to target center

    double pRadius = sqrt(rX * rX + rY * rY);
    double pAngle = atan2(rY, rX);

    return [pRadius, pAngle];
  }

  int _touchedArrowIndex(double x, double y) {
    // determine distance to all arrows and return arrow with lowest dist IF within radius
    double touchPRadius = localCartesianToRelativePolar(x, y)[0];
    double touchPAngle = localCartesianToRelativePolar(x, y)[1];

    List<double> distances = [];

    arrows[endIndex].forEach(
        (arrow) => distances.add(polarDistance(touchPRadius, touchPAngle, arrow.pRadius * targetRadius * _scaleFactor, arrow.pAngle)));

    // TODO *3 is hardcoded here
    if (argMin(distances)[0] <= arrows[endIndex][argMin(distances)[1]].arrowRadius * targetRadius * _scaleFactor * 3) {
      return argMin(distances)[1];
    }

    return -1;
  }

  Widget loadArrows() {
    List<CustomPaint> arrowPainters = [];
    int counter = 0;
    arrows[endIndex].forEach((element) {
      arrowPainters.add(
        CustomPaint(
          painter: ArrowPainter.fromInstance(
              element, false, draggedTargetCenter(), scaledTargetRadius(), counter == _draggedArrow, _scaleFactor),
          child: Container(),
        ),
      );
      counter++;
    });

    return XGestureDetector(
      doubleTapTimeConsider: 300,
      longPressTimeConsider: 350,
      //onTap: onTap,
      //onDoubleTap: onDoubleTap,
      //onLongPress: onLongPress,
      onMoveStart: (pointer, localPos, position) {
        _draggedArrow = _touchedArrowIndex(localPos.dx, localPos.dy);
      },
      onMoveEnd: (pointer, localPos, position) {
        if (_draggedArrow != -1) {
          arrows[endIndex][_draggedArrow].moveByOffset(
              Offset(0, -arrows[endIndex][_draggedArrow].arrowRadius * targetRadius * 6 * (1 / _scaleFactor + 1)),
              targetRadius); // todo remove hardcoding
        }
        _draggedArrow = -1;
        setState(() {});
      },
      onMoveUpdate: (localPos, position, localDelta, delta) {
        if (_draggedArrow != -1) {
          arrows[endIndex][_draggedArrow].moveByOffset(delta, targetRadius * _scaleFactor);
          setState(() {});
        }
      },
      onScaleStart: (initialFocusPoint) {
        _initialScaleCenter = initialFocusPoint;
        _initialScaleFactor = _scaleFactor;
      },
      onScaleUpdate: (changedFocusPoint, scale, rotation) {
        _scaleFactor = scale * _initialScaleFactor;
        Offset newScaleCenterOffset = _initialScaleCenter - changedFocusPoint;
        _scaleCenterDelta = _scaleCenterOffset - newScaleCenterOffset;
        _scaleCenterOffset = newScaleCenterOffset;
        _targetCenterOffset += _scaleCenterDelta;
        setState(() {});
        //print('onScaleUpdate - changedFocusPoint: $changedFocusPoint'); // ; scale: $scale ;Rotation: $rotation');
      },
      onScaleEnd: () {
        _scaleCenterOffset = Offset(0, 0);
      },
      bypassTapEventOnDoubleTap: false,
      child: new Stack(
        children: arrowPainters,
      ),
    );
  }

  void resetArrows() {
    arrows[endIndex].forEach((element) {
      element.reset();
    });
    setState(() {});
  }

  void nextRound() async {
    await dbService.updateAllEndsOfTraining(widget.training.id, arrows);

    // go forward and if we hit the end, create more ends...
    endIndex++;

    if (endIndex < arrows.length) {
      // all good
      setState(() {});
      return;
    }

    // create new end
    int endID = await dbService.addEnd(widget.training.id);
    await dbService.addDefaultScores(endID, widget.training.arrowsPerEnd);

    // just load all again and we are good
    Map<int, List<ScoreInstance>> SBEM = await dbService.getFullEndsOfTraining(widget.training.id);

    arrows = new List.generate(SBEM.length, (i) => []);
    int counter = 0;
    SBEM.forEach((key, value) {
      value.forEach((element) {
        arrows[counter].add(element);
      });
      counter++;
    });

    setState(() {});
  }

  void prevRound() async {
    // go back if possible
    if (endIndex == 0) return;

    await dbService.updateAllEndsOfTraining(widget.training.id, arrows);

    endIndex--;
    setState(() {});
  }

  Future<bool> onLeave() async {
    return await dbService.updateAllEndsOfTraining(widget.training.id, arrows);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    targetCenter = SizeConfig().threeSideCenter();
    targetRadius = SizeConfig().minDim() / 2.2;

    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(title: Text("Score Recording"), actions: <Widget>[
            // action button
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: resetArrows,
            ),
          ]),
          body: Stack(
            children: [createTarget(), loadArrows()],
          ),
          bottomNavigationBar: BottomAppBar(
              color: Colors.white,
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Quickstats"), // TODO add quickstats
                  new Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FlatButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.0)),
                        padding: EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.navigate_before),
                            Text("Previous"),
                          ],
                        ),
                        onPressed: prevRound,
                      ),
                      Text(
                        "End " + (endIndex + 1).toString() + "/" + arrows.length.toString(),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      FlatButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.0)),
                        padding: EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.navigate_next),
                            Text("Next"),
                          ],
                        ),
                        onPressed: nextRound,
                      ),
                    ],
                  ),
                ],
              )),
        ),
        onWillPop: onLeave);
  }
}
