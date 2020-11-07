import 'package:Wingman/ArrowInformation.dart';
import 'package:flutter/material.dart';
import 'ScoreInstance.dart';
import 'SizeConfig.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TargetPage.dart';
import 'package:Wingman/TargetPainter.dart';
import 'ArrowPainter.dart';
import 'utilities.dart';
import 'StatsPainter.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TrainingSummary extends StatefulWidget {
  TrainingSummary(this.training, {Key key}) : super(key: key);

  final TrainingInstance training;

  @override
  _TrainingSummaryState createState() => _TrainingSummaryState();
}

class _TrainingSummaryState extends State<TrainingSummary> with TickerProviderStateMixin {
  DatabaseService dbService; // = DatabaseService.old();
  List<List<ScoreInstance>> arrows;
  bool startRoutineFinished = false;
  GlobalKey _changeScoresKey = GlobalObjectKey("changeScores");
  GlobalKey _statSectionKey = GlobalObjectKey("statSection");
  bool _statSectionKeyAssigned = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    SizeConfig().init(context);
    arrows = await dbService.getFullEndsOfTraining(widget.training.id);
    startRoutineFinished = true;
    setState(() {});
  }

  void showCoachMarkFAB() {
    CoachMark coachMark = CoachMark();

    if (_changeScoresKey.currentContext == null) {
      showCoachMarkStats();
      return;
    }

    RenderBox target = _changeScoresKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(center: markRect.center, radius: markRect.longestSide * 0.7);

    coachMark.show(
      targetContext: _changeScoresKey.currentContext,
      markRect: markRect,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Tap here to edit your scores.",
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
        // Scrollable.ensureVisible(_statSectionKey.currentContext);
        if (_statSectionKey.currentContext != null) {
          RenderBox box = _statSectionKey.currentContext.findRenderObject();
          Offset position = box.localToGlobal(Offset.zero); //this is global position
          double y = position.dy - fullScreenHeight() / 2;

          _scrollController
              .animateTo(
                y + _scrollController.offset,
                duration: Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
              )
              .then((value) => showCoachMarkStats());
        }
      },
    );
  }

  void showCoachMarkStats() {
    CoachMark coachMark = CoachMark();

    if (_statSectionKey.currentContext == null) {
      return;
    }

    RenderBox target = _statSectionKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 10, height: markRect.height * 1.2);

    coachMark.show(
      targetContext: _statSectionKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "These sections contain arrow specific statistics. Low dispersion values indicate tight groups and the group center deviations (GCD) quantify the average deviation of arrow x (purple) from the other arrows (grey).",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24.0,
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

  DataCell defaultDataCell(String text, [Color c]) {
    Color color = Colors.black;
    if (c != null) {
      color = c;
    }

    return DataCell(
      Text(
        text,
        style: TextStyle(color: color, fontSize: 16),
      ),
    );
  }

  Widget scoreBlob(ScoreInstance scoreInstance) {
    Color backgroundColor;
    Color textColor = Colors.black;
    int swatchValue = 400;

    switch (scoreInstance.score) {
      case 10:
      case 9:
        backgroundColor = Colors.yellow[swatchValue];
        break;
      case 8:
      case 7:
        backgroundColor = Colors.red[swatchValue];
        break;
      case 6:
      case 5:
        backgroundColor = Colors.blue[swatchValue];
        break;
      case 4:
      case 3:
        backgroundColor = Colors.black;
        textColor = Colors.white;
        break;
      default:
        backgroundColor = Colors.white;
        break;
    }

    return Stack(
      children: [
        Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.all(Radius.circular(30))),
          ),
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                scoreInstance.displayScore(true, widget.training.indoor),
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                scoreInstance.arrowInformation == null ? "" : scoreInstance.arrowInformation.label,
                style: TextStyle(color: textColor, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataCell scoreCell(ScoreInstance scoreInstance) {
    return DataCell(
      scoreBlob(scoreInstance),
    );
  }

  Widget drawStats(Offset normGroupCenter, Offset normRestCenter, double targetRadiusScaleFactor) {
    // List<Offset> eigenvectors
    if (normGroupCenter == null || normRestCenter == null) {
      return Container();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
          painter: StatsPainter(normGroupCenter, normRestCenter, targetRadiusScaleFactor), //eigenvectors),
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxWidth,
          ),
        );
      },
    );
  }

  Widget drawArrows(List<ScoreInstance> instances, double targetRadiusScaleFactor, Color color) {
    List<Widget> arrowPainters = [];
    if (instances == null || instances.isEmpty) {
      return Container();
    }

    instances.forEach((instance) {
      arrowPainters.add(
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return CustomPaint(
              painter: ArrowPainter.fromInstanceForSummary(instance, widget.training.targetType == TargetType.TripleSpot, targetRadiusScaleFactor, color),
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxWidth,
              ),
            );
          },
        ),
      );
    });
    return Stack(
      children: arrowPainters,
    );
  }

  Widget createHitMap([ArrowInformation arrowInformation]) {
    List<ScoreInstance> mainInstances;
    List<ScoreInstance> secondaryInstances;

    if (arrowInformation == null) {
      mainInstances = allArrows(arrows);
      secondaryInstances = allArrowsExcept(arrows);
    } else {
      mainInstances = allArrows(arrows, arrowInformation.id);
      secondaryInstances = allArrowsExcept(arrows, arrowInformation.id);
    }

    if (mainInstances == null || mainInstances.isEmpty) {
      return Container();
    }

    double scaleFactor = 1.0;

    switch (widget.training.targetType) {
      case TargetType.Full:
        scaleFactor = 1.0;
        break;
      case TargetType.SingleSpot:
        scaleFactor = 2.0;
        break;
      case TargetType.TripleSpot:
        scaleFactor = 2.0;
        break;
    }

    return Container(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: [
              CustomPaint(
                painter: TargetPainter.forSummary(widget.training.targetType),
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth,
                ),
              ),
              drawArrows(secondaryInstances, scaleFactor, Colors.black12),
              drawArrows(mainInstances, scaleFactor, Colors.purple),
              drawStats(
                normGroupCenter(mainInstances, widget.training.targetDiameterCM, widget.training.targetType),
                normGroupCenter(secondaryInstances, widget.training.targetDiameterCM, widget.training.targetType),
                scaleFactor,
                //calculateConfidenceEllipse(mainInstances, 1, widget.training.targetType),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget createSummaryTable() {
    // ends, arrows
    List<DataRow> rows = [];

    if (arrows == null || arrows.isEmpty) {
      return Text("Can't find results for this training.");
    }

    int totalSum = 0;
    int endCounter = 0;

    arrows.forEach((scores) {
      // for each end
      int endSum = 0;
      endCounter++;

      List<DataCell> cells = [];

      if (widget.training.targetType == TargetType.TripleSpot) {
        scores.sort((a, b) => a.tripleSpotRadius(widget.training.targetDiameterCM).compareTo(b.tripleSpotRadius(widget.training.targetDiameterCM)));
      } else {
        scores.sort((a, b) => a.pRadius.compareTo(b.pRadius));
      }

      int endScoreCounter = 0;
      int rowScoreCounter = 0;
      int rowOfEndCounter = 0;
      int rowSum = 0;
      scores.forEach((scoreInstance) {
        // .where((element) => element.isUntouched == 0).toList()
        // for each scoreInstance in end
        rowSum += scoreInstance.score;
        endSum += scoreInstance.score;
        totalSum += scoreInstance.score;

        if (rowScoreCounter == 0) {
          // begin of new row
          String content = "";
          if (rowOfEndCounter == 0) {
            content = endCounter.toString();
          }

          cells.add(defaultDataCell(content, Colors.grey[800]));

          rowOfEndCounter++;
        }

        cells.add(scoreCell(scoreInstance));

        endScoreCounter++;
        rowScoreCounter++;

        if (endScoreCounter == scores.length && scores.length % 3 != 0) {
          for (int i = 0; i < 3 - (scores.length % 3); i++) {
            cells.add(defaultDataCell(""));
            rowScoreCounter++;
          }
        }

        if (rowScoreCounter == 3) {
          // finish row
          cells.add(defaultDataCell(rowSum.toString()));

          String endSumText = "";
          String totalSumText = "";

          // this is the last row of an end
          if ((scores.length / 3.0).ceil() - rowOfEndCounter <= 0) {
            endSumText = endSum.toString();
            totalSumText = totalSum.toString();
          }

          cells.add(defaultDataCell(endSumText));
          cells.add(defaultDataCell(totalSumText));
          rows.add(DataRow(cells: cells));

          cells = [];
          rowScoreCounter = 0;
          rowSum = 0;
        }
      });
    });

    List<DataColumn> columns = [
      DataColumn(
        label: Expanded(
          child: Text('End', textAlign: TextAlign.center, textScaleFactor: 1.3),
        ),
        numeric: true,
      ),
      DataColumn(
        label: Expanded(
          child: Text('1', textAlign: TextAlign.center, textScaleFactor: 1.3),
        ),
        numeric: false,
      ),
      DataColumn(
        label: Expanded(
          child: Text('2', textAlign: TextAlign.center, textScaleFactor: 1.3),
        ),
        numeric: false,
      ),
      DataColumn(
        label: Expanded(
          child: Text('3', textAlign: TextAlign.center, textScaleFactor: 1.3),
        ),
        numeric: false,
      ),
      DataColumn(
        label: Expanded(
          child: Text('Row\nSum', textAlign: TextAlign.center, textScaleFactor: 1.1),
        ),
        numeric: true,
      ),
      DataColumn(
        label: Expanded(
          child: Text('End\nSum', textAlign: TextAlign.center, textScaleFactor: 1.1),
        ),
        numeric: true,
      ),
      DataColumn(
        label: Expanded(
          child: Text('Total', textAlign: TextAlign.center, textScaleFactor: 1.1),
        ),
        numeric: true,
      )
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        columnSpacing: 15,
        dataRowHeight: 35,
      ),
    );
  }

  void _changeScores() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TargetPage(widget.training, arrows)),
    ).then((value) {
      startRoutineFinished = false;
      onStart();
    });
  }

  Widget emptyScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.training.title),
      ),
      body: SpinKitCircle(
        color: Theme.of(context).primaryColor,
        size: 100.0,
        controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)),
      ),
    );
  }

  List<Widget> allArrowHitmaps(double radius) {
    List<Widget> hitmaps = [];
    for (var arrowInformation in allArrowInformation(arrows)) {
      hitmaps.add(createHitMap(arrowInformation));
    }
    return hitmaps;
  }

  Offset centerDeviationOfArrowWithID(int id) {
    Offset groupAvg = normGroupCenter(allArrows(arrows, id), widget.training.targetDiameterCM, widget.training.targetType);
    Offset otherAvg = normGroupCenter(allArrowsExcept(arrows, id), widget.training.targetDiameterCM, widget.training.targetType);
    return (groupAvg - otherAvg) * widget.training.targetDiameterCM;
  }

  GlobalObjectKey assignStatSectionKey() {
    if (!_statSectionKeyAssigned) {
      _statSectionKeyAssigned = true;
      return _statSectionKey;
    }
    return null;
  }

  Widget allArrowHitmapsColumn(double radius) {
    List<Widget> mainColumn = [];
    double spacerSize = screenWidth() / 20;
    _statSectionKeyAssigned = false;

    if (allArrowInformation(arrows) == null || allArrowInformation(arrows).isEmpty || allArrowInformation(arrows).contains(null)) {
      return Container();
    }

    for (var arrowInformation in allArrowInformation(arrows)) {
      List<Widget> rowChildren = [];

      mainColumn.add(SizedBox(height: 30));

      rowChildren.add(SizedBox(width: spacerSize));
      rowChildren.add(Expanded(child: createHitMap(arrowInformation)));
      rowChildren.add(SizedBox(width: spacerSize));
      rowChildren.add(Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ø Score = " +
                (allArrows(arrows, arrowInformation.id).map((e) => e.score).reduce((a, b) => a + b) / allArrows(arrows, arrowInformation.id).length).toStringAsFixed(2),
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            "2D Dispersion = " +
                rootMeanSquareDist(allArrows(arrows, arrowInformation.id)
                        .map((e) => e.getRelativeCartesianCoordinates(widget.training.targetDiameterCM, widget.training.targetType))
                        .toList())
                    .toStringAsFixed(2),
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            "↔ GCD = " + centerDeviationOfArrowWithID(arrowInformation.id).dx.toStringAsFixed(2) + "cm",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            "↕ GCD = " + centerDeviationOfArrowWithID(arrowInformation.id).dy.toStringAsFixed(2) + "cm",
            style: TextStyle(fontSize: 16),
          ), // group center deviation
        ],
      )));
      rowChildren.add(SizedBox(width: spacerSize));

      mainColumn.add(
        Column(
          key: assignStatSectionKey(),
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Arrow " + arrowInformation.label + " Hitmap",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
            SizedBox(height: 5),
            SizedBox(width: spacerSize),
            Row(
              children: rowChildren,
            ),
          ],
        ),
      );
    }
    return Column(children: mainColumn);
  }

  Widget createStatistics() {
    if (allArrows(arrows).isEmpty) {
      return Container();
    }

    return Column(
      children: [
        SizedBox(height: 30),
        Text(
          "Statistics",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "Hitmap of all arrows",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        SizedBox(height: 5),
        Row(
          children: [
            SizedBox(width: 20),
            Expanded(child: createHitMap()),
            SizedBox(width: 20),
          ],
        ),
        allArrowHitmapsColumn(150)
      ],
    );
  }

  Widget showContent() {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.training.title),
            actions: <Widget>[
              // action button
              IconButton(
                icon: Icon(Icons.help),
                onPressed: () {
                  showCoachMarkFAB();
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.7,
                center: Alignment.bottomRight,
                colors: [
                  Colors.grey[100],
                  Colors.grey[200],
                  Colors.grey[400],
                ],
                stops: [0.0, 0.5, 1.0], //[0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Score Table",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    createSummaryTable(),
                    createStatistics(),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            key: _changeScoresKey,
            onPressed: _changeScores,
            tooltip: 'Change Scores',
            child: Icon(Icons.assignment),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (startRoutineFinished) {
      return showContent();
    }

    return emptyScreen(context);
  }
}
