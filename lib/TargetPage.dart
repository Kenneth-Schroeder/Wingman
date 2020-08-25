import 'package:flutter/material.dart';
import 'package:fluttertraining/ScoreInstance.dart';
import 'database_service.dart';
import 'package:fluttertraining/TrainingInstance.dart';
import 'TargetPainter.dart';
import 'ArrowPainter.dart';
import 'SizeConfig.dart';
import 'dart:math';
import 'ScoreInstance.dart';

class TargetPage extends StatefulWidget {
  TargetPage(this.training, {Key key}) : super(key: key);

  final TrainingInstance training;

  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  DatabaseService dbService = DatabaseService();
  List<ScoreInstance> arrows;

  Offset targetCenter;
  double targetRadius;
  double arrowRadius = 10;
  int _draggedArrow = -1;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    arrows = [
      // check if which arrows exist in database
      // then arrowpainter can take care of positioning relative to target
      ScoreInstance(0),
      ScoreInstance(0),
      ScoreInstance(0),
    ];
  }

  Widget createTarget() {
    return CustomPaint(painter: TargetPainter(targetCenter, targetRadius, false));
  }

  double polarDistance(double r1, double a1, double r2, double a2) {
    return sqrt(r1 * r1 + r2 * r2 - 2 * r1 * r2 * cos(a1 - a2));
  }

  List argMin(List<double> numbers) {
    double minValue = double.maxFinite;
    int minIndex = 0;

    for (var i = 0; i < numbers.length; i++) {
      if (numbers[i] < minValue) {
        minValue = numbers[i];
        minIndex = i;
      }
    }

    return [minValue, minIndex];
  }

  List localCartesianToRelativePolar(double x, double y) {
    double rX = x - targetCenter.dx; // x coordinate relative to target center
    double rY = y - targetCenter.dy; // y coordinate relative to target center

    double pRadius = sqrt(rX * rX + rY * rY);
    double pAngle = atan2(rY, rX);

    return [pRadius, pAngle];
  }

  int _touchedArrowIndex(double x, double y) {
    // determine distance to all arrows and return arrow with lowest dist IF within radius
    double touchPRadius = localCartesianToRelativePolar(x, y)[0];
    double touchPAngle = localCartesianToRelativePolar(x, y)[1];

    List<double> distances = [];
    arrows.forEach(
        (arrow) => distances.add(polarDistance(touchPRadius, touchPAngle, arrow.pRadius * targetRadius, arrow.pAngle)));

    if (argMin(distances)[0] <= arrowRadius) {
      return argMin(distances)[1];
    }

    return -1;
  }

  Widget loadArrows() {
    List<CustomPaint> arrowPainters = [];
    arrows.forEach((element) {
      arrowPainters.add(
        CustomPaint(
          painter: ArrowPainter.fromInstance(element, arrowRadius, false, targetCenter, targetRadius),
          child: Container(),
        ),
      );
    });

    return GestureDetector(
        onPanStart: (details) {
          _draggedArrow = _touchedArrowIndex(details.localPosition.dx, details.localPosition.dy);
        },
        onPanEnd: (details) {
          _draggedArrow = -1;
        },
        onPanUpdate: (details) {
          if (_draggedArrow != -1) {
            arrows[_draggedArrow].moveByOffset(details.delta, targetRadius);
            setState(() {});
          }
        },
        child: new Stack(
          children: arrowPainters,
        ));
  }

  // TODO reset button for arrows
  // TODO remember arrow positions properly through database
  // TODO enable more pages for additional ends - BottomNavigationBar
  // TODO recognize scores of arrows
  // TODO different arrow counts

  void resetArrows() {
    arrows.forEach((element) {
      element.reset();
    });
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    targetCenter = SizeConfig().threeSideCenter();
    targetRadius = SizeConfig().minDim() / 2.2;

    return Scaffold(
      appBar: AppBar(title: Text("Score Recording"), actions: <Widget>[
        // action button
        IconButton(
          icon: Icon(Icons.undo),
          onPressed: resetArrows,
        ),
      ]),
      body: new Stack(
        children: [createTarget(), loadArrows()],
      ),
      bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Quickstats"), // TODO add quickstats
              new Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlatButton(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.0)),
                    padding: EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.navigate_before),
                        Text("Previous"),
                      ],
                    ),
                    onPressed: () {},
                  ),
                  Text(
                    "Round 1/10",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  FlatButton(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.0)),
                    padding: EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.navigate_next),
                        Text("Next"),
                      ],
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          )),

      /*BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.navigate_before),
            title: Text('Previous'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.atm),
            title: Text('Round 1'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigate_next),
            title: Text('Next'),
          ),
        ],
        currentIndex: 1,
        //selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),*/
    );
  }
}
