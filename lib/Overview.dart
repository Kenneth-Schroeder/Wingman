import 'package:flutter/material.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TrainingSummary.dart';
import 'TrainingCreation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'CompetitionMenu.dart';
import 'package:Wingman/icons/my_flutter_app_icons.dart';
import 'SizeConfig.dart';
import 'utilities.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'dart:math';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<TrainingInstance> _trainings = [];
  DatabaseService dbService;
  bool startRoutineFinished = false;
  GlobalKey _addTrainingKey = GlobalObjectKey("addTraining");
  GlobalKey _trainingTileKey = GlobalObjectKey("trainingTile");
  AnimationController _dialController;

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

    _dialController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    setState(() {});
  }

  void showCoachMarkFAB() {
    CoachMark coachMarkFAB = CoachMark();

    if (_addTrainingKey.currentContext == null) {
      if (_trainings != null && _trainings.isNotEmpty) {
        showCoachMarkFirstTraining();
      }
      return;
    }

    RenderBox target = _addTrainingKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(center: markRect.center, radius: markRect.longestSide * 0.8);

    coachMarkFAB.show(
      targetContext: _addTrainingKey.currentContext,
      markRect: markRect,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Tap here to add a training session.",
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
        if (_trainings != null && _trainings.isNotEmpty) {
          showCoachMarkFirstTraining();
        }
      },
    );
  }

  void showCoachMarkFirstTraining() {
    CoachMark coachMarkFAB = CoachMark();

    if (_trainingTileKey.currentContext == null) {
      return;
    }

    RenderBox target = _trainingTileKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 10, height: markRect.height * 1.2);

    coachMarkFAB.show(
      targetContext: _trainingTileKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Tap here to enter a training session or swipe left for more actions.",
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
    );
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

    return GestureDetector(
      onTap: () {
        _dialController.reset();
      },
      child: Container(
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
                      ).then((value) => onStart());
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
                        key: index == 0 ? _trainingTileKey : null,
                        padding: EdgeInsets.all(10.0),
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                          boxShadow: [
                            new BoxShadow(color: Colors.black54, offset: new Offset(3.0, 4.0), blurRadius: 3.0, spreadRadius: 0.1)
                          ],
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: false,
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

  Widget buildSpeedDial() {
    List<IconData> icons = [MyFlutterApp.trophy, Icons.assignment];
    List<String> labels = ["Virtual Opponent", "Training"];
    List<Color> backgroundColors = [Colors.red[800], Colors.yellow[800]];
    List<Function> actions = [
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CompetitionMenu()),
        ).then((value) => onStart());
      },
      () {
        _addTraining();
      }
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              height: 70.0,
              alignment: FractionalOffset.topCenter,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _dialController,
                  curve: Interval(0.0, 1.0 - 0 / icons.length / 2.0, curve: Curves.easeOut),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.red[800],
                    border: Border.all(
                      width: 5.0,
                      color: Colors.red[800],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    "Virtual Opponent",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Container(
              height: 70.0,
              alignment: FractionalOffset.topCenter,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _dialController,
                  curve: Interval(0.0, 1.0 - 1 / icons.length / 2.0, curve: Curves.easeOut),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.yellow[800],
                    border: Border.all(
                      width: 5.0,
                      color: Colors.yellow[800],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    "Training",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Container(
              height: 32.0,
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(icons.length, (int index) {
            Widget child = Container(
              height: 70.0,
              width: 56.0,
              alignment: FractionalOffset.topCenter,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _dialController,
                  curve: Interval(0.0, 1.0 - index / icons.length / 2.0, curve: Curves.easeOut),
                ),
                child: FloatingActionButton(
                  heroTag: null,
                  backgroundColor: backgroundColors[index],
                  mini: true,
                  child: Icon(icons[index], color: Colors.white),
                  onPressed: actions[index],
                ),
              ),
            );
            return child;
          }).toList()
            ..add(
              FloatingActionButton(
                key: _addTrainingKey,
                heroTag: null,
                child: AnimatedBuilder(
                  animation: _dialController,
                  builder: (BuildContext context, Widget child) {
                    return Transform(
                      transform: _dialController.isDismissed ? Matrix4.identity() : Matrix4.rotationZ(_dialController.value * 0.25 * pi),
                      alignment: FractionalOffset.center,
                      child: Icon(Icons.add),
                    );
                  },
                ),
                onPressed: () {
                  if (_dialController.isDismissed) {
                    _dialController.forward();
                  } else {
                    _dialController.reverse();
                  }
                },
              ),
            ),
        ),
      ],
    );
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
                  showCoachMarkFAB();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: overviewScreen(),
          ),
          floatingActionButton: buildSpeedDial(), // This trailing comma makes auto-formatting nicer for build methods.
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
