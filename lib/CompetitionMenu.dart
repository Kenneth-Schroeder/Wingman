import 'package:Wingman/TrainingInstance.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'utilities.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:Wingman/icons/my_flutter_app_icons.dart';
import 'QuiverOrganizer.dart';

class CompetitionMenu extends StatefulWidget {
  CompetitionMenu({Key key}) : super(key: key);

  @override
  _CompetitionMenuState createState() => _CompetitionMenuState();
}

class _CompetitionMenuState extends State<CompetitionMenu> {
  DatabaseService dbService;
  double sliderValue = 10;
  List<int> selected = [-1, -1, -1]; // outdoor, indoor / female, male / qualifying, finals
  bool showError = false;
  GlobalKey _outdoorIndoorKey = GlobalObjectKey("outdoorIndoor");
  GlobalKey _difficultyKey = GlobalObjectKey("difficulty");
  ScrollController _scrollController = ScrollController();
  TrainingInstance training;
  List<int> _arrowInformationIDs = [];
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    training = TrainingInstance("", DateTime.now());
    dbService = await DatabaseService.create();
  }

  void showCoachMarkOutdoorIndoor() {
    CoachMark coachMark = CoachMark();

    if (_outdoorIndoorKey.currentContext == null) {
      _scrollController
          .animateTo(
            _scrollController.position.minScrollExtent,
            duration: Duration(seconds: 1),
            curve: Curves.fastOutSlowIn,
          )
          .then((value) => showCoachMarkDifficulty());
      return;
    }

    RenderBox target = _outdoorIndoorKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 10, height: markRect.height * 1.2);

    coachMark.show(
      targetContext: _outdoorIndoorKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Select which type of competition you want to train. Your choice will determine the target types, reference difficulties and the competition format.",
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
        _scrollController
            .animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
            )
            .then((value) => showCoachMarkDifficulty());
      },
    );
  }

  void showCoachMarkDifficulty() {
    CoachMark coachMark = CoachMark();

    if (_difficultyKey.currentContext == null) {
      return;
    }

    RenderBox target = _difficultyKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 10, height: markRect.height * 1.2);

    coachMark.show(
      targetContext: _difficultyKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Select a difficulty using the slider. Level 20 is statistically equivalent to recent world champion performances.",
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

  void _saveNewTraining(TrainingInstance training) async {
    await dbService.addTraining(training, _arrowInformationIDs);
  }

  Widget floatingBoxWrapper(String image, String title, Color textColor, Alignment titleAlign, int category, int option) {
    BorderRadius radius = BorderRadius.only(bottomLeft: Radius.circular(10), topRight: Radius.circular(10));
    bool highlighted = selected[category] == option;

    Widget imageWidget = ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.grey[800],
        BlendMode.multiply,
      ),
      child: Image.asset(
        "assets/images/" + image,
        fit: BoxFit.cover,
      ),
    );

    if (highlighted) {
      imageWidget = Image.asset(
        "assets/images/" + image,
        fit: BoxFit.cover,
      );
    }

    return Expanded(
      child: Stack(
        children: [
          Container(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: GestureDetector(
                onTap: () {
                  selected[category] = option;
                  setState(() {});
                },
                child: imageWidget,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: customBoxShadow(),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: titleAlign,
              child: Container(
                padding: EdgeInsets.all(4),
                //margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.85),
                  borderRadius: radius,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BoxShadow> customBoxShadow() {
    return [
      BoxShadow(
        color: Colors.grey.withOpacity(0.8),
        spreadRadius: 3,
        blurRadius: 6,
        offset: Offset(0, 3), // changes position of shadow
      ),
    ];
  }

  void submitSelection() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    _formKey.currentState.save();

    if (!selected.contains(-1)) {
      training.competitionLevel = sliderValue.toInt();

      if (selected[0] == 0) {
        // outdoor
        training.targetDiameterCM = 122;
        training.targetType = TargetType.Full;
        training.title += "Outdoor ";

        if (selected[2] == 0) {
          // qualifying
          training.arrowsPerEnd = 6;
          training.numberOfEnds = 12;
        } else {
          // finals
          training.arrowsPerEnd = 3;
          training.numberOfEnds = 0;
        }
      } else {
        // indoor
        training.targetDiameterCM = 40;
        training.targetType = TargetType.TripleSpot;
        training.arrowsPerEnd = 3;
        training.title += "Indoor ";

        if (selected[2] == 0) {
          // qualifying
          training.numberOfEnds = 20;
        } else {
          // finals
          training.numberOfEnds = 0;
        }
      }

      if (selected[2] == 0) {
        // qualifying
        training.competitionType = CompetitionType.qualifying;
        training.title += "Qual. ";
      } else {
        // finals
        training.competitionType = CompetitionType.finals;
        training.title += "Final ";
      }

      if (selected[1] == 0) {
        // female
        training.referencedGender = Gender.female;
        training.title += "♀-";
      } else {
        // male
        training.referencedGender = Gender.male;
        training.title += "♂-";
      }

      training.title += training.competitionLevel.toString().padLeft(2, "0");

      await _saveNewTraining(training);
      Navigator.pop(context);
    }
  }

  int getNumArrows() {
    if (selected[0] == 0 && selected[2] == 0) {
      return 6;
    }

    return 3;
  }

  bool arrowSelectionValid() {
    if (_arrowInformationIDs.length != 0 && _arrowInformationIDs.length == getNumArrows()) {
      return true;
    }
    return false;
  }

  void setupArrows(BuildContext context) {
    if (getNumArrows() > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuiverOrganizer(getNumArrows(), _arrowInformationIDs)),
      ).then(
        (arrowInformationIDs) {
          if (arrowInformationIDs != null) {
            // can be null if back button is hit
            setState(() {
              _arrowInformationIDs = arrowInformationIDs;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text("Virtual Opponent"),
            actions: <Widget>[
              // action button
              IconButton(
                icon: Icon(Icons.help),
                onPressed: () {
                  _scrollController
                      .animateTo(
                        _scrollController.position.minScrollExtent,
                        duration: Duration(seconds: 1),
                        curve: Curves.fastOutSlowIn,
                      )
                      .then((value) => showCoachMarkOutdoorIndoor());
                },
              ),
            ],
          ),
          body: Container(
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
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        key: _outdoorIndoorKey,
                        children: [
                          floatingBoxWrapper("outdoor.jpg", "Outdoor", Colors.white, Alignment.bottomLeft, 0, 0),
                          SizedBox(width: 20),
                          floatingBoxWrapper("indoor.jpg", "Indoor", Colors.white, Alignment.topRight, 0, 1),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          floatingBoxWrapper("female.png", "Female", Colors.white, Alignment.bottomLeft, 1, 0),
                          SizedBox(width: 20),
                          floatingBoxWrapper("male.png", "Male", Colors.white, Alignment.topRight, 1, 1),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          floatingBoxWrapper("qualification.jpg", "Qualifying", Colors.white, Alignment.bottomLeft, 2, 0),
                          SizedBox(width: 20),
                          floatingBoxWrapper("finals.jpg", "Finals", Colors.white, Alignment.topRight, 2, 1),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        key: _difficultyKey,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Column(
                          children: [
                            Text(
                              "Difficulty",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Slider(
                              value: sliderValue,
                              onChanged: (newVal) {
                                sliderValue = newVal;
                                setState(() {});
                              },
                              min: 1,
                              max: 20,
                              divisions: 19,
                              label: sliderValue.toInt().toString(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 22),
                                  child: Text("Beginner", style: TextStyle(fontSize: 16)),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 22),
                                  child: Text("World Champion", style: TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: customBoxShadow(),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: customBoxShadow(),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                                child: TextFormField(
                                  enabled: true,
                                  initialValue: training.arrowDiameterMM.toStringAsFixed(0),
                                  decoration: InputDecoration(
                                    labelText: 'Arrow Diameter in Millimeters',
                                    errorMaxLines: 5,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(25.0),
                                      ),
                                      borderSide: BorderSide(),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter the diameter of your arrows in millimeters.';
                                    }
                                    if (double.parse(value) <= 0 || double.parse(value) > 20) {
                                      return 'Please enter a value greater than 0 and smaller than 20.';
                                    }
                                    return null;
                                  },
                                  onSaved: (String value) {
                                    training.arrowDiameterMM = double.parse(value);
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: Center(
                                  child: ButtonTheme(
                                    minWidth: 100.0,
                                    height: 50.0,
                                    child: RaisedButton(
                                      color: arrowSelectionValid() ? Colors.green : Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
                                      child: Icon(MyFlutterApp.arrow_flights),
                                      onPressed: selected.contains(-1) ? null : () => setupArrows(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: Text("Let's go", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          decoration: BoxDecoration(
                            color: selected.contains(-1) ? Colors.grey : Colors.blue[800],
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: customBoxShadow(),
                          ),
                        ),
                        onTap: submitSelection,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
