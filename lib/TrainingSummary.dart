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
import 'dart:math';

class TrainingSummary extends StatefulWidget {
  TrainingSummary(this.training, {Key key}) : super(key: key);

  final TrainingInstance training;

  @override
  _TrainingSummaryState createState() => _TrainingSummaryState();
}

class _TrainingSummaryState extends State<TrainingSummary> {
  DatabaseService dbService; // = DatabaseService.old();
  List<List<ScoreInstance>> arrows;
  bool startRoutineFinished = false;
  bool showHelpOverlay = false;

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
    if (normGroupCenter == null || normRestCenter == null) {
      return Container();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
          painter: StatsPainter(normGroupCenter, normRestCenter, targetRadiusScaleFactor),
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
              painter: ArrowPainter.fromInstanceForSummary(
                  instance, widget.training.targetType == TargetType.TripleSpot, targetRadiusScaleFactor, color),
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
      mainInstances = allArrows();
      secondaryInstances = allArrowsExcept();
    } else {
      mainInstances = allArrows(arrowInformation.id);
      secondaryInstances = allArrowsExcept(arrowInformation.id);
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
              drawStats(normGroupCenter(mainInstances), normGroupCenter(secondaryInstances), scaleFactor),
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

      scores.sort((a, b) => a.pRadius.compareTo(b.pRadius));

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

    //MediaQueryData _mediaQueryData = MediaQuery.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        columnSpacing: 25,
        dataRowHeight: 35,
      ),
    );
  }

  void _changeScores() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TargetPage(widget.training, arrows)),
    ).then((value) => onStart());
  }

  Widget emptyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.training.title),
      ),
      body: SafeArea(
        child: Text("loading..."),
      ),
    );
  }

  List<ScoreInstance> allArrows([int id]) {
    if (id != null) {
      return arrows
          .expand((element) => element)
          .toList()
          .where((element) => element.isUntouched == 0)
          .toList()
          .where((element) => element.arrowInformation.id == id)
          .toList();
    }
    return arrows.expand((element) => element).toList().where((element) => element.isUntouched == 0).toList();
  }

  List<ScoreInstance> allArrowsExcept([int id]) {
    if (id != null) {
      return arrows
          .expand((element) => element)
          .toList()
          .where((element) => element.isUntouched == 0)
          .toList()
          .where((element) => element.arrowInformation.id != id)
          .toList();
    }
    return [];
  }

  List<ArrowInformation> allArrowInformation() {
    return allArrows().map((e) => e.arrowInformation).toSet().toList();
  }

  List<Widget> allArrowHitmaps(double radius) {
    List<Widget> hitmaps = [];
    for (var arrowInformation in allArrowInformation()) {
      hitmaps.add(createHitMap(arrowInformation));
    }
    return hitmaps;
  }

  Offset normGroupCenter(List<ScoreInstance> arrows) {
    if (arrows == null || arrows.isEmpty) {
      return Offset(0, 0);
    }

    return arrows
            .map((e) => e.getRelativeCartesianCoordinates(widget.training.targetDiameterCM, widget.training.targetType))
            .reduce((a, b) => a + b) /
        arrows.length.toDouble() /
        widget.training.targetDiameterCM;
  }

  Offset centerDeviationOfArrowWithID(int id) {
    Offset groupAvg = normGroupCenter(allArrows(id));
    Offset otherAvg = normGroupCenter(allArrowsExcept(id));
    return (groupAvg - otherAvg) * widget.training.targetDiameterCM;
  }

  double rootMeanSquareDist(List<Offset> positions) {
    double meanX = positions.map((e) => e.dx).reduce((a, b) => a + b) / positions.length;
    double meanY = positions.map((e) => e.dy).reduce((a, b) => a + b) / positions.length;
    double sum = 0;

    for (Offset o in positions) {
      sum += pow(o.dx - meanX, 2) + pow(o.dy - meanY, 2);
    }
    sum = sqrt(sum / positions.length);
    return sum;
  }

  Widget allArrowHitmapsColumn(double radius) {
    List<Widget> mainColumn = [];
    double spacerSize = screenWidth() / 20;

    if (allArrowInformation() == null || allArrowInformation().isEmpty || allArrowInformation().contains(null)) {
      return Container();
    }

    for (var arrowInformation in allArrowInformation()) {
      List<Widget> rowChildren = [];

      mainColumn.add(SizedBox(
        height: 30,
      ));
      mainColumn.add(
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
      );
      mainColumn.add(SizedBox(
        height: 5,
      ));
      rowChildren.add(SizedBox(width: spacerSize));
      rowChildren.add(Expanded(child: createHitMap(arrowInformation)));
      rowChildren.add(SizedBox(width: spacerSize));
      rowChildren.add(Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ø Score = " +
                (allArrows(arrowInformation.id).map((e) => e.score).reduce((a, b) => a + b) / allArrows(arrowInformation.id).length)
                    .toStringAsFixed(2),
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "2D Dispersion = " +
                rootMeanSquareDist(allArrows(arrowInformation.id)
                        .map((e) => e.getRelativeCartesianCoordinates(widget.training.targetDiameterCM, widget.training.targetType))
                        .toList())
                    .toStringAsFixed(2),
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "↔ GCD = " + centerDeviationOfArrowWithID(arrowInformation.id).dx.toStringAsFixed(2) + "cm",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "↕ GCD = " + centerDeviationOfArrowWithID(arrowInformation.id).dy.toStringAsFixed(2) + "cm",
            style: TextStyle(fontSize: 16),
          ), // group center deviation
        ],
      )));
      rowChildren.add(SizedBox(width: spacerSize));

      mainColumn.add(Row(
        children: rowChildren,
      ));
    }
    return Column(children: mainColumn);
  }

  Widget createStatistics() {
    if (allArrows().isEmpty) {
      return Container();
    }

    return Column(
      children: [
        SizedBox(
          height: 30,
        ),
        Text(
          "Statistics",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          "Hitmap of all arrows",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        SizedBox(
          height: 5,
        ),
        Row(
          children: [
            SizedBox(
              width: 20,
            ),
            Expanded(child: createHitMap()),
            SizedBox(
              width: 20,
            ),
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
                  showHelpOverlay = true;
                  setState(() {});
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Container(
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
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
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
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _changeScores,
            tooltip: 'Change Scores',
            child: Icon(Icons.assignment),
          ),
        ),
        helpOverlay(
          "assets/images/help/summary.jpg",
          showHelpOverlay,
          () {
            showHelpOverlay = false;
            setState(() {});
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (startRoutineFinished) {
      return showContent();
    }

    return emptyScreen();
  }
}
