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
  DatabaseService dbService = DatabaseService();
  Map<int, List<ScoreInstance>> scoresByEnd = Map<int, List<ScoreInstance>>();

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    scoresByEnd = await dbService.getFullEndsOfTraining(widget.training.id);
    setState(() {});
  }

  Widget createSummaryTable() {
    // ends, arrows
    List<DataRow> rows = [];

    if (scoresByEnd == null || scoresByEnd.isEmpty) {
      return Text("NOTHING");
    }

    scoresByEnd.forEach((key, value) {
      List<DataCell> cells = [];
      cells.add(DataCell(Text(
        key.toString(),
        style: TextStyle(color: Colors.grey, fontSize: 14),
      )));

      value.forEach((scoreInstance) {
        cells.add(DataCell(Text(
          scoreInstance.score.toString(),
          style: TextStyle(fontSize: 16),
        )));
      });

      cells.add(DataCell(Text(
        "SUM",
        style: TextStyle(fontSize: 16),
      )));

      cells.add(DataCell(Text(
        "TOTAL",
        style: TextStyle(fontSize: 16),
      )));

      rows.add(DataRow(cells: cells));
    });

    List<DataColumn> columns = [
      DataColumn(label: Text('Nr.')),
      DataColumn(label: Text('1')),
      DataColumn(label: Text('2')),
      DataColumn(label: Text('3')),
      DataColumn(label: Text('Row Sum')),
      DataColumn(label: Text('Total'))
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
      MaterialPageRoute(builder: (context) => TargetPage(widget.training)),
    );
  }

  void _testingEndsInDB() async {
    final int id1 = await dbService.addEnd(widget.training.id);
    await dbService.addScore(ScoreInstance(id1));
    await dbService.addScore(ScoreInstance(id1));
    await dbService.addScore(ScoreInstance(id1));
    final int id2 = await dbService.addEnd(widget.training.id);
    await dbService.addScore(ScoreInstance(id2));
    await dbService.addScore(ScoreInstance(id2));
    await dbService.addScore(ScoreInstance(id2));
    final int id3 = await dbService.addEnd(widget.training.id);
    await dbService.addScore(ScoreInstance(id3));
    await dbService.addScore(ScoreInstance(id3));
    await dbService.addScore(ScoreInstance(id3));
    print("created 3 ends ...");
    print(id2.toString() + " is the id of the second end");
    print("querying all scores of the second end...");

    List<ScoreInstance> scores = await dbService.getAllScoresOfEnd(id1);
    scores.forEach((element) {
      print(element.toString());
    });
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
