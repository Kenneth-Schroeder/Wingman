import 'package:flutter/cupertino.dart';
import 'dart:math';

class ScoreInstance {
  int shotID = -1;
  double arrowRadius = 0.05; // percentage of target radius, which is normalized to 1
  int score = 0;
  int endID;
  double pRadius = 1.3; // polar radius
  double pAngle = 13 / 20 * pi; // polar angle

  ScoreInstance(this.endID);
  ScoreInstance.positioned(this.endID, this.score, Offset position, double targetRadius) {
    setWithCartesianCoordinates(position, targetRadius);
  }

  ScoreInstance.fromMap(Map<String, dynamic> map)
      : assert(map["score"] != null),
        assert(map["endID"] != null),
        shotID = map["shotID"],
        arrowRadius = map["arrowRadius"],
        score = map["score"],
        endID = map["endID"],
        pRadius = map["pRadius"] == null ? -1 : map["pRadius"],
        pAngle = map["pAngle"] == null ? -1 : map["pAngle"];

  Map<String, dynamic> toMap() {
    return {
      "arrowRadius": this.arrowRadius,
      "score": this.score,
      "endID": this.endID,
      "pRadius": this.pRadius,
      "pAngle": this.pAngle,
    };
  }

  int updateScore() {
    // range (0, 1] soll gequetscht werden in (11, 1] und dann in [10,0]
    double distance = pRadius - arrowRadius;

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
    // todo make sure it works with 10s
    // TODO different calculation for different target type
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

  void moveByOffset(Offset offset, double targetRadius) {
    // convert own coordinates to cartesian, add offset, convert back
    Offset cartesian = getCartesianCoordinates(targetRadius);
    cartesian += offset;
    setWithCartesianCoordinates(cartesian, targetRadius);
    updateScore();
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
