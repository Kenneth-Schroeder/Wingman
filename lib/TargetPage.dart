import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'ScoreInstance.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TargetPainter.dart';
import 'ArrowPainter.dart';
import 'SizeConfig.dart';
import 'dart:math';
import 'CompetitionSimulator.dart';
import 'ArrowInformation.dart';
import 'utilities.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'StatsPainter.dart';

class TargetPage extends StatefulWidget {
  TargetPage(this.training, this.arrows, {Key key}) : super(key: key);

  final TrainingInstance training;
  List<List<ScoreInstance>> arrows;

  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> with TickerProviderStateMixin {
  List<List<ScoreInstance>> arrows;
  Offset arrowTopPosition;
  Offset arrowBotPosition;

  Offset targetCenter;
  double targetRadius;
  int _draggedArrow = -1;
  List<ArrowInformation> arrowInformation = [];

  int endIndex = 0;

  double _previousScaleFactor = 1.0;
  double _scaleFactor = 1.0;
  double _initialScaleFactor = 1.0;
  Offset _initialScaleCenter = Offset(0, 0);
  Offset _scaleCenterOffset = Offset(0, 0);
  Offset _scaleCenterDelta = Offset(0, 0);
  Offset _targetCenterOffset = Offset(0, 0);

  double _groupPerimeter = 0;
  double _2dDispersion = 0;

  DatabaseService dbService;
  CompetitionSimulator simulator;
  List<Archer> opponents;
  bool sortAscending = false;
  int sortColumnIndex = 2;
  int numberOfUntouchedArrows;
  int numOpponents = 5;
  List<int> currentMatchPoints = [0, 0];
  bool startRoutineFinished = false;
  bool dragScrollIsExpanded = false;
  bool _showOverlayStatistics = false;

  AnimationController _animationController;
  Animation<double> _animation;
  bool animationOn = false;

  GlobalKey _targetKey = GlobalObjectKey("target");
  GlobalKey _draggableSheetKey = GlobalObjectKey("draggableSheet");
  GlobalKey _resetArrowsKey = GlobalObjectKey("resetArrows");
  GlobalKey _deleteEndKey = GlobalObjectKey("deleteEnd");

  @override
  void initState() {
    super.initState();
    //arrows = List.from(widget.arrows);
    arrows = widget.arrows.map((end) => end.map((score) => score.clone()).toList()).toList();

    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this, value: 0.1);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.decelerate);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationOn = false;
        _animationController.reset();
        setState(() {});
      }
    });

    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    SizeConfig().init(context);

    arrowTopPosition = Offset(screenWidth() / 10, screenHeight() * 4 / 12);
    arrowBotPosition = Offset(screenWidth() / 10, screenHeight() * 8 / 12);

    arrowInformation = await dbService.getArrowInformationToTraining(widget.training.id);

    switch (widget.training.targetType) {
      case TargetType.Full:
        targetCenter = screenThreeSideCenter();
        _scaleFactor = 1.0;
        break;
      case TargetType.SingleSpot:
        targetCenter = screenThreeSideCenter();
        _scaleFactor = 1.7;
        break;
      case TargetType.TripleSpot:
        targetCenter = screenCenter();
        _scaleFactor = 0.8;
        break;
    }

    targetRadius = minScreenDimension() / 2.2;

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
          String name = "Rival " + (i + 1).toString().padLeft(2, '0');
          opponents.add(Archer(name));
          dbService.addOpponent(widget.training.id, name);
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

  void showCoachMarkArrowInstance() {
    if (arrows[endIndex][0].isUntouched == 0 || _targetKey.currentContext == null) {
      showCoachMarkTarget();
      return;
    }

    CoachMark coachMark = CoachMark();

    Rect markRect = Rect.fromCircle(
      center: arrowTopPosition + screenAppBarHeight(),
      radius: minScreenDimension() / 22.0,
    );

    coachMark.show(
      targetContext: _targetKey.currentContext,
      markRect: markRect,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Drag arrows to place them onto the target.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
      onClose: () {
        showCoachMarkTarget();
      },
    );
  }

  void showCoachMarkTarget() {
    CoachMark coachMark = CoachMark();

    if (_targetKey.currentContext == null) {
      showCoachMarkTopControls();
      return;
    }

    Rect markRect = Rect.fromCircle(
      center: draggedTargetCenter() + screenAppBarHeight(),
      radius: scaledTargetRadius(),
    );

    coachMark.show(
      targetContext: _targetKey.currentContext,
      markRect: markRect,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Pinch with two fingers to zoom onto the target.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
      onClose: () {
        showCoachMarkTopControls();
      },
    );
  }

  void showCoachMarkDraggableSheet() {
    CoachMark coachMark = CoachMark();

    if (_draggableSheetKey.currentContext == null) {
      return;
    }

    RenderBox target = _draggableSheetKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 10, height: markRect.height * 1.3);

    coachMark.show(
      targetContext: _draggableSheetKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Drag up or tap this handle to reveal additional information.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
    );
  }

  void showCoachMarkTopControls() {
    CoachMark coachMark = CoachMark();

    if (_resetArrowsKey.currentContext == null || _deleteEndKey.currentContext == null) {
      showCoachMarkDraggableSheet();
      return;
    }

    RenderBox resetButton = _resetArrowsKey.currentContext.findRenderObject();
    RenderBox deleteButton = _deleteEndKey.currentContext.findRenderObject();

    Rect markRectResetButton = resetButton.localToGlobal(Offset.zero) & resetButton.size;
    Rect markRectDeleteButton = deleteButton.localToGlobal(Offset.zero) & resetButton.size;
    double radius = markRectResetButton.longestSide * 0.6;
    Rect result = Rect.fromPoints(markRectResetButton.center - Offset(radius, radius * 0.8), markRectDeleteButton.center + Offset(radius, radius * 0.8));

    coachMark.show(
      targetContext: _resetArrowsKey.currentContext,
      markRect: result,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          result,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Use these buttons to reset or delete all arrows of the current end.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
      onClose: () {
        showCoachMarkDraggableSheet();
      },
    );
  }

  Offset arrowDropOffset() {
    return Offset(0, -fullScreenHeight() / 6);
  }

  int countNumberOfUntouchedArrows([int index]) {
    if (index == null) {
      return arrows[endIndex].where((element) => element.isUntouched == 1).length;
    }
    return arrows[index].where((element) => element.isUntouched == 1).length;
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
    return CustomPaint(key: _targetKey, painter: TargetPainter(draggedTargetCenter(), scaledTargetRadius(), widget.training.targetType));
  }

  Widget statisticsOverlay() {
    if (!_showOverlayStatistics || _draggedArrow != -1) {
      return Container();
    }

    Offset groupCenter = normGroupCenter(allArrows([arrows[endIndex]]), scaledTargetRadius(), widget.training.targetType);

    if (normGroupCenter == null) {
      return Container();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
          painter: StatsPainter.fromTargetLocation(
              groupCenter, draggedTargetCenter(), scaledTargetRadius(), calculateConfidenceEllipse(arrows[endIndex], scaledTargetRadius(), widget.training.targetType)),
        );
      },
    );
  }

  int _touchedArrowIndex(double x, double y) {
    // determine distance to all arrows and return arrow with lowest dist IF within radius
    double touchPRadius = localCartesianToRelativePolar(draggedTargetCenter(), x, y)[0];
    double touchPAngle = localCartesianToRelativePolar(draggedTargetCenter(), x, y)[1];

    List<double> distances = [];
    for (int i = 0; i < arrows[endIndex].length; i++) {
      distances.add(polarDistance(touchPRadius, touchPAngle, arrows[endIndex][i].pRadius * targetRadius * _scaleFactor, arrows[endIndex][i].pAngle));
    }

    // todo pretty much hardcoded /27 or /15 same as in arrowpainter
    if (argMin(distances)[0] <= minScreenDimension() / 15.0) {
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

  int getEndScore(int endIdx) {
    int score = 0;
    arrows[endIdx].forEach((arrow) {
      score += arrow.score;
    });
    return score;
  }

  List<int> getMatchPoints() {
    List<int> points = [0, 0];
    int untouchedEndDecrease = 0;

    if (opponents == null || widget.training.competitionType != CompetitionType.finals) {
      return points;
    }

    if (countNumberOfUntouchedArrows(endIndex) == arrows[endIndex].length) {
      // dont count the current end
      untouchedEndDecrease = 1;
    }

    for (int i = 0; i < opponents[0].endScores.length - untouchedEndDecrease; i++) {
      // check if end has an untouched arrow, then stop here and dont allow clicking next if an arrow is not placed
      if (countNumberOfUntouchedArrows(i) > 0) {
        break;
      }

      if (i == 5) {
        Random random = Random();
        if (opponents[0].endScores[i] < getEndScore(i)) {
          points[0] += 1;
        } else if (opponents[0].endScores[i] > getEndScore(i)) {
          points[1] += 1;
        } else {
          if (random.nextBool()) {
            points[0] += 1;
          } else {
            points[1] += 1;
          }
        }
      } else if (opponents[0].endScores[i] < getEndScore(i)) {
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
    if (widget.training.competitionType == CompetitionType.finals && (currentMatchPoints[0] >= 6 || currentMatchPoints[1] >= 6)) {
      return true;
    }
    return false;
  }

  Widget winDisplay() {
    if (gameOver()) {
      String text = "DEFEAT";
      if (currentMatchPoints[0] > currentMatchPoints[1]) {
        text = "VICTORY";
      }

      return Text(
        text,
        style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    return SizedBox(
      height: 0,
      width: 0,
    );
  }

  Widget matchPointsDisplay() {
    Widget w = Container();

    if (widget.training.competitionType == CompetitionType.finals) {
      w = Container(
        height: 50,
        child: Center(
          child: Column(
            children: [
              Text(
                currentMatchPoints[0].toString() + " vs " + currentMatchPoints[1].toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              winDisplay(),
            ],
          ),
        ),
      );
    }

    return w;
  }

  Widget _scoreOverlayAnimation() {
    if (!animationOn || widget.training.competitionType != CompetitionType.finals) {
      return Container();
    }

    return Container(
      color: Colors.black87,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentMatchPoints[0].toString() + " vs " + currentMatchPoints[1].toString(),
                  textScaleFactor: 5.0,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                winDisplay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void arrowReleasedAction() {
    if (widget.training.competitionType == CompetitionType.training) return;

    int newUntouchedArrows = countNumberOfUntouchedArrows();
    if (newUntouchedArrows < numberOfUntouchedArrows && opponents[0].arrowScores[endIndex].length < numArrowsForEnd(endIndex)) {
      // add new arrow to opponents scores
      for (int i = 0; i < numOpponents; i++) {
        int score = simulator.getScore();
        opponents[i].arrowScores[endIndex].add(score);
        opponents[i].addToEnd(endIndex, score);
      }
    }

    if (newUntouchedArrows == 0) {
      // all arrows placed
      currentMatchPoints = getMatchPoints();
      animationOn = true;
      _animationController.forward();
      setState(() {});
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
      label: Text(
        text,
        textAlign: TextAlign.right,
      ),
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
    if (widget.training.competitionType == CompetitionType.training) {
      return Container();
    }

    if (opponents[0].endScores.length <= endIndex || opponents[0].arrowScores[endIndex].length == 0) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.all(10),
        child: Center(
          child: Text(
            "< Opponent scores will be displayed here after you record your results >",
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      );
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
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            child: DataTable(
              columns: columns,
              rows: rows,
              sortAscending: sortAscending,
              sortColumnIndex: sortColumnIndex,
              columnSpacing: 15,
              dataRowHeight: 25,
            ),
            scrollDirection: Axis.horizontal,
          ),
        ),
      ),
    );
  }

  void setUntouchedArrowsPosition() {
    for (int endIdx = 0; endIdx < arrows.length; endIdx++) {
      for (int i = 0; i < arrows[endIdx].length; i++) {
        if (arrows[endIdx][i].isUntouched == 1) {
          // arrow.moveWithScale(scaleDelta, -_scaleCenterDelta, scaledTargetRadius());
          Offset position;
          if (arrows[endIdx].length == 1) {
            position = arrowBotPosition;
          } else {
            position = arrowTopPosition + ((arrowBotPosition - arrowTopPosition) / (arrows[endIdx].length.toDouble() - 1.0)) * i.toDouble();
          }
          arrows[endIdx][i].setWithGlobalCartesianCoordinates(position, scaledTargetRadius(), draggedTargetCenter());
        }
      }
    }
  }

  Widget loadArrows(BuildContext context) {
    List<CustomPaint> arrowPainters = [];
    for (int i = 0; i < arrows[endIndex].length; i++) {
      arrowPainters.add(
        CustomPaint(
          painter: ArrowPainter.fromInstance(arrows[endIndex][i], draggedTargetCenter(), scaledTargetRadius(), arrowDropOffset(), i == _draggedArrow,
              _draggedArrow != -1 && i != _draggedArrow && arrows[endIndex][i].isUntouched == 0),
          child: Container(),
        ),
      );
    }

    return XGestureDetector(
      doubleTapTimeConsider: 300,
      longPressTimeConsider: 350,
      //onTap: onTap,
      //onDoubleTap: onDoubleTap,
      //onLongPress: onLongPress,
      onMoveStart: (pointer, localPos, position) {
        _draggedArrow = _touchedArrowIndex(localPos.dx, localPos.dy);
        if (_draggedArrow != -1 && arrows[endIndex][_draggedArrow].isLocked == 1) {
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('This arrow is locked.')));
        }
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
        _previousScaleFactor = _scaleFactor;
        _scaleFactor = scale * _initialScaleFactor;
        Offset newScaleCenterOffset = _initialScaleCenter - changedFocusPoint;
        _scaleCenterDelta = _scaleCenterOffset - newScaleCenterOffset;
        _scaleCenterOffset = newScaleCenterOffset;

        double scaleDelta = _scaleFactor / _previousScaleFactor;
        Offset scaleCenterTargetCenterVector = draggedTargetCenter() - changedFocusPoint;
        Offset scaleCenterTargetCenterVectorDelta = scaleCenterTargetCenterVector * (scaleDelta - 1);

        _targetCenterOffset += scaleCenterTargetCenterVectorDelta;
        _targetCenterOffset += _scaleCenterDelta;
        setState(() {});
      },
      onScaleEnd: () {
        _scaleCenterOffset = Offset(0, 0);
      },
      bypassTapEventOnDoubleTap: false,
      child: Stack(
        children: arrowPainters,
      ),
    );
  }

  void resetArrows(BuildContext context) {
    // i want to keep reset, mainly when editing middle ends
    if (arrows[endIndex].any((element) => element.isLocked == 1)) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('This end is locked.')));
      return;
    }

    arrows[endIndex].forEach((element) {
      element.reset();
    });

    if (widget.training.competitionType != CompetitionType.training) {
      // resetting in the middle of all the ends is fine here, since the end will be locked until all arrows are placed again...
      resetOpponentsEnd();
      currentMatchPoints = getMatchPoints();
    }
    setState(() {});
  }

  void resetOpponentsEnd() {
    for (int i = 0; i < numOpponents; i++) {
      opponents[i].arrowScores[endIndex] = [];
      opponents[i].endScores[endIndex] = 0;
    }
  }

  void deleteEnd(BuildContext context) async {
    if (arrows[endIndex].any((element) => element.isLocked == 1)) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('This end is locked.')));
      return;
    }

    if (arrows.length <= 1 || widget.training.competitionType != CompetitionType.training) {
      // do just a reset if its not training or only one end left
      resetArrows(context);
      return;
    }

    // if its training and there are multiple ends, just delete
    int endID = arrows[endIndex].first.endID;
    await dbService.deleteEnd(endID);
    arrows.removeAt(endIndex);

    // update current end
    endIndex = max(0, endIndex - 1);
    setState(() {});
  }

  void lockArrowsIfFinal() {
    if (widget.training.competitionType == CompetitionType.finals) {
      for (var arrow in arrows.last) {
        arrow.lock();
      }
    }
  }

  void nextRound(BuildContext context) async {
    if (countNumberOfUntouchedArrows() > 0) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('Please place all arrows before continuing.')));
      return;
    }

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
      lockArrowsIfFinal();
      // create new
      await dbService.updateAllEndsOfTraining(widget.training, arrows);

      int endID = await dbService.addEnd(widget.training.id);
      await dbService.addDefaultScores(endID, numArrowsForEnd(endIndex), widget.training.relativeArrowWidth(), arrowInformation);

      // just load all again and we are good
      arrows = await dbService.getFullEndsOfTraining(widget.training.id);
      assert(arrows.length != 0);

      setUntouchedArrowsPosition();
      numberOfUntouchedArrows = countNumberOfUntouchedArrows();
      endFinishedAction();
      setState(() {});
      return;
    }

    endIndex--;
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
    startRoutineFinished = false;
    setState(() {});
    if (opponents != null) {
      await dbService.updateAllOpponents(widget.training.id, opponents);
    }
    return await dbService.updateAllEndsOfTraining(widget.training, arrows);
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

  // todo fix error when clicking next round too fast
  double getGroupPerimeter(double physicalTargetDiameter) {
    // all arrows to Offsets
    List<Offset> arrowOffsets = [];

    // arrows[endIndex]
    allArrows([arrows[endIndex]]).forEach((arrow) {
      arrowOffsets.add(arrow.getRelativeCartesianCoordinates(physicalTargetDiameter / 2, widget.training.targetType));
    });

    if (arrowOffsets.isEmpty) {
      return 0.0;
    }

    return chPerimeter(convexHull(arrowOffsets));
  }

  int _numberOfEnds() {
    if (widget.training.numberOfEnds == 0) {
      return arrows.length;
    }

    return widget.training.numberOfEnds;
  }

  Widget _quickStats() {
    return Container(
      height: 95,
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
              width: screenWidth(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("End Score: " + getEndScore(endIndex).toString(), style: TextStyle(fontSize: 16)),
                    SizedBox(height: 1),
                    Text("Total: " + getTotalScore().toString(), style: TextStyle(fontSize: 16)),
                    SizedBox(height: 3),
                    FlatButton(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      height: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.blue[800]),
                      ),
                      child: Text(
                        "TOGGLE OVERLAY",
                        style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                      ),
                      onPressed: () {
                        _showOverlayStatistics = !_showOverlayStatistics;
                        setState(() {});
                      },
                    ),
                  ],
                ),
                SizedBox(width: 15),
                Column(
                  children: [
                    Text("End Average: " + getEndAverage().toStringAsFixed(2), style: TextStyle(fontSize: 16)),
                    SizedBox(height: 1),
                    Text("Perimeter: " + _groupPerimeter.toStringAsFixed(2) + "cm", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 3),
                    Text(
                      "2D Dispersion = " + _2dDispersion.toStringAsFixed(2),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Icon forwardButtonIcon() {
    if (endIndex + 1 >= arrows.length && !gameOver() && (arrows.length < widget.training.numberOfEnds || widget.training.numberOfEnds == 0)) {
      // make it add button
      return Icon(Icons.add);
    }

    return Icon(Icons.navigate_next);
  }

  Text forwardButtonText() {
    if (endIndex + 1 >= arrows.length && !gameOver() && (arrows.length < widget.training.numberOfEnds || widget.training.numberOfEnds == 0)) {
      // make it add button
      return Text("Add End");
    }

    return Text("Next");
  }

  Widget _bottomBar(BuildContext context) {
    if (_draggedArrow == -1) {
      _groupPerimeter = getGroupPerimeter(widget.training.targetDiameterCM); // todo remove hardcoding here and further down
      _2dDispersion = rootMeanSquareDist(
          allArrows([arrows[endIndex]]).map((e) => e.getRelativeCartesianCoordinates(widget.training.targetDiameterCM, widget.training.targetType)).toList());
    }

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
                forwardButtonIcon(),
                forwardButtonText(),
              ],
            ),
            onPressed: () {
              nextRound(context);
            },
          ),
        ],
      ),
    );
  }

  double _dragScrollSheetMaxSize() {
    if (widget.training.competitionType == CompetitionType.training) {
      return (95 + 55) / screenHeight();
    }

    return 0.5;
  }

  double _dragScrollSheetInitialSize() {
    if (dragScrollIsExpanded) {
      return _dragScrollSheetMaxSize();
    }

    return 25 / screenHeight();
  }

  Widget sheetItemWrapper(Widget child, bool enabled, Color backgroundColor, Color borderColor) {
    if (!enabled) {
      return Container();
    }

    return Container(
      //padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
      margin: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          width: 10.0,
          color: borderColor,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: child,
      ),
    );
  }

  Widget _dragScrollSheet() {
    return DraggableScrollableSheet(
        key: Key(dragScrollIsExpanded.toString()),
        initialChildSize: _dragScrollSheetInitialSize(),
        maxChildSize: _dragScrollSheetMaxSize(),
        minChildSize: 25 / screenHeight(),
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Container(
              color: Colors.blue[800],
              height: screenHeight() * _dragScrollSheetMaxSize(),
              child: Column(
                children: [
                  GestureDetector(
                    child: Container(
                      key: _draggableSheetKey,
                      height: 25,
                      color: Colors.blue[800],
                      child: Center(
                        child: Icon(
                          Icons.arrow_drop_up,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onTap: () {
                      dragScrollIsExpanded = !dragScrollIsExpanded;
                      setState(() {});
                    },
                  ),
                  Container(
                    height: screenHeight() * _dragScrollSheetMaxSize() - 25, // -25 1.5 creates bottom border
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          sheetItemWrapper(_quickStats(), true, Colors.white, Colors.white),
                          sheetItemWrapper(matchPointsDisplay(), widget.training.competitionType == CompetitionType.finals, Colors.red[300], Colors.red[300]),
                          sheetItemWrapper(_opponentStats(), widget.training.competitionType != CompetitionType.training, Colors.white, Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget emptyScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Score Recording")),
      body: SpinKitCircle(
        color: Theme.of(context).primaryColor,
        size: 100.0,
        controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)),
      ),
    );
  }

  Widget showContent(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Score Recording"),
          actions: <Widget>[
            // action button
            IconButton(
              icon: Icon(Icons.help),
              onPressed: () {
                showCoachMarkArrowInstance();
              },
            ),
            Builder(
              builder: (context) => IconButton(
                key: _resetArrowsKey,
                icon: Icon(Icons.undo),
                onPressed: () => resetArrows(context),
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                key: _deleteEndKey,
                icon: Icon(Icons.delete),
                onPressed: () => deleteEnd(context),
              ),
            ),
          ],
        ),
        body: Builder(
          builder: (context) => Stack(
            children: [createTarget(), loadArrows(context), statisticsOverlay(), _dragScrollSheet(), _scoreOverlayAnimation()],
          ),
        ),
        bottomNavigationBar: Builder(
          builder: (context) => _bottomBar(context),
        ),
      ),
      onWillPop: onLeave,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (startRoutineFinished) {
      SizeConfig().init(context);
      arrowTopPosition = Offset(screenWidth() / 10, screenHeight() * 4 / 12);
      arrowBotPosition = Offset(screenWidth() / 10, screenHeight() * 8 / 12);
      targetRadius = minScreenDimension() / 2.2;
      setUntouchedArrowsPosition();
      return showContent(context);
    }

    return emptyScreen(context);
  }
}
