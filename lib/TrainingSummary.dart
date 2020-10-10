import 'package:flutter/material.dart';
import 'ScoreInstance.dart';
import 'SizeConfig.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TargetPage.dart';

class TrainingSummary extends StatefulWidget {
  TrainingSummary(this.training, {Key key}) : super(key: key);

  final TrainingInstance training;

  @override
  _TrainingSummaryState createState() => _TrainingSummaryState();
}

class _TrainingSummaryState extends State<TrainingSummary> {
  DatabaseService dbService; // = DatabaseService.old();
  Map<int, List<ScoreInstance>> scoresByEnd = Map<int, List<ScoreInstance>>();
  bool startRoutineFinished = false;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    SizeConfig().init(context);
    scoresByEnd = await dbService.getFullEndsOfTraining(widget.training.id);
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

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.all(Radius.circular(30))),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              scoreInstance.score.toString(),
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              scoreInstance.arrowInformation == null ? "" : scoreInstance.arrowInformation.label,
              style: TextStyle(color: textColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  DataCell scoreCell(ScoreInstance scoreInstance) {
    return DataCell(
      scoreBlob(scoreInstance),
    );
  }

  Widget createSummaryTable() {
    // ends, arrows
    List<DataRow> rows = [];

    if (scoresByEnd == null || scoresByEnd.isEmpty) {
      return Text("Can't find results for this training.");
    }

    int totalSum = 0;
    int endCounter = 0;

    scoresByEnd.forEach((endID, scores) {
      // for each end
      int endSum = 0;
      endCounter++;

      List<DataCell> cells = [];

      scores.sort((b, a) => a.score.compareTo(b.score));

      int endScoreCounter = 0;
      int rowScoreCounter = 0;
      int rowOfEndCounter = 0;
      int rowSum = 0;
      scores.forEach((scoreInstance) {
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

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.7,
          center: Alignment.bottomRight,
          colors: [
            Colors.grey[100],
            Colors.grey[200],
            Colors.grey[400],
            //Colors.black45,
            //Colors.black54,
          ], //, Colors.black, Colors.white],
          stops: [0.0, 0.5, 1.0], //[0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      child: ListView(
        children: <Widget>[
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns,
                rows: rows,
                columnSpacing: 25,
                dataRowHeight: 35,
              ),
            ),
          ),
          Container(
            height: SizeConfig.screenHeight == null ? 100 : SizeConfig.screenHeight / 5,
          ),
        ],
      ),
    );
  }

  void _changeScores() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TargetPage(widget.training, scoresByEnd)),
    ).then((value) => onStart());
  }

  Widget emptyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.training.title),
      ),
      body: Text("loading..."),
    );
  }

  Widget showContent() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.training.title),
      ),
      body: createSummaryTable(),
      floatingActionButton: FloatingActionButton(
        onPressed: _changeScores,
        tooltip: 'Change Scores',
        child: Icon(Icons.assignment),
      ),
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
