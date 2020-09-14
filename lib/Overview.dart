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
  DatabaseService dbService;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    await _loadTrainings();
    setState(() {});
  }

  void _addTraining() async {
    await _createNewTraining();
    await _loadTrainings();

    setState(() {});
  }

  void _createNewTraining() async {
    final training = TrainingInstance.fromMap({"title": "Training", "creationTime": DateTime.now(), "arrowsPerEnd": 6});
    await dbService.addTraining(training);
  }

  void _loadTrainings() async {
    List<TrainingInstance> trainings = await dbService.getAllTrainings();
    _trainings = trainings.reversed.toList();
  }

  Widget overviewScreen() {
    return ListView.separated(
        padding: EdgeInsets.all(8),
        itemBuilder: (BuildContext ctxt, int Index) {
          return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrainingSummary(_trainings[Index])),
                );
              },
              child: new Container(
                padding: EdgeInsets.all(5.0),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(
                    width: 3.0,
                    color: Colors.blue[400],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          _trainings[Index].title,
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                              child: Center(
                                  child: Text(
                            "Date: " + _trainings[Index].date(),
                            style: TextStyle(color: Colors.blue[800]),
                          ))),
                          Expanded(
                              child: Center(
                                  child: Text(
                            "Time: " + _trainings[Index].time(),
                            style: TextStyle(color: Colors.blue[800]),
                          ))),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 8,
          );
        },
        itemCount: _trainings.length);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: overviewScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTraining,
        tooltip: 'New Training',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
