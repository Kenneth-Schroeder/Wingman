import 'package:flutter/material.dart';
import 'package:fluttertraining/ScoreInstance.dart';
import 'database_service.dart';
import 'package:fluttertraining/TrainingInstance.dart';
import 'TargetPage.dart';

class TrainingSummary extends StatefulWidget {
  TrainingSummary(this.training, {Key key}) : super(key: key) {}

  final TrainingInstance training;

  @override
  _TrainingSummaryState createState() => _TrainingSummaryState();
}

class _TrainingSummaryState extends State<TrainingSummary> {
  DatabaseService dbService; // = DatabaseService.old();
  Map<int, List<ScoreInstance>> scoresByEnd = Map<int, List<ScoreInstance>>();

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    scoresByEnd = await dbService.getFullEndsOfTraining(widget.training.id);
    setState(() {});
  }

  Widget createSummaryTable() {
    // ends, arrows
    List<DataRow> rows = [];

    if (scoresByEnd == null || scoresByEnd.isEmpty) {
      return Text("Can't find results for this training.");
    }

    int totalSum = 0;
    int endCounter = 0;

    scoresByEnd.forEach((key, value) {
      // for each end
      int endSum = 0;
      endCounter++;

      List<DataCell> cells = [];

      value.sort((b, a) => a.score.compareTo(b.score));

      int rowScoreCounter = 0;
      int rowOfEndCounter = 0;
      int rowSum = 0;
      value.forEach((scoreInstance) {
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

          cells.add(
            DataCell(
              Text(
                content,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );

          rowOfEndCounter++;
        }

        cells.add(
          DataCell(
            Text(
              scoreInstance.score.toString(),
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
        // TODO add more of these cells if there aren't enough to fill the row

        rowScoreCounter++;

        if (rowScoreCounter == 3) {
          // finish row
          cells.add(
            DataCell(
              Text(
                rowSum.toString(),
                style: TextStyle(fontSize: 16),
              ),
            ),
          );

          String endSumText = "";
          String totalSumText = "";

          // this is the last row of an end
          if ((value.length / 3.0).ceil() - rowOfEndCounter <= 0) {
            endSumText = endSum.toString();
            totalSumText = totalSum.toString();
          }

          cells.add(
            DataCell(
              Text(
                endSumText,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );

          cells.add(
            DataCell(
              Text(
                totalSumText,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );

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
        label: Text('Row Sum'),
        numeric: true,
      ),
      DataColumn(
        label: Text('End Sum'),
        numeric: true,
      ),
      DataColumn(
        label: Text('Total'),
        numeric: true,
      )
    ];

    MediaQueryData _mediaQueryData = MediaQuery.of(context);

    return ListView(
      children: <Widget>[
        SingleChildScrollView(
          child: DataTable(
            columns: columns,
            rows: rows,
            columnSpacing: 1,
            dataRowHeight: _mediaQueryData.size.height / 25,
          ),
        )
      ],
    );
  }

  void _changeScores() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TargetPage(widget.training, scoresByEnd)),
    ).then((value) => onStart());
  }

  @override
  Widget build(BuildContext context) {
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
}
