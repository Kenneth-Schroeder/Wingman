import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'TrainingInstance.dart';
import 'ScoreInstance.dart';
import 'TargetPage.dart'; // todo move Archer definition
import 'ArrowInformation.dart';

final tableTrainings = "trainings";
final tableOpponents = "opponents";
final tableEnds = "ends";
final tableScores = "scores";
final tableArrowSets = "arrowSets";
final tableArrowInfo = "arrowInfos";
final tableTrainingArrowConnector = "trainingArrowConnector";

class DatabaseService {
  Future<Database> database;

  DatabaseService._();

  // https://github.com/fluttercommunity/get_it/issues/4
  static Future<DatabaseService> create() async {
    var emptyDB = DatabaseService._();
    await emptyDB.initDatabase();
    return emptyDB;
  }

  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  initDatabase() async {
    database = openDatabase(
      join(await getDatabasesPath(), 'beautiful_alarm.db'),
      // When the database is first created, create a table to store data.
      onConfigure: _onConfigure,
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
            arrowDiameterMM REAL,
            creationTime DATETIME
            )
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableOpponents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            trainingID INTEGER NOT NULL,
            FOREIGN KEY (trainingID) REFERENCES $tableTrainings (id) ON DELETE CASCADE 
            )
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableEnds(
            endID INTEGER PRIMARY KEY AUTOINCREMENT,
            arrowCount INTEGER,
            trainingID INTEGER,
            opponentID INTEGER,
            FOREIGN KEY (trainingID) REFERENCES $tableTrainings (id) ON DELETE CASCADE,
            FOREIGN KEY (opponentID) REFERENCES $tableOpponents (id) ON DELETE CASCADE 
            )
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableArrowSets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL 
            )
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableArrowInfo(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            setID INTEGER NOT NULL,
            label TEXT NOT NULL,
            FOREIGN KEY (setID) REFERENCES $tableArrowSets (id) ON DELETE CASCADE 
            ) 
          ''',
        );
        // TODO check all on delete cascades if correct
        db.execute(
          '''CREATE TABLE $tableScores(
            shotID INTEGER PRIMARY KEY AUTOINCREMENT,
            relativeArrowRadius REAL,
            score INTEGER,
            pRadius REAL,
            pAngle REAL,
            isLocked INTEGER,
            isUntouched INTEGER,
            arrowInformationID INTEGER,
            endID INTEGER NOT NULL,
            FOREIGN KEY (arrowInformationID) REFERENCES $tableArrowInfo (id) ON DELETE SET NULL,
            FOREIGN KEY (endID) REFERENCES $tableEnds (endID) ON DELETE CASCADE
            ) 
          ''',
        );
        db.execute(
          '''CREATE TABLE $tableTrainingArrowConnector(
            trainingID INTEGER NOT NULL,
            arrowID INTEGER NOT NULL,
            FOREIGN KEY (trainingID) REFERENCES $tableTrainings (id) ON DELETE CASCADE,
            FOREIGN KEY (arrowID) REFERENCES $tableArrowInfo (id) ON DELETE CASCADE,
            PRIMARY KEY (trainingID, arrowID)
            ) 
          ''',
        ); // ,
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  Future<ArrowInformation> getArrowInformationFromID(int id) async {
    Database db = await database;
    ArrowInformation result;

    var mapRows = await db.query(tableArrowInfo, where: 'id = ?', whereArgs: [id]);
    result = ArrowInformation.fromMap(mapRows.first);
    return result;
  }

  Future<bool> addArrowInfoToTraining(List<int> arrowInformationIDs, int trainingID) async {
    Database db = await database;
    for (var arrowInfoID in arrowInformationIDs) {
      await db.insert(tableTrainingArrowConnector, {"trainingID": trainingID, "arrowID": arrowInfoID});
    }
    return true;
  }

  Future<List<ArrowInformation>> getArrowInformationToTraining(int trainingID) async {
    Database db = await database;
    List<ArrowInformation> result = [];

    List<Map> rows = await db.rawQuery("SELECT * "
        "FROM $tableArrowInfo "
        "INNER JOIN $tableTrainingArrowConnector ON $tableTrainingArrowConnector.arrowID = $tableArrowInfo.id "
        "WHERE $tableTrainingArrowConnector.trainingID == $trainingID");

    for (var row in rows) {
      result.add(ArrowInformation.fromMap(row));
    }

    return result;
  }

  Future<int> updateArrowInformation(ArrowInformation arrowInformation, int setID) async {
    Database db = await database;
    int updateCount =
        await db.update(tableArrowInfo, arrowInformation.toMapWithSetID(setID), where: 'id = ?', whereArgs: [arrowInformation.id]);
    return updateCount;
  }

  Future<int> updateArrowSet(ArrowSet arrowSet) async {
    Database db = await database;
    int updateCount = await db.update(tableArrowSets, arrowSet.toMap(), where: 'id = ?', whereArgs: [arrowSet.id]);
    return updateCount;
  }

  Future<bool> addArrowInfoToSet(ArrowInformation arrowInformation, int setID) async {
    Database db = await database;
    await db.insert(tableArrowInfo, arrowInformation.toMapWithSetID(setID));
    return true;
  }

  Future<bool> addArrowSetWithInfos(ArrowSet set) async {
    Database db = await database;
    int setID = await db.insert(tableArrowSets, set.toMap());
    for (var arrow in set.arrowInfos) {
      await addArrowInfoToSet(arrow, setID);
    }
    return true;
  }

  Future<bool> updateAllArrowSets(List<ArrowSet> arrowSets) async {
    Database db = await database;
    for (var arrowSet in arrowSets) {
      if (arrowSet.id != null) {
        await updateArrowSet(arrowSet);
        for (var arrowInfo in arrowSet.arrowInfos) {
          if (arrowInfo.id != null) {
            await updateArrowInformation(arrowInfo, arrowSet.id);
          } else {
            await addArrowInfoToSet(arrowInfo, arrowSet.id);
          }
        }
      } else {
        await addArrowSetWithInfos(arrowSet);
      }
    }

    return true;
  }

  Future<List<ArrowSet>> getAllArrowSets() async {
    Database db = await database;
    List<ArrowSet> arrowSets = [];

    var setsTable = await db.query(tableArrowSets);
    for (var set in setsTable) {
      List<ArrowInformation> arrows = [];
      await db.query(tableArrowInfo, where: 'setID = ?', whereArgs: [set['id']]).then((arrowsTable) {
        for (var arrow in arrowsTable) {
          arrows.add(ArrowInformation.fromMap(arrow));
        }
      });

      arrowSets.add(ArrowSet.fromMap({
        ...set,
        ...{"arrowInfos": arrows}
      }));
    }

    return arrowSets;
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

    for (var end in archer.arrowScores) {
      // update arrows that are in DB already and insert new ones for those that have no ID
      addOpponentsEnd(opponentID, end.length).then((endID) {
        for (var score in end) {
          addScore(ScoreInstance.scoreOnly(endID, score)); // TODO this uses unnecessarily much storage
        }
      });
    }

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
    for (var element in endsMap) {
      if (!scoresByEnd.containsKey(element["endID"])) {
        scoresByEnd[element["endID"]] = [];
      }
      scoresByEnd[element["endID"]].add(element["score"]);
    }

    opponent.arrowScores = new List.generate(scoresByEnd.length, (i) => []);
    int counter = 0;
    for (var end in scoresByEnd.values) {
      for (var arrow in end) {
        opponent.arrowScores[counter].add(arrow);
      }
      counter++;
    }

    opponent.endScores = [];
    for (var end in opponent.arrowScores) {
      opponent.endScores.add(end.reduce((a, b) => a + b));
    }

    return opponent;
  }

  Future<List<int>> getAllOpponentIDs(int trainingID) async {
    Database db = await database;

    return await db.query(tableOpponents, where: 'trainingID = ?', whereArgs: [trainingID]).then((table) {
      List<int> opponentIDs = [];
      for (var row in table) {
        opponentIDs.add(row['id']);
      }
      return opponentIDs;
    });
  }

  Future<List<Archer>> getAllOpponents(int trainingID) async {
    List<int> opponentIDs = await getAllOpponentIDs(trainingID);
    List<Archer> opponents = [];

    for (int id in opponentIDs) {
      await getOpponent(id).then((archer) => opponents.add(archer));
    }

    return opponents;
  }

  Future<int> addEnd(int trainingID) async {
    Database db = await database;
    int id = await db.insert(tableEnds, {"trainingID": trainingID});
    return id;
  }

  Future<int> addScore(ScoreInstance instance, [ArrowInformation arrowInformation]) async {
    Database db = await database;
    int id = await db.insert(tableScores, instance.toMap());
    return id;
  }

  Future<int> updateScore(ScoreInstance instance) async {
    Database db = await database;
    int updateCount = await db.update(tableScores, instance.toMap(), where: 'shotID = ?', whereArgs: [instance.shotID]);
    return updateCount;
  }

  void addDefaultScores(int endID, int number, double relativeArrowRadius, [List<ArrowInformation> arrowsInformation]) async {
    for (var i = 0; i < number; i++) {
      ScoreInstance instance = ScoreInstance(endID, relativeArrowRadius);

      if (arrowsInformation != null && arrowsInformation.length > i) {
        instance.setArrowInformation(arrowsInformation[i]);
      }

      addScore(instance);
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

    for (var item in endsMap) {
      if (!scoresByEnd.containsKey(item["endID"])) {
        scoresByEnd[item["endID"]] = [];
      }
      scoresByEnd[item["endID"]].add(ScoreInstance.fromMapAndDB(item, this));
    }

    return scoresByEnd;
  }

  Future<bool> updateAllEndsOfTraining(int trainingID, List<List<ScoreInstance>> arrows) async {
    // iterate over all ends and as long as arrows have an id, update them individually
    for (var end in arrows) {
      // update arrows that are in DB already and insert new ones for those that have no ID
      if (end.first.shotID != -1) {
        for (var arrow in end) {
          await updateScore(arrow);
        }
      } else {
        await addEnd(trainingID).then((endID) {
          for (var arrow in end) {
            arrow.endID = endID;
            addScore(arrow);
          }
        });
      }
    }

    return true;
  }

  Future<List<ScoreInstance>> getAllScoresOfEnd(int endID) async {
    Database db = await database;
    List<Map> scoresMap = await db.rawQuery(
        "SELECT * FROM $tableScores INNER JOIN $tableEnds ON $tableScores.endID = $tableEnds.endID WHERE $tableScores.endID == $endID");

    List<ScoreInstance> scores = [];
    for (var row in scoresMap) {
      scores.add(ScoreInstance.fromMapAndDB(row, this));
    }

    return scores;
  }

  Future<int> addTraining(TrainingInstance instance, List<int> arrowInformationIDs) async {
    Database db = await database;

    int trainingID = await db.insert(tableTrainings, instance.toMap());
    await addArrowInfoToTraining(arrowInformationIDs, trainingID);
    int endID = await addEnd(trainingID);
    List<ArrowInformation> fullArrowInformation = await getArrowInformationToTraining(trainingID);
    await addDefaultScores(endID, instance.arrowsPerEnd, instance.relativeArrowWidth(), fullArrowInformation);
    return trainingID;
  }

  void deleteTraining(int trainingID) async {
    Database db = await database;
    await db.delete(tableTrainings, where: 'id = ?', whereArgs: [trainingID]);
  }

  Future<bool> deleteEnd(int endID) async {
    Database db = await database;
    await db.delete(tableEnds, where: 'endID = ?', whereArgs: [endID]);
    return true;
  }

  Future<List<TrainingInstance>> getAllTrainings() async {
    Database db = await database;

    return db.query(tableTrainings).then((value) {
      List<TrainingInstance> trainings = [];
      for (var row in value) {
        trainings.add(TrainingInstance.fromMap(row));
      }
      return trainings;
    });
  }
}
