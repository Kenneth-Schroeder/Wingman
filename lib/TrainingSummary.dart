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

          cells.add(defaultDataCell(content, Colors.grey));

          rowOfEndCounter++;
        }

        cells.add(
          DataCell(
            Row(
              children: [
                Text(
                  scoreInstance.score.toString(),
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  scoreInstance.arrowInformation == null ? "" : scoreInstance.arrowInformation.label, // todo dont leave it like this
                  style: TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        );

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
        label: Text('End'),
        numeric: true,
      ),
      DataColumn(
        label: Text('1'),
        numeric: true,
      ),
      DataColumn(
        label: Text('2'),
        numeric: true,
      ),
      DataColumn(
        label: Text('3'),
        numeric: true,
      ),
      DataColumn(
        label: Text('Row\nSum'),
        numeric: true,
      ),
      DataColumn(
        label: Text('End\nSum'),
        numeric: true,
      ),
      DataColumn(
        label: Text('Total'),
        numeric: true,
      )
    ];

    //MediaQueryData _mediaQueryData = MediaQuery.of(context);

    return ListView(
      children: <Widget>[
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: rows,
              columnSpacing: 25,
              dataRowHeight: 25,
            ),
          ),
        ),
        Container(
          height: SizeConfig.screenHeight == null ? 100 : SizeConfig.screenHeight / 5,
        ),
      ],
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
