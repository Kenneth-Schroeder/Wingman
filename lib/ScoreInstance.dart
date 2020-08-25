import 'package:flutter/cupertino.dart';
import 'dart:math';

class ScoreInstance {
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
        score = map["score"],
        endID = map["endID"],
        pRadius = map["pRadius"] == null ? -1 : map["pRadius"],
        pAngle = map["pAngle"] == null ? -1 : map["pAngle"];

  Map<String, dynamic> toMap() {
    return {
      "score": this.score,
      "endID": this.endID,
      "pRadius": this.pRadius,
      "pAngle": this.pAngle,
    };
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
