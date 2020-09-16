import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'TrainingInstance.dart';
import 'ScoreInstance.dart';

final tableTrainings = "trainings";
final tableEnds = "ends";
final tableScores = "scores";
final tableArrows = "arrows"; // specific arrow information

class DatabaseService {
  Future<Database> database;

  DatabaseService._();

  // https://github.com/fluttercommunity/get_it/issues/4
  static Future<DatabaseService> create() async {
    var emptyDB = DatabaseService._();
    await emptyDB.initDatabase();
    return emptyDB;
  }

  initDatabase() async {
    database = openDatabase(
      join(await getDatabasesPath(), 'beautiful_alarm.db'),
      // When the database is first created, create a table to store data.
      onCreate: (db, version) {
        db.execute(
          '''CREATE TABLE $tableTrainings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            arrowsPerEnd INTEGER,
            creationTime DATETIME)
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableEnds(
            endID INTEGER PRIMARY KEY AUTOINCREMENT,
            trainingID INTEGER NOT NULL,
            FOREIGN KEY (trainingID) REFERENCES $tableTrainings (id) ON DELETE CASCADE ) 
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableScores(
            shotID INTEGER PRIMARY KEY AUTOINCREMENT,
            arrowRadius REAL,
            score INTEGER,
            pRadius REAL,
            pAngle REAL,
            endID INTEGER NOT NULL,
            FOREIGN KEY (endID) REFERENCES $tableEnds (endID) ON DELETE CASCADE ) 
          ''',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  Future<int> addEnd(int trainingID) async {
    Database db = await database;
    int id = await db.insert(tableEnds, {"trainingID": trainingID});
    return id;
  }

  Future<int> addScore(ScoreInstance instance) async {
    Database db = await database;
    int id = await db.insert(tableScores, instance.toMap());
    return id;
  }

  Future<int> updateScore(ScoreInstance instance) async {
    Database db = await database;

    int updateCount = await db.update(tableScores, instance.toMap(), where: 'shotID = ?', whereArgs: [instance.shotID]);

    return updateCount;
  }

  void addDefaultScores(int endID, int number) async {
    for (var i = 0; i < number; i++) {
      addScore(ScoreInstance(endID));
    }
  }

  Future<Map<int, List<ScoreInstance>>> getFullEndsOfTraining(int trainingID) async {
    // get all ends first and then get scores for each end
    Database db = await database;
    List<Map> endsMap = await db.rawQuery("SELECT * "
        "FROM $tableEnds "
        "INNER JOIN $tableTrainings ON $tableEnds.trainingID = $tableTrainings.id "
        "INNER JOIN $tableScores ON $tableEnds.endID = $tableScores.endID "
        "WHERE $tableEnds.trainingID == $trainingID");

    Map<int, List<ScoreInstance>> scoresByEnd = Map<int, List<ScoreInstance>>();
    endsMap.forEach((element) {
      if (!scoresByEnd.containsKey(element["endID"])) scoresByEnd[element["endID"]] = [];
      scoresByEnd[element["endID"]].add(ScoreInstance.fromMap(element));
    });

    return scoresByEnd;
  }

  Future<bool> updateAllEndsOfTraining(int trainingID, List<List<ScoreInstance>> arrows) async {
    // iterate over all ends and as long as arrows have an id, update them individually
    arrows.forEach((end) {
      // update arrows that are in DB already and insert new ones for those that have no ID
      if (end.first.shotID != -1) {
        end.forEach((arrow) {
          updateScore(arrow); // todo check if its alright not to use await here
        });
      } else {
        addEnd(trainingID).then((endID) => end.forEach((arrow) {
              arrow.endID = endID;
              addScore(arrow);
            }));
      }
    });

    return true;
  }

  Future<List<ScoreInstance>> getAllScoresOfEnd(int endID) async {
    Database db = await database;
    List<Map> scoresMap = await db.rawQuery(
        "SELECT * FROM $tableScores INNER JOIN $tableEnds ON $tableScores.endID = $tableEnds.endID WHERE $tableScores.endID == $endID");

    List<ScoreInstance> scores = [];
    scoresMap.forEach((row) => scores.add(ScoreInstance.fromMap(row)));

    return scores;
  }

  void addTraining(TrainingInstance instance) async {
    Database db = await database;

    db
        .insert(tableTrainings, instance.toMap())
        .then((value) => addEnd(value))
        .then((value) => addDefaultScores(value, instance.arrowsPerEnd));
  }

  void deleteTraining(int trainingID) async {
    Database db = await database;
    await db.delete(tableTrainings, where: 'id = ?', whereArgs: [trainingID]);
  }

  Future<List<TrainingInstance>> getAllTrainings() async {
    Database db = await database;

    return db.query(tableTrainings).then((value) {
      List<TrainingInstance> trainings = [];
      value.forEach((row) => trainings.add(TrainingInstance.fromMap(row)));
      return trainings;
    });
  }
}
