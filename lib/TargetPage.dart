import 'dart:ui';
import 'package:flutter/material.dart';
import 'ScoreInstance.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TargetPainter.dart';
import 'ArrowPainter.dart';
import 'SizeConfig.dart';
import 'dart:math';
import 'CompetitionSimulator.dart';

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

  double _groupPerimeter = 0;

  DatabaseService dbService;
  CompetitionSimulator simulator;
  List<List<List<int>>> opponentsScores;
  List<List<int>> opponentsEndScores;
  int previouslyUntouchedArrows = 6;
  int numOpponents = 10;

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
    SizeConfig().init(context);

    switch (widget.training.targetType) {
      case TargetType.Full:
        targetCenter = SizeConfig().threeSideCenter();
        _scaleFactor = 1.0;
        break;
      case TargetType.SingleSpot:
        targetCenter = SizeConfig().threeSideCenter();
        _scaleFactor = 1.3;
        break;
      case TargetType.TripleSpot:
        targetCenter = SizeConfig().center();
        _scaleFactor = 0.8;
        break;
    }

    targetRadius = SizeConfig().minDim() / 2.2;

    if (widget.training.competitionType != CompetitionType.training) {
      simulator = CompetitionSimulator(
        widget.training.competitionType,
        widget.training.referencedGender,
        widget.training.targetType == TargetType.Full,
        widget.training.competitionLevel,
      );
    }

    opponentsScores = [];
    opponentsEndScores = [];
    for (int i = 0; i < numOpponents; i++) {
      opponentsScores.add([[]]);
      opponentsEndScores.add([0]);
    }

    previouslyUntouchedArrows = widget.training.arrowsPerEnd;

    setState(() {});
  }

  Offset draggedTargetCenter() {
    if (targetCenter == null) {
      return Offset(0, 0);
    }
    return targetCenter + _targetCenterOffset;
  }

  double scaledTargetRadius() {
    if (targetRadius == null) {
      return 0;
    }
    return targetRadius * _scaleFactor;
  }

  Widget createTarget() {
    return CustomPaint(painter: TargetPainter(draggedTargetCenter(), scaledTargetRadius(), widget.training.targetType));
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

  void arrowReleasedAction() {
    int newUntouchedArrows = arrows[endIndex].where((element) => element.pRadius == 1.3).length;
    if (newUntouchedArrows != previouslyUntouchedArrows && opponentsScores[0][endIndex].length < widget.training.arrowsPerEnd) {
      // add new arrow to opponents scores
      for (int i = 0; i < numOpponents; i++) {
        int score = simulator.getScore();
        opponentsScores[i][endIndex].add(score);
        opponentsEndScores[i][endIndex] += score;
      }
    }
    previouslyUntouchedArrows = newUntouchedArrows;

    switch (widget.training.competitionType) {
      case CompetitionType.training:
      case CompetitionType.qualifying:
        break;
      case CompetitionType.finals:
        break;
    }
  }

  void endFinishedAction() {
    // todo what if this is called by going back and fourth ??? cant happen i think
    for (int i = 0; i < numOpponents; i++) {
      opponentsScores[i].add([]);
      opponentsEndScores[i].add(0);
    }

    switch (widget.training.competitionType) {
      case CompetitionType.training:
        break;
      case CompetitionType.qualifying:
        //opponentScores.add(simulator.getScores(widget.training.arrowsPerEnd));
        break;
      case CompetitionType.finals:
        break;
    }
  }

  Widget _opponentStats() {
    // todo improve this
    if (opponentsScores == null ||
        widget.training.competitionType == CompetitionType.training ||
        opponentsScores[0].length <= endIndex ||
        opponentsScores[0][endIndex].length == 0) {
      return Container();
    }

    return ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(8),
        itemBuilder: (BuildContext ctxt, int index) {
          return Container(
            padding: EdgeInsets.all(5.0),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red[200],
              boxShadow: [new BoxShadow(color: Colors.grey, offset: new Offset(3.0, 2.0), blurRadius: 3.0, spreadRadius: 0.1)],
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 15,
                        //fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                            child: Text(
                          "End: " + opponentsEndScores[index][endIndex].toString(),
                          style: TextStyle(color: Colors.blue[800]),
                        )),
                      ),
                      Expanded(
                        child: Center(
                            child: Text(
                          "Total: " + opponentsEndScores[index].sublist(0, endIndex + 1).reduce((a, b) => a + b).toString(),
                          style: TextStyle(color: Colors.blue[800]),
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 8,
          );
        },
        itemCount: opponentsEndScores.length);

    /*new Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Text("Opponent Quickstats"), // TODO add quickstats
              Padding(
                padding: EdgeInsets.all(2.0),
                child: Container(
                  height: 1.0,
                  width: _screenWidth(),
                  //color: Colors.black,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text("Opponent End Score: " + opponentScores[endIndex].reduce((a, b) => a + b).toString()),
                      Text("Opponent Total: " + opponentScores.expand((element) => element).toList().reduce((a, b) => a + b).toString()),
                    ],
                  ),
                  Column(
                    children: [
                      Text("Opponent End Average: -"),
                      Text("Opponent Perimeter: - cm"),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Container(
                  height: 1.0,
                  width: _screenWidth(),
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );*/
  }

  Widget loadArrows() {
    List<CustomPaint> arrowPainters = [];
    int counter = 0;
    arrows[endIndex].forEach((element) {
      arrowPainters.add(
        CustomPaint(
          painter: ArrowPainter.fromInstance(element, draggedTargetCenter(), scaledTargetRadius(), counter == _draggedArrow, _scaleFactor),
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
              targetRadius,
              widget.training.targetType); // todo remove hardcoding
          arrows[endIndex][_draggedArrow].updateScore(widget.training.targetType, targetRadius);
        }
        _draggedArrow = -1;
        arrowReleasedAction();
        setState(() {});
      },
      onMoveUpdate: (localPos, position, localDelta, delta) {
        if (_draggedArrow != -1) {
          arrows[endIndex][_draggedArrow].moveByOffset(delta, targetRadius * _scaleFactor, widget.training.targetType);
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
    if (endIndex + 1 < arrows.length) {
      // all good
      endIndex++;
      setState(() {});
      return;
    }

    if (arrows.length < widget.training.numberOfEnds || widget.training.numberOfEnds == 0) {
      // create new
      await dbService.updateAllEndsOfTraining(widget.training.id, arrows);
      endIndex++;

      int endID = await dbService.addEnd(widget.training.id);
      await dbService.addDefaultScores(endID, widget.training.arrowsPerEnd);

      // just load all again and we are good
      Map<int, List<ScoreInstance>> allScoresMap = await dbService.getFullEndsOfTraining(widget.training.id);

      arrows = new List.generate(allScoresMap.length, (i) => []);
      int counter = 0;
      allScoresMap.forEach((key, value) {
        value.forEach((element) {
          arrows[counter].add(element);
        });
        counter++;
      });

      endFinishedAction();

      setState(() {});
    }
  }

  void prevRound() async {
    // go back if possible
    if (endIndex == 0) return;

    // await dbService.updateAllEndsOfTraining(widget.training.id, arrows);

    endIndex--;
    setState(() {});
  }

  Future<bool> onLeave() async {
    return await dbService.updateAllEndsOfTraining(widget.training.id, arrows);
  }

  int getEndScore() {
    int score = 0;
    arrows[endIndex].forEach((arrow) {
      score += arrow.score;
    });
    return score;
  }

  int getTotalScore() {
    int totalScore = 0;

    arrows.forEach((end) {
      end.forEach((arrow) {
        totalScore += arrow.score;
      });
    });

    return totalScore;
  }

  double getEndAverage() {
    int totalScore = 0;
    int numEnds = 0;

    arrows.forEach((end) {
      end.forEach((arrow) {
        totalScore += arrow.score;
      });
      numEnds += 1;
    });

    return totalScore / numEnds;
  }

  double dist(Offset pointA, Offset pointB) {
    return (pointA - pointB).distance;
  }

  double chPerimeter(List<Offset> points) {
    double p = 0;
    for (int i = 1; i < points.length; i++) {
      p += dist(points[i - 1], points[i]);
    }
    p += dist(points.first, points.last);

    return p;
  }

  double crossProduct(Offset O, Offset A, Offset B) {
    return (A.dx - O.dx) * (B.dy - O.dy) - (A.dy - O.dy) * (B.dx - O.dx);
  }

  List<Offset> convexHull(List<Offset> points) {
    int n = points.length;
    int k = 0;

    if (n <= 3) return points;

    List<Offset> ans = new List(n * 2);

    // Sort points lexicographically
    points.sort((a, b) {
      if (a == b) return 0;
      if (a.dx < b.dx || (a.dx == b.dx && a.dy < b.dy)) {
        return 1;
      }
      return -1;
    });

    // Build lower hull
    for (int i = 0; i < n; ++i) {
      // If the point at K-1 position is not a part
      // of hull as vector from ans[k-2] to ans[k-1]
      // and ans[k-2] to A[i] has a clockwise turn
      while (k >= 2 && crossProduct(ans[k - 2], ans[k - 1], points[i]) <= 0) k--;
      ans[k++] = points[i];
    }

    // Build upper hull
    for (int i = n - 1, t = k + 1; i > 0; --i) {
      // If the point at K-1 position is not a part
      // of hull as vector from ans[k-2] to ans[k-1]e
      // and ans[k-2] to A[i] has a clockwise turn
      while (k >= t && crossProduct(ans[k - 2], ans[k - 1], points[i - 1]) <= 0) k--;
      ans[k++] = points[i - 1];
    }

    // Resize the array to desired size
    return ans.getRange(0, k - 1).toList();
  }

  // todo fix error when clicking next round too fast
  double getGroupPerimeter(double physicalTargetRadius) {
    // all arrows to Offsets
    List<Offset> arrowOffsets = [];

    arrows[endIndex].forEach((arrow) {
      arrowOffsets.add(arrow.getRelativeCartesianCoordinates(physicalTargetRadius, widget.training.targetType));
    });

    return chPerimeter(convexHull(arrowOffsets));
  }

  int _numberOfEnds() {
    if (widget.training.numberOfEnds == 0) return arrows.length;

    return widget.training.numberOfEnds;
  }

  double _screenWidth() {
    return SizeConfig.screenWidth == null ? 1 : SizeConfig.screenWidth;
  }

  double _screenHeight() {
    return SizeConfig.screenHeight == null ? 1 : SizeConfig.screenHeight;
  }

  Widget _quickStats() {
    return new Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          height: _screenHeight() * 0.04,
          color: Colors.blue[300],
          child: Center(
            child: Icon(Icons.arrow_drop_up),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Text("Quickstats"), // TODO add quickstats
              Padding(
                padding: EdgeInsets.all(2.0),
                child: Container(
                  height: 1.0,
                  width: _screenWidth(),
                  //color: Colors.black,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text("End Score: " + getEndScore().toString()),
                      Text("Total: " + getTotalScore().toString()),
                    ],
                  ),
                  Column(
                    children: [
                      Text("End Average: " + getEndAverage().toStringAsFixed(2)),
                      Text("Perimeter: " + this._groupPerimeter.toStringAsFixed(2) + " cm"),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Container(
                  height: 1.0,
                  width: _screenWidth(),
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    if (_draggedArrow == -1)
      _groupPerimeter = getGroupPerimeter(widget.training.targetDiameterCM); // todo remove hardcoding here and further down

    return BottomAppBar(
      color: Colors.white,
      child: Row(
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
            "End " + (endIndex + 1).toString() + "/" + _numberOfEnds().toString(),
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
    );
  }

  Widget _dragScrollSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.04,
      maxChildSize: 0.8,
      minChildSize: 0.04,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [_quickStats(), _opponentStats()],
          ),
        );
      },
    );
  }

  /*
  SingleChildScrollView(
          controller: scrollController,
          child:
   */

  @override
  Widget build(BuildContext context) {
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
            children: [createTarget(), loadArrows(), _dragScrollSheet()],
          ),
          bottomNavigationBar: _bottomBar(),
        ),
        onWillPop: onLeave);
  }
}
