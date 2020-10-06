import 'package:Wingman/QuiverOrganizer.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TrainingSummary.dart';
import 'TrainingCreation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'CompetitionMenu.dart';
import 'package:Wingman/icons/my_flutter_app_icons.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
  bool startRoutineFinished = false;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    await _loadTrainings();
    startRoutineFinished = true;
    setState(() {});
  }

  void _addTraining() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrainingCreation()),
    ).then((value) => onStart());
  }

  void _loadTrainings() async {
    List<TrainingInstance> trainings = await dbService.getAllTrainings();
    _trainings = trainings.reversed.toList();
  }

  void editTraining(TrainingInstance training) {
    // TODO implement
  }

  void deleteTraining(int trainingID) async {
    await dbService.deleteTraining(trainingID);
    await _loadTrainings();
    setState(() {});
  }

  Widget overviewScreen() {
    return Scrollbar(
      child: ListView.separated(
          padding: EdgeInsets.all(8),
          itemBuilder: (BuildContext ctxt, int index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrainingSummary(_trainings[index])),
                );
              },
              child: Slidable(
                actionPane: SlidableDrawerActionPane(),
                actionExtentRatio: 0.25,
                secondaryActions: <Widget>[
                  IconSlideAction(
                    caption: 'Edit',
                    color: Colors.black45,
                    icon: Icons.more_horiz,
                    onTap: () => editTraining(_trainings[index]),
                  ),
                  IconSlideAction(
                    caption: 'Delete',
                    color: Colors.red,
                    icon: Icons.delete,
                    onTap: () => deleteTraining(_trainings[index].id),
                  ),
                ],
                child: Container(
                  padding: EdgeInsets.all(5.0),
                  height: 50,
                  decoration: BoxDecoration(
                    color: _trainings[index].competitionType == CompetitionType.training ? Colors.yellow[200] : Colors.red[200],
                    boxShadow: [new BoxShadow(color: Colors.grey, offset: new Offset(3.0, 2.0), blurRadius: 3.0, spreadRadius: 0.1)],
                    border: Border.all(
                      width: 3.0,
                      color: Colors.blue[400],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            _trainings[index].title,
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
                              "Date: " + _trainings[index].date(),
                              style: TextStyle(color: Colors.blue[800]),
                            ))),
                            Expanded(
                                child: Center(
                                    child: Text(
                              "Time: " + _trainings[index].time(),
                              style: TextStyle(color: Colors.blue[800]),
                            ))),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.navigate_before,
                        color: Colors.blue[800],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return SizedBox(
              height: 8,
            );
          },
          itemCount: _trainings.length),
    );
  }

  Widget emptyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Text("loading..."),
    );
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      // child: Icon(Icons.add),
      // onOpen: () => print('OPENING DIAL'),
      // onClose: () => print('DIAL CLOSED'),
      visible: true,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(
            MyFlutterApp.trophy,
            color: Colors.black,
          ),
          backgroundColor: Colors.redAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CompetitionMenu()),
          ).then((value) => onStart()),
          label: 'Competition Simulation',
          labelStyle: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
          labelBackgroundColor: Colors.redAccent,
        ),
        SpeedDialChild(
          child: Icon(Icons.assignment, color: Colors.black),
          backgroundColor: Colors.yellowAccent,
          onTap: () => _addTraining(),
          label: 'Open Training',
          labelStyle: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
          labelBackgroundColor: Colors.yellowAccent,
        ),
      ],
    );
  }

  void setupArrows() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuiverOrganizer()),
    ).then((value) => onStart());
  }

  Widget showContent() {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(MyFlutterApp.arrow_flights),
            onPressed: setupArrows,
          ),
        ],
      ),
      body: overviewScreen(),
      floatingActionButton: buildSpeedDial(), // This trailing comma makes auto-formatting nicer for build methods.
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
