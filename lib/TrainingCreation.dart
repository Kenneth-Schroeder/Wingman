import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:flutter/services.dart';
import 'TrainingInstance.dart';
import 'package:Wingman/icons/my_flutter_app_icons.dart';
import 'package:Wingman/QuiverOrganizer.dart';

class TrainingCreation extends StatefulWidget {
  TrainingCreation([this.editInstance]);

  TrainingInstance editInstance;

  @override
  _TrainingCreationState createState() => _TrainingCreationState();
}

class _TrainingCreationState extends State<TrainingCreation> {
  DatabaseService dbService;
  TrainingInstance newTraining = TrainingInstance.fromMap({"title": "Training", "creationTime": DateTime.now(), "arrowsPerEnd": -1});
  List<int> _arrowInformationIDs = [];
  final numArrowsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool startRoutineFinished = false;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    numArrowsController.addListener(() {
      setState(() {});
    });

    if (widget.editInstance != null) {
      newTraining = widget.editInstance;
      numArrowsController.text = newTraining.arrowsPerEnd.toString();
    }
    startRoutineFinished = true;
    setState(() {});
  }

  int getNumArrows() {
    if (numArrowsController.text.isEmpty) {
      return 0;
    }

    return int.parse(numArrowsController.text);
  }

  void _saveNewTraining() async {
    int id = await dbService.addTraining(newTraining, _arrowInformationIDs);
  }

  void _updateTraining() async {
    int id = await dbService.updateTraining(newTraining);
  }

  bool arrowSelectionValid() {
    if (_arrowInformationIDs.length != 0 && _arrowInformationIDs.length == getNumArrows()) {
      return true;
    }
    return false;
  }

  void setupArrows() {
    if (getNumArrows() > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuiverOrganizer(getNumArrows(), _arrowInformationIDs)),
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

  void onChangedTargetType(String item) {
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
  }

  void onChangedTargetDiameter(String item) {
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
  }

  List<DropdownMenuItem> targetTypeOptions = ["Full Target", "Single Spot", "Triple Spot"]
      .map((label) => DropdownMenuItem<String>(
            child: Text(label),
            value: label,
          ))
      .toList();

  String getLabelToTargetType(TargetType targetType) {
    //newTraining.targetType.toString()
    switch (targetType) {
      case TargetType.Full:
        return "Full Target";
      case TargetType.SingleSpot:
        return "Single Spot";
      default:
        return "Triple Spot";
    }
  }

  Widget newTrainingForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0, bottom: 10.0),
              child: TextFormField(
                enabled: true, //widget.editInstance == null,
                initialValue: widget.editInstance == null ? null : newTraining.title,
                decoration: const InputDecoration(
                  errorMaxLines: 2,
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
                      // todo needs controller for setupArrows() to get current value, when we dont need onFieldSubmitted anymore
                      enabled: widget.editInstance == null,
                      controller: numArrowsController,
                      decoration: const InputDecoration(
                        errorMaxLines: 3,
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
                          return 'Please enter a value greater than 0 and smaller than 25.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (String text) {
                        setState(() {});
                      },
                      onSaved: (String value) {
                        newTraining.arrowsPerEnd = getNumArrows();
                      },
                      inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: Center(
                        child: ButtonTheme(
                          minWidth: 100.0,
                          height: 50.0,
                          child: RaisedButton(
                            // todo disable button if in edit mode

                            color: arrowSelectionValid() ? Colors.green : Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
                            child: Icon(MyFlutterApp.arrow_flights),
                            onPressed: widget.editInstance == null ? setupArrows : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: TextFormField(
                initialValue: widget.editInstance == null ? null : newTraining.arrowDiameterMM.toStringAsFixed(0),
                enabled: widget.editInstance == null,
                decoration: const InputDecoration(
                  labelText: 'Arrow Diameter in Millimeters',
                  helperMaxLines: 8,
                  errorMaxLines: 3,
                  helperText:
                      'Note: This value will determine the size of the draggable arrows when recording the scores, which may become very hard to see on smaller screens. If readability is more important to you, choose a larger value. ',
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
              child: DropdownButtonFormField<String>(
                value: widget.editInstance == null ? null : getLabelToTargetType(widget.editInstance.targetType),
                disabledHint: widget.editInstance == null ? null : Text(getLabelToTargetType(widget.editInstance.targetType)),
                decoration: const InputDecoration(
                  errorMaxLines: 2,
                  labelText: 'Target Type',
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    borderSide: BorderSide(),
                  ),
                ),
                items: targetTypeOptions,
                validator: (value) {
                  if (value == null) {
                    return 'Please select a target type.';
                  }
                  return null;
                },
                onChanged: widget.editInstance == null
                    ? (String text) {
                        onChangedTargetType(text);
                      }
                    : null,
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: DropdownButtonFormField(
                // todo disable in edit mode
                value: widget.editInstance == null ? "122cm" : newTraining.targetDiameterCM.toStringAsFixed(0) + "cm",
                disabledHint: widget.editInstance == null ? null : Text(newTraining.targetDiameterCM.toStringAsFixed(0) + "cm"),
                decoration: const InputDecoration(
                  errorMaxLines: 2,
                  labelText: 'Target Size',
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    borderSide: BorderSide(),
                  ),
                ),
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
                onChanged: widget.editInstance == null
                    ? (String text) {
                        onChangedTargetDiameter(text);
                      }
                    : null,
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: RaisedButton(
                  color: Colors.blue[800],
                  onPressed: () {
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (_formKey.currentState.validate()) {
                      // Process data.
                      _formKey.currentState.save();
                      widget.editInstance == null ? _saveNewTraining() : _updateTraining();
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

  Widget emptyScreen() {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: widget.editInstance == null ? Text("Create new Training") : Text("Edit Training"),
        ),
        body: Text("loading..."),
      ),
    );
  }

  Widget showContent() {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: widget.editInstance == null ? Text("Create new Training") : Text("Edit Training"),
          actions: <Widget>[
            // action button
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {},
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
            child: SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: newTrainingForm(),
            )),
      ),
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
