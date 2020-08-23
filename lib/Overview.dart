import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:fluttertraining/TrainingInstance.dart';
import 'TrainingSummary.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TrainingInstance> _trainings = [];
  DatabaseService dbService = DatabaseService();

  void _addTraining() {
    _createNewTraining();
    _loadTrainings();

    setState(() {});
  }

  void _createNewTraining() async {
    final training = TrainingInstance.fromMap(
        {"title": "Training", "creationTime": DateTime.now()});
    final int id = await dbService.addTraining(training);
    print(id);
  }

  void _loadTrainings() async {
    final List<TrainingInstance> trainings = await dbService.getAllTrainings();
    _trainings = trainings.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    // TODO initialize properly
    // _loadTrainings();

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView.separated(
          padding: EdgeInsets.all(8),
          itemBuilder: (BuildContext ctxt, int Index) {
            return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TrainingSummary(_trainings[Index])),
                  );
                },
                child: new Container(
                  padding: EdgeInsets.all(12.0),
                  height: 40,
                  color: Colors.purple,
                  child: Center(
                      child: Text(
                    _trainings[Index].toString(),
                    style: TextStyle(color: Colors.white),
                  )),
                ));
          },
          separatorBuilder: (BuildContext context, int index) {
            return SizedBox(
              height: 10,
            );
          },
          itemCount: _trainings.length),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTraining,
        tooltip: 'New Training',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
