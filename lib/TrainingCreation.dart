import 'package:Wingman/ArrowInformation.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:flutter/services.dart';
import 'TrainingInstance.dart';
import 'package:Wingman/icons/my_flutter_app_icons.dart';
import 'package:Wingman/QuiverOrganizer.dart';

class TrainingCreation extends StatefulWidget {
  TrainingCreation({Key key}) : super(key: key);

  @override
  _TrainingCreationState createState() => _TrainingCreationState();
}

class _TrainingCreationState extends State<TrainingCreation> {
  DatabaseService dbService;
  TrainingInstance newTraining = TrainingInstance.fromMap({"title": "Training", "creationTime": DateTime.now(), "arrowsPerEnd": -1});
  List<int> _arrowInformationIDs = [];

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
  }

  void _saveNewTraining() async {
    int id = await dbService.addTraining(newTraining);
    if (arrowSelectionValid()) {
      dbService.addArrowInfoToTraining(_arrowInformationIDs, id);
    }
  }

  bool arrowSelectionValid() {
    print(_arrowInformationIDs);
    if (_arrowInformationIDs.length != 0 && _arrowInformationIDs.length == newTraining.arrowsPerEnd) {
      return true;
    }
    return false;
  }

  void setupArrows() {
    if (newTraining.arrowsPerEnd > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuiverOrganizer(newTraining.arrowsPerEnd)),
      ).then((arrowInformationIDs) {
        if (arrowInformationIDs != null) {
          // can be null if back button is hit
          setState(() {
            _arrowInformationIDs = arrowInformationIDs;
          });
        }
      });
    }
  }

  Widget newTrainingForm() {
    final _formKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0, bottom: 10.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Training Title',
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    borderSide: BorderSide(),
                  ),
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (String value) {
                  newTraining.title = value;
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: newTraining.arrowsPerEnd > 0 ? newTraining.arrowsPerEnd.toString() : null,
                      decoration: const InputDecoration(
                        labelText: 'Arrows per End',
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(25.0),
                          ),
                          borderSide: BorderSide(),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter the number of arrows to shoot per end.';
                        }
                        if (int.parse(value) <= 0 || int.parse(value) > 24) {
                          return 'Please enter a value greater than 0 and smaller than 25';
                        }
                        return null;
                      },
                      onFieldSubmitted: (String value) {
                        // todo add proper listener
                        newTraining.arrowsPerEnd = int.parse(value);
                        setState(() {});
                      },
                      inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                    ),
                  ),
                  Expanded(
                    child: RaisedButton(
                      color: arrowSelectionValid() ? Colors.green : Colors.redAccent,
                      child: Icon(MyFlutterApp.arrow_flights),
                      onPressed: setupArrows,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Arrow Diameter in Millimeters',
                  helperText: 'Note: This value will determine the size of the draggable\n'
                      ' arrows when recording the scores, which may become\n'
                      ' very hard to see on smaller screens.\n'
                      ' If readability is more important to you, choose a larger value. ',
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    borderSide: BorderSide(),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter the diameter of your arrows in millimeters.';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Please enter a value greater than 0';
                  }
                  return null;
                },
                onSaved: (String value) {
                  newTraining.arrowDiameterMM = double.parse(value);
                },
                inputFormatters: [WhitelistingTextInputFormatter.digitsOnly], // TODO fix this
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Target Type',
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    borderSide: BorderSide(),
                  ),
                ),
                items: ["Full Target", "Single Spot", "Triple Spot"]
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a target type.';
                  }
                  return null;
                },
                onChanged: (String item) {
                  switch (item) {
                    case "Full Target":
                      newTraining.targetType = TargetType.Full;
                      break;
                    case "Single Spot":
                      newTraining.targetType = TargetType.SingleSpot;
                      break;
                    case "Triple Spot":
                      newTraining.targetType = TargetType.TripleSpot;
                      break;
                  }
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Target Size',
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    borderSide: BorderSide(),
                  ),
                ),
                value: "122cm",
                items: ["40cm", "60cm", "80cm", "122cm"]
                    .map((label) => DropdownMenuItem(
                          child: Text(label.toString()),
                          value: label,
                        ))
                    .toList(),
                hint: Text('Target Diameter'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a target diameter.';
                  }
                  return null;
                },
                onChanged: (String item) {
                  switch (item) {
                    case "40cm":
                      newTraining.targetDiameterCM = 40;
                      break;
                    case "60cm":
                      newTraining.targetDiameterCM = 60;
                      break;
                    case "80cm":
                      newTraining.targetDiameterCM = 80;
                      break;
                    case "122cm":
                      newTraining.targetDiameterCM = 122;
                      break;
                  }
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: RaisedButton(
                  color: Colors.blue,
                  onPressed: () {
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (_formKey.currentState.validate()) {
                      // Process data.
                      _formKey.currentState.save();
                      _saveNewTraining();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create new Training"),
      ),
      body: newTrainingForm(),
    );
  }
}
