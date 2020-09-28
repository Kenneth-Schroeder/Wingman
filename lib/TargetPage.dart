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

class Archer {
  List<int> endScores = [0];
  List<List<int>> arrowScores = [[]];
  String name;
  Archer(this.name);

  void addToEnd(int endIndex, int number) {
    endScores[endIndex] += number;
  }

  int scoreOfEnd(int endIndex) {
    return endScores[endIndex];
  }

  int totalScoreUpToEnd(int endIndex) {
    return endScores.sublist(0, endIndex + 1).reduce((a, b) => a + b);
  }
}

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
  List<Archer> opponents;
  bool sortAscending = false;
  int sortColumnIndex = 2;
  int numberOfUntouchedArrows;
  int numOpponents = 10;
  List<int> currentMatchPoints = [0, 0];
  bool startRoutineFinished = false;

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

    numberOfUntouchedArrows = countNumberOfUntouchedArrows(); // has to be called before first getMatchPoints()

    if (widget.training.competitionType != CompetitionType.training) {
      simulator = CompetitionSimulator(
        widget.training.competitionType,
        widget.training.referencedGender,
        widget.training.targetType == TargetType.Full,
        widget.training.competitionLevel,
      );

      if (widget.training.competitionType == CompetitionType.finals) {
        numOpponents = 1;
      }

      if (await dbService.getAllOpponentIDs(widget.training.id).then((value) => value.length == 0)) {
        opponents = [];

        for (int i = 0; i < numOpponents; i++) {
          opponents.add(Archer(i.toString()));
          dbService.addOpponent(widget.training.id, i.toString());
        }
      } else {
        opponents = await dbService.getAllOpponents(widget.training.id);

        int len = opponents[0].arrowScores.length;
        for (int j = 0; j < arrows.length - len; j++) {
          for (int i = 0; i < numOpponents; i++) {
            opponents[i].arrowScores.add([]);
            opponents[i].endScores.add(0);
          }
        }
      }

      currentMatchPoints = getMatchPoints();
    }

    startRoutineFinished = true;

    setState(() {});
  }

  Offset arrowDropOffset() {
    return Offset(0, -_screenHeight() / 5);
  }

  int countNumberOfUntouchedArrows() {
    return arrows[endIndex].where((element) => element.isUntouched == 1).length;
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
    if (argMin(distances)[0] <= arrows[endIndex][argMin(distances)[1]].relativeArrowRadius * targetRadius * _scaleFactor * 10) {
      return argMin(distances)[1];
    }

    return -1;
  }

  int numArrowsForEnd(int endIndex) {
    if (widget.training.competitionType == CompetitionType.finals && endIndex == 5) {
      return 1;
    }

    return widget.training.arrowsPerEnd;
  }

  List<int> getMatchPoints() {
    List<int> points = [0, 0];

    if (opponents == null || numberOfUntouchedArrows == arrows[endIndex].length) {
      return points;
    }

    for (int i = 0; i < opponents[0].endScores.length; i++) {
      if (opponents[0].endScores[i] < getEndScore(i)) {
        points[0] += 2;
      } else if (opponents[0].endScores[i] > getEndScore(i)) {
        points[1] += 2;
      } else {
        points[0] += 1;
        points[1] += 1;
      }
    }

    return points;
  }

  bool gameOver() {
    if (widget.training.competitionType == CompetitionType.finals && currentMatchPoints[0] >= 6 || currentMatchPoints[1] >= 6) {
      return true;
    }
    return false;
  }

  Widget matchPointsDisplay() {
    Widget w = Container();

    Widget winDisplay = Container();
    if (gameOver()) {
      String text = "DEFEAT";
      if (currentMatchPoints[0] > currentMatchPoints[1]) {
        text = "VICTORY";
      }

      winDisplay = Text(
        text,
        style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    if (widget.training.competitionType == CompetitionType.finals) {
      w = Container(
        height: _screenHeight() * 0.12,
        color: Colors.red[300],
        child: Center(
          child: Column(
            children: [
              Text(
                currentMatchPoints[0].toString() + " VS " + currentMatchPoints[1].toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              winDisplay,
            ],
          ),
        ),
      );
    }

    return w;
  }

  void arrowReleasedAction() {
    if (widget.training.competitionType == CompetitionType.training) return;

    int newUntouchedArrows = countNumberOfUntouchedArrows();
    if (newUntouchedArrows != numberOfUntouchedArrows && opponents[0].arrowScores[endIndex].length < numArrowsForEnd(endIndex)) {
      // add new arrow to opponents scores
      for (int i = 0; i < numOpponents; i++) {
        int score = simulator.getScore();
        opponents[i].arrowScores[endIndex].add(score);
        opponents[i].addToEnd(endIndex, score);
      }

      if (newUntouchedArrows == 0) {
        // all arrows placed
        currentMatchPoints = getMatchPoints();
      }
    }

    numberOfUntouchedArrows = newUntouchedArrows;
  }

  void endFinishedAction() {
    // only executed when clicking next for the first time for each end
    if (widget.training.competitionType == CompetitionType.training) return;

    for (int i = 0; i < numOpponents; i++) {
      opponents[i].arrowScores.add([]);
      opponents[i].endScores.add(0);
    }
  }

  List<Archer> getArchers() {
    List<Archer> archers = List<Archer>.from(opponents);
    archers.add(Archer("YOU"));

    archers.last.endScores[0] = getEndScore(0);
    for (int i = 1; i < arrows.length; i++) {
      archers.last.endScores.add(getEndScore(i));
    }

    switch (sortColumnIndex) {
      case 0:
        if (sortAscending) {
          archers.sort((a, b) => a.name.compareTo(b.name));
        } else {
          archers.sort((b, a) => a.name.compareTo(b.name));
        }
        break;
      case 1:
        if (sortAscending) {
          archers.sort((a, b) => a.scoreOfEnd(endIndex).compareTo(b.scoreOfEnd(endIndex)));
        } else {
          archers.sort((b, a) => a.scoreOfEnd(endIndex).compareTo(b.scoreOfEnd(endIndex)));
        }
        break;
      default:
        if (sortAscending) {
          archers.sort((a, b) => a.totalScoreUpToEnd(endIndex).compareTo(b.totalScoreUpToEnd(endIndex)));
        } else {
          archers.sort((b, a) => a.totalScoreUpToEnd(endIndex).compareTo(b.totalScoreUpToEnd(endIndex)));
        }
        break;
    }

    return archers;
  }

  void onColumnSort(columnIndex, ascending) {
    sortAscending = ascending;
    sortColumnIndex = columnIndex;
    setState(() {});
  }

  DataColumn tableColumn(String text, bool numeric) {
    return DataColumn(
      label: Text(text),
      numeric: numeric,
      onSort: onColumnSort,
    );
  }

  DataCell tableCell(String content) {
    return DataCell(
      Text(
        content,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _opponentStats() {
    if (widget.training.competitionType == CompetitionType.training ||
        opponents[0].endScores.length <= endIndex ||
        opponents[0].arrowScores[endIndex].length == 0) {
      return Container();
    }

    List<Archer> archers = getArchers();
    List<DataRow> rows = [];

    for (int i = 0; i < archers.length; i++) {
      List<DataCell> cells = [];

      cells.add(tableCell(archers[i].name));
      cells.add(tableCell(archers[i].scoreOfEnd(endIndex).toString()));
      cells.add(tableCell(archers[i].totalScoreUpToEnd(endIndex).toString()));

      rows.add(DataRow(cells: cells));
      cells = [];
    }

    List<DataColumn> columns = [
      tableColumn('Archer', false),
      tableColumn('End Score', true),
      tableColumn('Total Score', true),
    ];

    return Container(
      color: Colors.white,
      child: DataTable(
        columns: columns,
        rows: rows,
        sortAscending: sortAscending,
        sortColumnIndex: sortColumnIndex,
        columnSpacing: 25,
        dataRowHeight: 25,
      ),
    );
  }

  Widget loadArrows() {
    List<CustomPaint> arrowPainters = [];
    int counter = 0;
    arrows[endIndex].forEach((element) {
      arrowPainters.add(
        CustomPaint(
          painter:
              ArrowPainter.fromInstance(element, draggedTargetCenter(), scaledTargetRadius(), arrowDropOffset(), counter == _draggedArrow),
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
          arrows[endIndex][_draggedArrow].moveByOffset(arrowDropOffset() / _scaleFactor, targetRadius, widget.training.targetType);
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

  void deleteEnd() {
    if (arrows.length <= 1) {
      resetArrows();
      return;
    }

    int endID = arrows[endIndex].first.endID;

    arrows.removeAt(endIndex);
    dbService.deleteEnd(endID);

    endIndex = max(0, endIndex--);
    setState(() {});
  }

  void nextRound() async {
    endIndex++;

    if (endIndex < arrows.length) {
      // all good
      numberOfUntouchedArrows = countNumberOfUntouchedArrows();
      setState(() {});
      return;
    }

    if (gameOver()) {
      endIndex--; // do nothing (+-1)
      return;
    }

    if (arrows.length < widget.training.numberOfEnds || widget.training.numberOfEnds == 0) {
      // create new
      await dbService.updateAllEndsOfTraining(widget.training.id, arrows);

      int endID = await dbService.addEnd(widget.training.id);
      await dbService.addDefaultScores(endID, numArrowsForEnd(endIndex), widget.training.relativeArrowWidth());

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

      numberOfUntouchedArrows = countNumberOfUntouchedArrows();

      endFinishedAction();

      setState(() {});
    }
  }

  void prevRound() async {
    // go back if possible
    if (endIndex == 0) {
      return;
    }
    endIndex--;
    setState(() {});
  }

  Future<bool> onLeave() async {
    if (opponents != null) {
      await dbService.updateAllOpponents(widget.training.id, opponents);
    }
    return await dbService.updateAllEndsOfTraining(widget.training.id, arrows);
  }

  int getEndScore(int endIdx) {
    int score = 0;
    arrows[endIdx].forEach((arrow) {
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
      while (k >= 2 && crossProduct(ans[k - 2], ans[k - 1], points[i]) <= 0) k--;
      ans[k++] = points[i];
    }

    // Build upper hull
    for (int i = n - 1, t = k + 1; i > 0; --i) {
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
    // todo make sure to use these
    return SizeConfig.screenWidth == null ? 1 : SizeConfig.screenWidth;
  }

  double _screenHeight() {
    return SizeConfig.screenHeight == null ? 1 : SizeConfig.screenHeight;
  }

  Widget _quickStats() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Text(
            "End Statistics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
                  Text("End Score: " + getEndScore(endIndex).toString(), style: TextStyle(fontSize: 16)),
                  Text("Total: " + getTotalScore().toString(), style: TextStyle(fontSize: 16)),
                ],
              ),
              Column(
                children: [
                  Text("End Average: " + getEndAverage().toStringAsFixed(2), style: TextStyle(fontSize: 16)),
                  Text("Perimeter: " + this._groupPerimeter.toStringAsFixed(2) + " cm", style: TextStyle(fontSize: 16)),
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

  Widget _dragScrollSheetExtension() {
    return Container(
      height: _screenHeight() * 0.5,
      color: Colors.white,
    );
  }

  Widget _dragScrollSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.04,
      maxChildSize: 0.6,
      minChildSize: 0.04,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              Container(
                height: _screenHeight() * 0.045,
                color: Colors.blue[300],
                child: Center(
                  child: Icon(Icons.arrow_drop_up),
                ),
              ),
              Container(
                color: Colors.blue[300],
                child: Container(
                  //padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
                  margin: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 10.0,
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(
                    children: [_quickStats(), matchPointsDisplay(), _opponentStats(), _dragScrollSheetExtension()],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget emptyScreen() {
    return Scaffold(
      appBar: AppBar(title: Text("Score Recording")),
      body: Text("loading..."),
    );
  }

  Widget showContent() {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Score Recording"),
            actions: <Widget>[
              // action button
              IconButton(
                icon: Icon(Icons.undo),
                onPressed: resetArrows,
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: deleteEnd,
              ),
            ],
          ),
          body: Stack(
            children: [createTarget(), loadArrows(), _dragScrollSheet()],
          ),
          bottomNavigationBar: _bottomBar(),
        ),
        onWillPop: onLeave);
  }

  @override
  Widget build(BuildContext context) {
    if (startRoutineFinished) {
      return showContent();
    }

    return emptyScreen();
  }
}
