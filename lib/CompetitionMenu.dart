import 'package:Wingman/TrainingInstance.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

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

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
  }

  void _saveNewTraining(TrainingInstance training) async {
    await dbService.addTraining(training);
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

  void submitSelection() {
    if (!selected.contains(-1)) {
      TrainingInstance training = TrainingInstance("Competition", DateTime.now());

      training.competitionLevel = sliderValue.toInt();

      if (selected[0] == 0) {
        // outdoor
        training.targetDiameterCM = 122;
        training.targetType = TargetType.Full;

        if (selected[2] == 0) {
          // qualifying
          training.arrowsPerEnd = 6;
          training.numberOfEnds = 12;
        } else {
          // finals
          training.arrowsPerEnd = 0;
        }
      } else {
        // indoor
        training.targetDiameterCM = 40;
        training.targetType = TargetType.TripleSpot;
        training.arrowsPerEnd = 3;

        if (selected[2] == 0) {
          // qualifying
          training.numberOfEnds = 20;
        } else {
          // finals
          training.numberOfEnds = 0;
        }
      }

      if (selected[1] == 0) {
        // female
        training.referencedGender = Gender.female;
      } else {
        // male
        training.referencedGender = Gender.male;
      }

      if (selected[2] == 0) {
        // qualifying
        training.competitionType = CompetitionType.qualifying;
      } else {
        // finals
        training.competitionType = CompetitionType.finals;
      }

      _saveNewTraining(training);
      Navigator.pop(context);
    }
  }

  // images from https://svgsilh.com/image/2025609.html and https://svgsilh.com/image/156849.html
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Competition Simulation"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              floatingBoxWrapper("outdoor.jpg", "Outdoors", Colors.white, Alignment.bottomLeft, 0, 0),
              SizedBox(width: 20),
              floatingBoxWrapper("indoor.jpg", "Indoors", Colors.white, Alignment.topRight, 0, 1),
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
                      child: Text("Inhuman", style: TextStyle(fontSize: 16)),
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
          InkWell(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Center(
                child: Text("Let's go", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              decoration: BoxDecoration(
                color: selected.contains(-1) ? Colors.grey : Colors.greenAccent,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: customBoxShadow(),
              ),
            ),
            onTap: submitSelection,
          ),
        ],
      ),
    );
  }
}
