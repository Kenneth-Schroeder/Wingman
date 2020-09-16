import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:flutter/services.dart';
import 'package:fluttertraining/TrainingInstance.dart';

class TrainingCreation extends StatefulWidget {
  TrainingCreation({Key key}) : super(key: key);

  @override
  _TrainingCreationState createState() => _TrainingCreationState();
}

class _TrainingCreationState extends State<TrainingCreation> {
  DatabaseService dbService;
  TrainingInstance newTraining = TrainingInstance.fromMap({"title": "Training", "creationTime": DateTime.now(), "arrowsPerEnd": 6});

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
  }

  void _saveNewTraining() async {
    await dbService.addTraining(newTraining);
  }

  Widget newTrainingForm() {
    final _formKey = GlobalKey<FormState>();
    int _value = 1;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Training Title',
            ),
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
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Arrows per End',
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter the number of arrows to shoot per end.';
              }
              if (int.parse(value) <= 0) {
                return 'Please enter a value greater than 0.';
              }
              return null;
            },
            onSaved: (String value) {
              newTraining.arrowsPerEnd = int.parse(value);
            },
            inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
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
              child: Text('Submit'),
            ),
          ),
        ],
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
