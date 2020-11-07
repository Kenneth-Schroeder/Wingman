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
  int isLocked = 0;
  int isUntouched = 1; // 1 == true
  bool isX = false;

  ScoreInstance.scoreOnly(this.endID, this.score); // for opponent scores
  ScoreInstance(this.endID, this.relativeArrowRadius);

  ScoreInstance clone() {
    return ScoreInstance.fromMapAndArrowInformation({
      ...this.toMap(),
      ...{"shotID": this.shotID},
    }, _cloneArrowInformation());
  }

  ArrowInformation _cloneArrowInformation() {
    if (arrowInformation != null) {
      return arrowInformation.clone();
    }

    return null;
  }

  // todo check if compound scores are right and also adjust all the score calculations for compound if enabled later on
  String displayScore(bool recurve, bool indoor) {
    if (recurve) {
      if (isX && !indoor) {
        return "X";
      }
      return score.toString();
    } else {
      if (isX) {
        return "10";
      } else if (score == 10) {
        return "9";
      }
      return score.toString();
    }
  }

  void setArrowInformation(ArrowInformation arrowInfo) {
    arrowInformation = arrowInfo;
  }

  ScoreInstance.fromMapAndArrowInformation(Map<String, dynamic> map, ArrowInformation arrowInfo)
      : assert(map["score"] != null),
        assert(map["endID"] != null),
        shotID = map["shotID"],
        relativeArrowRadius = map["relativeArrowRadius"],
        score = map["score"],
        isX = map["isX"] == 1 ? true : false,
        endID = map["endID"],
        pRadius = map["pRadius"] == null ? -1 : map["pRadius"],
        pAngle = map["pAngle"] == null ? -1 : map["pAngle"],
        isLocked = map["isLocked"],
        isUntouched = map["isUntouched"] == null ? 1 : map["isUntouched"] {
    if (map["arrowInformationID"] != null) {
      arrowInformation = arrowInfo;
    }
  }

  void lock() {
    isLocked = 1;
  }

  String getLabel() {
    if (arrowInformation == null) {
      return "";
    }

    return arrowInformation.label;
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
      "isX": this.isX ? 1 : 0,
      "endID": this.endID,
      "arrowInformationID": _getArrowInformationID(),
      "pRadius": this.pRadius,
      "pAngle": this.pAngle,
      "isLocked": this.isLocked,
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

    isX = distance >= 10.5;
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

  double tripleSpotRadius(double targetRadius) {
    double radius = pRadius;
    _moveForTriSpot(targetRadius, 1);
    radius = min(radius, pRadius);
    _moveForTriSpot(targetRadius, -2);
    radius = min(radius, pRadius);
    _moveForTriSpot(targetRadius, 1);

    return radius;
  }

  Offset tripleSpotLocalRelativeCoordinates(double targetRadius) {
    // local spot, relative to local spot center

    Offset bestPosition = getCartesianCoordinates(targetRadius);
    _moveForTriSpot(targetRadius, 1);
    if (getCartesianCoordinates(targetRadius).distance < bestPosition.distance) {
      bestPosition = getCartesianCoordinates(targetRadius);
    }
    _moveForTriSpot(targetRadius, -2);
    if (getCartesianCoordinates(targetRadius).distance < bestPosition.distance) {
      bestPosition = getCartesianCoordinates(targetRadius);
    }
    _moveForTriSpot(targetRadius, 1);

    return bestPosition;
  }

  int updateScore(TargetType targetType, double targetRadius) {
    if (isLocked == 1) {
      return score;
    }

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

  // cartesian relative to center spot if tripleSpot used
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

  void setWithGlobalCartesianCoordinates(Offset offset, double targetRadius, Offset targetCenter) {
    setWithCartesianCoordinatesRelativeToTarget(offset - targetCenter, targetRadius);
  }

  void setWithCartesianCoordinatesRelativeToTarget(Offset offset, double targetRadius) {
    double radius = sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
    pAngle = atan2(offset.dy, offset.dx);
    pRadius = radius / targetRadius;
  }

  void _moveForTriSpot(double targetRadius, int direction) {
    Offset cartesian = getCartesianCoordinates(targetRadius);
    cartesian += Offset(0, targetRadius * 1.1 * direction);
    setWithCartesianCoordinatesRelativeToTarget(cartesian, targetRadius);
  }

  void moveByOffset(Offset offset, double targetRadius, TargetType targetType) {
    if (isLocked == 1) {
      return;
    }
    // convert own coordinates to cartesian, add offset, convert back
    isUntouched = 0;
    Offset cartesian = getCartesianCoordinates(targetRadius);
    cartesian += offset;
    setWithCartesianCoordinatesRelativeToTarget(cartesian, targetRadius);
    // updateScore(targetType, targetRadius);
  }

  void reset() {
    if (isLocked == 1) {
      return;
    }
    score = 0;
    pRadius = 1.3;
    pAngle = 13 / 20 * pi;
    isUntouched = 1;
    // position only temporary, will be set by targetpage to be on screen side
  }

  String toString() {
    return score.toString() + "-" + shotID.toString() + "at" + pRadius.toString() + "/" + pAngle.toString();
  }
}
