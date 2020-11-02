import 'package:flutter/material.dart';
import 'database_service.dart';
import 'TrainingInstance.dart';
import 'TrainingSummary.dart';
import 'TrainingCreation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'CompetitionMenu.dart';
import 'package:Wingman/icons/my_flutter_app_icons.dart';
import 'utilities.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'dart:math';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'SizeConfig.dart';
import 'package:google_fonts/google_fonts.dart';

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
  ScrollController _scrollController = ScrollController();
  bool _curtainActive;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    await _loadTrainings();
    SizeConfig().init(context);

    _curtainActive = false;
    _dialController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    startRoutineFinished = true;
    setState(() {});
  }

  void showCoachMarkFAB() {
    CoachMark coachMark = CoachMark();

    if (_addTrainingKey.currentContext == null) {
      if (_trainings != null && _trainings.isNotEmpty) {
        _scrollController
            .animateTo(
              _scrollController.position.minScrollExtent,
              duration: Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
            )
            .then((value) => showCoachMarkFirstTraining());
      }
      return;
    }

    RenderBox target = _addTrainingKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(center: markRect.center, radius: markRect.longestSide * 0.7);

    coachMark.show(
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
          _scrollController
              .animateTo(
                _scrollController.position.minScrollExtent,
                duration: Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
              )
              .then((value) => showCoachMarkFirstTraining());
        }
      },
    );
  }

  void showCoachMarkFirstTraining() {
    CoachMark coachMark = CoachMark();

    if (_trainingTileKey.currentContext == null) {
      return;
    }

    RenderBox target = _trainingTileKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 10, height: markRect.height * 1.2);

    coachMark.show(
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
      MaterialPageRoute(builder: (context) => TrainingCreation(_trainings)),
    ).then((value) {
      startRoutineFinished = false;
      onStart();
    });
  }

  void _loadTrainings() async {
    List<TrainingInstance> trainings = await dbService.getAllTrainings();
    _trainings = trainings.reversed.toList();
  }

  void editTraining(TrainingInstance training) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrainingCreation(_trainings, training)),
    ).then((value) {
      startRoutineFinished = false;
      onStart();
    });
  }

  void deleteTraining(int trainingID) async {
    await dbService.deleteTraining(trainingID);
    await _loadTrainings();
    setState(() {});
  }

  double getGradientRadius(int height) {
    return screenWidth() / height;
  }

  String getTargetImageOfTraining(int index) {
    switch (_trainings[index].targetType) {
      case TargetType.TripleSpot:
        return "assets/images/targets/triple.png";
      case TargetType.SingleSpot:
        return "assets/images/targets/single.png";
      default:
        return "assets/images/targets/full.png";
    }
  }

  String getDistanceOfTraining(int index) {
    if (_trainings[index].targetDistance != null && _trainings[index].targetDistance != 0) {
      return _trainings[index].targetDistance.toStringAsFixed(0) + "m";
    }

    return "-";
  }

  Widget cardRing(Color color, double radiusFactor, double width, bool fill, [Widget child]) {
    return ClipRect(
      child: Center(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Container(
            width: screenWidth() * radiusFactor,
            height: screenWidth() * radiusFactor,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(500)),
              border: Border.all(color: color, width: width),
              color: fill ? color : null,
            ),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 25),
                height: 80,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget trainingInfo(int index) {
    Color col = Colors.black;
    TextStyle smallFont = TextStyle(color: col, fontSize: 16, height: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 2),
        Text(
          _trainings[index].title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.architectsDaughter(
            // lobster, architectsDaughter, rockSalt
            fontSize: 20,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Distance: ",
                    style: smallFont,
                  ),
                  Text(
                    "Score: ",
                    style: smallFont,
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    getDistanceOfTraining(index),
                    style: smallFont,
                  ),
                  Text(
                    _trainings[index].totalScore.toString(),
                    style: smallFont,
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          "Date: " + _trainings[index].date(),
          style: TextStyle(color: col, fontSize: 10),
        ),
        SizedBox(height: 3)
      ],
    );
  }

  Widget trainingCard(int index) {
    return Container(
      key: index == 0 ? _trainingTileKey : null,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        border: Border.all(
          width: 4.0,
          color: Colors.white,
        ),
        color: Colors.white,
        boxShadow: [new BoxShadow(color: Colors.black54, offset: new Offset(3.0, 4.0), blurRadius: 3.0, spreadRadius: 0.1)],
      ),
      child: Stack(
        children: [
          cardRing(Colors.blue, 0.85, _trainings[index].competitionType == CompetitionType.training ? screenWidth() * 0.025 : screenWidth() * 0.05, false),
          cardRing(Colors.red, 0.75, _trainings[index].competitionType == CompetitionType.training ? screenWidth() * 0.025 : screenWidth() * 0.05, false),
          cardRing(Colors.yellow, 0.65, _trainings[index].competitionType == CompetitionType.training ? screenWidth() * 0.025 : screenWidth() * 0.05, false,
              trainingInfo(index)),
        ],
      ),
    );
  }

  Widget overviewScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.7,
          center: Alignment.bottomRight,
          colors: [
            Colors.grey[300],
            Colors.grey[400],
            Colors.grey[500],
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SizedBox.expand(
        child: Scrollbar(
          child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.only(top: 15, bottom: 12, left: 15), //EdgeInsets.all(8),
              itemBuilder: (BuildContext ctxt, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TrainingSummary(_trainings[index])),
                    ).then((value) {
                      startRoutineFinished = false;
                      onStart();
                    });
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
                    child: trainingCard(index),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 16);
              },
              itemCount: _trainings.length),
        ),
      ),
    );
  }

  Widget emptyScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SpinKitCircle(
        color: Theme.of(context).primaryColor,
        size: 100.0,
        controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)),
      ),
    );
  }

  Widget buildSpeedDial(BuildContext context) {
    List<IconData> icons = [MyFlutterApp.trophy, Icons.assignment];
    List<String> labels = ["Virtual Opponent", "Training"];
    List<Color> backgroundColors = [Colors.red[800], Colors.yellow[800]];
    List<Function> actions = [
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CompetitionMenu()),
          ).then((value) {
            startRoutineFinished = false;
            onStart();
          }),
      () => _addTraining()
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
                  _curtainActive = !_curtainActive;
                  if (_dialController.isDismissed) {
                    _dialController.forward();
                  } else {
                    _dialController.reverse();
                  }
                  setState(() {});
                },
              ),
            ),
        ),
      ],
    );
  }

  Widget _greyCurtain() {
    if (!_curtainActive) {
      return Container();
    }
    return GestureDetector(
      onTap: () {
        _dialController.reset();
        _curtainActive = false;
        setState(() {});
      },
      child: Container(
        color: Colors.black54,
      ),
    );
  }

  Widget showContent(BuildContext context) {
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
          body: Stack(
            children: [
              overviewScreen(),
              _greyCurtain(),
            ],
          ),
          floatingActionButton: buildSpeedDial(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    if (startRoutineFinished) {
      return showContent(context);
    }

    return emptyScreen(context);
  }
}
