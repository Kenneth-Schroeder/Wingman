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
  static final DatabaseService _instance = DatabaseService._internal();
  Future<Database> database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal() {
    initDatabase();
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
            creationTime DATETIME)
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableEnds(
            endID INTEGER PRIMARY KEY AUTOINCREMENT,
            trainingID INTEGER NOT NULL,
            FOREIGN KEY (trainingID) REFERENCES $tableTrainings (id) )
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableScores(
            shotID INTEGER PRIMARY KEY AUTOINCREMENT,
            score INTEGER,
            pRadius REAL,
            pAngle REAL,
            endID INTEGER NOT NULL,
            FOREIGN KEY (endID) REFERENCES $tableEnds (endID) )
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

  void addDefaultScores(int endID, int number) async {
    Database db = await database;
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
        .then((value) => addDefaultScores(value, 3));
  }

  Future<List<TrainingInstance>> getAllTrainings() async {
    Database db = await database;
    List<Map> trainingsMap = await db.query(tableTrainings);
    List<TrainingInstance> trainings = [];
    trainingsMap.forEach((row) => trainings.add(TrainingInstance.fromMap(row)));

    return trainings;
  }

  /*
  Future<RandomNumber> getNumber(int id) async {
    Database db = await database;
    List<Map> datas = await db.query(tableRandomNumber,
        where: 'id = ?',
        whereArgs: [id]);
    if (datas.length > 0) {
      return RandomNumber.fromMap(datas.first);
    }
    return null;
  }
*/
}
