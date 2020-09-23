import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'TrainingInstance.dart';
import 'ScoreInstance.dart';
import 'TargetPage.dart'; // todo move Archer definition

final tableTrainings = "trainings";
final tableOpponents = "opponents";
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
            targetType INTEGER,
            competitionType INTEGER,
            competitionLevel INTEGER,
            referencedGender INTEGER,
            numberOfEnds INTEGER,
            targetDiameterCM REAL,
            creationTime DATETIME)
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableOpponents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            trainingID INTEGER NOT NULL,
            FOREIGN KEY (trainingID) REFERENCES $tableTrainings (id) ON DELETE CASCADE )
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableEnds(
            endID INTEGER PRIMARY KEY AUTOINCREMENT,
            arrowCount INTEGER,
            trainingID INTEGER,
            opponentID INTEGER,
            FOREIGN KEY (trainingID) REFERENCES $tableTrainings (id) ON DELETE CASCADE,
            FOREIGN KEY (opponentID) REFERENCES $tableOpponents (id) ON DELETE CASCADE )
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

  Future<int> addOpponent(int trainingID, String name) async {
    Database db = await database;
    int id = await db.insert(tableOpponents, {"trainingID": trainingID, "name": name});
    return id;
  }

  Future<bool> addOpponents(int trainingID, int number) async {
    // todo it this even used?
    for (int i = 0; i < number; i++) {
      await addOpponent(trainingID, i.toString());
    }
    return true;
  }

  Future<int> addOpponentsEnd(int opponentID, int arrowCount) async {
    Database db = await database;
    int id = await db.insert(tableEnds, {"opponentID": opponentID, "arrowCount": arrowCount});
    return id;
  }

  void deleteAllEndsOfOpponent(int opponentID) async {
    Database db = await database;
    await db.delete(tableEnds, where: 'opponentID = ?', whereArgs: [opponentID]);
  }

  Future<bool> updateAllEndsOfOpponent(int opponentID, Archer archer) async {
    // just delete all and create new entries?
    deleteAllEndsOfOpponent(opponentID);

    archer.arrowScores.forEach((end) {
      // update arrows that are in DB already and insert new ones for those that have no ID
      addOpponentsEnd(opponentID, end.length).then((endID) => end.forEach((score) {
            addScore(ScoreInstance.scoreOnly(endID, score)); // TODO this uses unnecessarily much storage
          }));
    });

    return true;
  }

  Future<bool> updateAllOpponents(int trainingID, List<Archer> opponents) async {
    List<int> opponentIDs = await getAllOpponentIDs(trainingID);

    for (int i = 0; i < opponentIDs.length; i++) {
      await updateAllEndsOfOpponent(opponentIDs[i], opponents[i]);
    }

    return true;
  }

  Future<Archer> getOpponent(int opponentID) async {
    // get all ends first and then get scores for each end
    Database db = await database;
    List<Map> endsMap = await db.rawQuery("SELECT * "
        "FROM $tableEnds "
        "INNER JOIN $tableScores ON $tableEnds.endID = $tableScores.endID "
        "INNER JOIN $tableOpponents ON $tableOpponents.id = $tableEnds.opponentID "
        "WHERE $tableEnds.opponentID == $opponentID");

    Archer opponent = Archer(endsMap.first['name'].toString());

    Map<int, List<int>> scoresByEnd = Map<int, List<int>>(); // maps from endID to the scores
    endsMap.forEach((element) {
      if (!scoresByEnd.containsKey(element["endID"])) {
        scoresByEnd[element["endID"]] = [];
      }
      scoresByEnd[element["endID"]].add(element["score"]);
    });

    opponent.arrowScores = new List.generate(scoresByEnd.length, (i) => []);
    int counter = 0;
    scoresByEnd.forEach((key, value) {
      value.forEach((element) {
        opponent.arrowScores[counter].add(element);
      });
      counter++;
    });

    opponent.endScores = [];
    opponent.arrowScores.forEach((end) {
      opponent.endScores.add(end.reduce((a, b) => a + b));
    });

    return opponent;
  }

  Future<List<int>> getAllOpponentIDs(int trainingID) async {
    Database db = await database;

    return await db.query(tableOpponents, where: 'trainingID = ?', whereArgs: [trainingID]).then((value) {
      List<int> opponentIDs = [];
      value.forEach((row) => opponentIDs.add(row['id']));
      return opponentIDs;
    });
  }

  Future<List<Archer>> getAllOpponents(int trainingID) async {
    List<int> opponentIDs = await getAllOpponentIDs(trainingID);
    List<Archer> opponents = [];

    for (int id in opponentIDs) {
      print(id);
      await getOpponent(id).then((archer) => opponents.add(archer));
    }

    return opponents;
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
      if (!scoresByEnd.containsKey(element["endID"])) {
        scoresByEnd[element["endID"]] = [];
      }
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
          updateScore(arrow); // todo check if its alright not to use await here NO NOT GOOD check getAllOpponents() for better solution
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
