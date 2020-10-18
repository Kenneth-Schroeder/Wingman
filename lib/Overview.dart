import 'package:flutter/material.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TrainingSummary.dart';
import 'TrainingCreation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'CompetitionMenu.dart';
import 'package:Wingman/icons/my_flutter_app_icons.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'SizeConfig.dart';
import 'utilities.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TrainingInstance> _trainings = [];
  DatabaseService dbService;
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrainingCreation(training)),
    ).then((value) => onStart());
  }

  void deleteTraining(int trainingID) async {
    await dbService.deleteTraining(trainingID);
    await _loadTrainings();
    setState(() {});
  }

  double getGradientRadius(int height) {
    // todo do this with the other SizeConfigs too // todo make sure to use _screenWidth OR always wait for startRoutineFinished
    SizeConfig().init(context);
    return screenWidth() / height;
  }

  Widget overviewScreen() {
    int lighteningFactor = 800;

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
      child: SizedBox.expand(
        child: Scrollbar(
          child: ListView.separated(
              padding: EdgeInsets.only(top: 10, bottom: 12, left: 12), //EdgeInsets.all(8),
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
                      padding: EdgeInsets.all(10.0),
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                        boxShadow: [new BoxShadow(color: Colors.black54, offset: new Offset(3.0, 4.0), blurRadius: 3.0, spreadRadius: 0.1)],
                        gradient: RadialGradient(
                          radius: getGradientRadius(60), // todo check if thats alright for all screen sizes
                          center: Alignment.topLeft,
                          colors: [
                            Colors.yellow,
                            Colors.yellow[lighteningFactor],
                            Colors.red[lighteningFactor],
                            Colors.red[lighteningFactor],
                            Colors.blue[lighteningFactor],
                            Colors.blue[lighteningFactor],
                            Colors.black,
                          ],
                          stops: [0.0, 0.15, 0.34, 0.48, 0.66, 0.78, 1.0], // [0.0, 0.63, 0.7, 0.76, 0.8, 0.90, 0.94, 1.0],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                _trainings[index].title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
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
                                  style: TextStyle(color: Colors.white),
                                ))),
                                Expanded(
                                    child: Center(
                                        child: Text(
                                  "Time: " + _trainings[index].time(),
                                  style: TextStyle(color: Colors.white),
                                ))),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.navigate_before,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(
                  height: 12,
                );
              },
              itemCount: _trainings.length),
        ),
      ),
    );
  }

  Widget emptyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Text("loading..."),
      ),
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
            color: Colors.white,
          ),
          backgroundColor: Colors.red[800],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CompetitionMenu()),
          ).then((value) => onStart()),
          label: 'Competition Simulation',
          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          labelBackgroundColor: Colors.red[800],
        ),
        SpeedDialChild(
          child: Icon(Icons.assignment, color: Colors.white),
          backgroundColor: Colors.yellow[800],
          onTap: () => _addTraining(),
          label: 'Training',
          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          labelBackgroundColor: Colors.yellow[800],
        ),
      ],
    );
  }

  Widget _helpOverlay() {
    if (showHelpOverlay) {
      return GestureDetector(
        child: Container(
          color: Colors.black,
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Image.asset(
                "assets/images/help/overview.jpg",
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
        ),
        onTap: () {
          showHelpOverlay = false;
          setState(() {});
        },
      );
    }
    return Container();
  }

  Widget showContent() {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(widget.title),
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
            child: overviewScreen(),
          ),
          floatingActionButton: buildSpeedDial(), // This trailing comma makes auto-formatting nicer for build methods.
        ),
        _helpOverlay(),
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
