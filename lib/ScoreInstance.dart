import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'TrainingInstance.dart';
import 'ArrowInformation.dart';
import 'database_service.dart';

class ScoreInstance {
  int shotID = -1;
  double relativeArrowRadius = 0.03; // percentage of target radius, which is normalized to 1
  int score = 0;
  int endID;
  ArrowInformation arrowInformation;
  double pRadius = 1.3; // polar radius
  double pAngle = 13 / 20 * pi; // polar angle
  int isUntouched = 1; // 1 == true

  ScoreInstance.scoreOnly(this.endID, this.score); // for opponent scores
  ScoreInstance(this.endID, this.relativeArrowRadius);
  ScoreInstance.positioned(this.endID, this.score, Offset position, double targetRadius) {
    // todo - is this used anymore?
    setWithCartesianCoordinates(position, targetRadius);
  }

  void setArrowInformation(ArrowInformation arrowInfo) {
    arrowInformation = arrowInfo;
  }

  ScoreInstance.fromMapAndDB(Map<String, dynamic> map, DatabaseService dbService)
      : assert(map["score"] != null),
        assert(map["endID"] != null),
        shotID = map["shotID"],
        relativeArrowRadius = map["relativeArrowRadius"],
        score = map["score"],
        endID = map["endID"],
        pRadius = map["pRadius"] == null ? -1 : map["pRadius"],
        pAngle = map["pAngle"] == null ? -1 : map["pAngle"],
        isUntouched = map["isUntouched"] == null ? 1 : map["isUntouched"] {
    if (map["arrowInformationID"] != null) {
      gatherArrowInformation(dbService, map["arrowInformationID"]);
    }
  }

  String getLabel() {
    if (arrowInformation == null) {
      return "";
    }

    return arrowInformation.label;
  }

  Future<bool> gatherArrowInformation(DatabaseService dbService, int id) async {
    arrowInformation = await dbService.getArrowInformationFromID(id);
    return true;
  }

  int _getArrowInformationID() {
    if (arrowInformation == null) {
      return null;
    }

    return arrowInformation.id;
  }

  Map<String, dynamic> toMap() {
    return {
      "relativeArrowRadius": this.relativeArrowRadius,
      "score": this.score,
      "endID": this.endID,
      "arrowInformationID": _getArrowInformationID(),
      "pRadius": this.pRadius,
      "pAngle": this.pAngle,
      "isUntouched": this.isUntouched,
    };
  }

  int fullTargetScore() {
    // range (0, 1] soll gequetscht werden in (11, 1] und dann in [10,0]
    double distance = pRadius - relativeArrowRadius;

    if (distance <= 0) {
      score = 10;
      return score;
    }
    if (distance > 1) {
      score = 0;
      return score;
    }

    // range (0, 1] for 10 to 1
    distance = -distance; // range [-1, 0) for 1 to 10
    distance += 1; // range [0, 1) for 1 to 10
    distance *= 10; // range [0, 10) for 1 to 10
    distance += 1; // range [1, 11) for 1 to 10

    score = distance.floor();

    return score;
  }

  int singleSpotScore() {
    int score = fullTargetScore();
    if (score <= 5) score = 0;
    return score;
  }

  int tripleSpotScore(double targetRadius) {
    score = 0;

    score = max(score, singleSpotScore());
    _moveForTriSpot(targetRadius, 1);
    score = max(score, singleSpotScore());
    _moveForTriSpot(targetRadius, -2);
    score = max(score, singleSpotScore());
    _moveForTriSpot(targetRadius, 1);

    return score;
  }

  int updateScore(TargetType targetType, double targetRadius) {
    switch (targetType) {
      case TargetType.Full:
        score = fullTargetScore();
        break;
      case TargetType.SingleSpot:
        score = singleSpotScore();
        break;
      case TargetType.TripleSpot:
        score = tripleSpotScore(targetRadius);
        break;
    }

    return score;
  }

  Offset getRelativeCartesianCoordinates(double targetRadius, TargetType targetType) {
    double radius = pRadius * targetRadius;
    double angle = pAngle;

    switch (targetType) {
      case TargetType.TripleSpot:
        List<Offset> spotOffsets = [];
        spotOffsets.add(Offset(radius * cos(angle), radius * sin(angle)));
        spotOffsets.add(spotOffsets.first + Offset(0, targetRadius * 1.1)); // todo hardcoded cross files
        spotOffsets.add(spotOffsets.first - Offset(0, targetRadius * 1.1));

        Offset minOffset = spotOffsets.first;
        spotOffsets.forEach((offset) {
          if (offset.distance < minOffset.distance) {
            minOffset = offset;
          }
        });
        return minOffset;

      default:
        return Offset(radius * cos(angle), radius * sin(angle));
    }
  }

  // TODO maybe move coordinates into separate class
  Offset getCartesianCoordinates(double targetRadius) {
    double radius = pRadius * targetRadius;
    double angle = pAngle;

    return Offset(radius * cos(angle), radius * sin(angle));
  }

  void setWithCartesianCoordinates(Offset offset, double targetRadius) {
    double radius = sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
    pAngle = atan2(offset.dy, offset.dx);
    pRadius = radius / targetRadius;
  }

  void _moveForTriSpot(double targetRadius, int direction) {
    Offset cartesian = getCartesianCoordinates(targetRadius);
    cartesian += Offset(0, targetRadius * 1.1 * direction);
    setWithCartesianCoordinates(cartesian, targetRadius);
  }

  void moveByOffset(Offset offset, double targetRadius, TargetType targetType) {
    // convert own coordinates to cartesian, add offset, convert back
    isUntouched = 0;
    Offset cartesian = getCartesianCoordinates(targetRadius);
    cartesian += offset;
    setWithCartesianCoordinates(cartesian, targetRadius);
    // updateScore(targetType, targetRadius);
  }

  void reset() {
    score = 0;
    pRadius = 1.3;
    pAngle = 13 / 20 * pi;
  }

  String toString() {
    return score.toString();
  }
}
