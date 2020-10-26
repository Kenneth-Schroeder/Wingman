import 'package:flutter/material.dart';
import 'dart:math';
import 'SizeConfig.dart';
import 'ScoreInstance.dart';
import 'ArrowInformation.dart';
import 'TrainingInstance.dart';
import 'package:vector_math/vector_math.dart' as vecMath;

class Archer {
  List<int> endScores = [0];
  List<List<int>> arrowScores = [[]];
  String name;
  Archer(this.name);

  void addToEnd(int endIndex, int number) {
    endScores[endIndex] += number;
  }

  int scoreOfEnd(int endIndex) {
    return endScores[endIndex];
  }

  int totalScoreUpToEnd(int endIndex) {
    return endScores.sublist(0, endIndex + 1).reduce((a, b) => a + b);
  }
}

double screenWidth() {
  return SizeConfig.screenWidth == null ? 1 : SizeConfig.screenWidth;
}

double screenHeight() {
  return SizeConfig.screenHeight == null ? 1 : SizeConfig.screenHeight;
}

double minScreenDimension() {
  return SizeConfig.minDim == null ? 1 : SizeConfig.minDim;
}

double maxScreenDimension() {
  return SizeConfig.maxDim == null ? 1 : SizeConfig.maxDim;
}

double fullScreenHeight() {
  return SizeConfig.fullScreenHeight == null ? 1 : SizeConfig.fullScreenHeight;
}

Offset screenThreeSideCenter() {
  return SizeConfig.threeSideCenter == null ? Offset(0, 0) : SizeConfig.threeSideCenter;
}

Offset screenAppBarHeight() {
  return SizeConfig.appBarHeight == null ? Offset(0, 0) : SizeConfig.appBarHeight;
}

Offset screenCenter() {
  return SizeConfig.center == null ? Offset(0, 0) : SizeConfig.center;
}

double polarDistance(double r1, double a1, double r2, double a2) {
  return sqrt(r1 * r1 + r2 * r2 - 2 * r1 * r2 * cos(a1 - a2));
}

List argMin(List<double> numbers) {
  double minValue = double.maxFinite;
  int minIndex = 0;

  for (var i = 0; i < numbers.length; i++) {
    if (numbers[i] < minValue) {
      minValue = numbers[i];
      minIndex = i;
    }
  }

  return [minValue, minIndex];
}

List localCartesianToRelativePolar(Offset center, double x, double y) {
  double rX = x - center.dx; // x coordinate relative to target center
  double rY = y - center.dy; // y coordinate relative to target center

  double pRadius = sqrt(rX * rX + rY * rY);
  double pAngle = atan2(rY, rX);

  return [pRadius, pAngle];
}

double dist(Offset pointA, Offset pointB) {
  return (pointA - pointB).distance;
}

double chPerimeter(List<Offset> points) {
  double p = 0;
  for (int i = 1; i < points.length; i++) {
    p += dist(points[i - 1], points[i]);
  }
  p += dist(points.first, points.last);

  return p;
}

double crossProduct(Offset O, Offset A, Offset B) {
  return (A.dx - O.dx) * (B.dy - O.dy) - (A.dy - O.dy) * (B.dx - O.dx);
}

List<Offset> convexHull(List<Offset> points) {
  int n = points.length;
  int k = 0;

  if (n <= 3) return points;

  List<Offset> ans = new List(n * 2);

  // Sort points lexicographically
  points.sort((a, b) {
    if (a == b) return 0;
    if (a.dx < b.dx || (a.dx == b.dx && a.dy < b.dy)) {
      return 1;
    }
    return -1;
  });

  // Build lower hull
  for (int i = 0; i < n; ++i) {
    while (k >= 2 && crossProduct(ans[k - 2], ans[k - 1], points[i]) <= 0) k--;
    ans[k++] = points[i];
  }

  // Build upper hull
  for (int i = n - 1, t = k + 1; i > 0; --i) {
    while (k >= t && crossProduct(ans[k - 2], ans[k - 1], points[i - 1]) <= 0) k--;
    ans[k++] = points[i - 1];
  }

  // Resize the array to desired size
  return ans.getRange(0, k - 1).toList();
}

Widget positionWhereSpace(Rect rectangle, Widget child) {
  bool moreSpaceAbove = rectangle.top > fullScreenHeight() - rectangle.bottom;
  double bottomSpacing = fullScreenHeight() - rectangle.top + 15.0;

  if (moreSpaceAbove) {
    return Positioned(
      bottom: bottomSpacing,
      width: screenWidth(),
      child: child,
    );
  }

  return Positioned(
    top: rectangle.bottom + 15.0,
    width: screenWidth(),
    child: child,
  );
}

double rootMeanSquareDist(List<Offset> positions) {
  if (positions == null || positions.isEmpty) {
    return 0;
  }

  double meanX = positions.map((e) => e.dx).reduce((a, b) => a + b) / positions.length;
  double meanY = positions.map((e) => e.dy).reduce((a, b) => a + b) / positions.length;
  double sum = 0;

  for (Offset o in positions) {
    sum += pow(o.dx - meanX, 2) + pow(o.dy - meanY, 2);
  }
  sum = sqrt(sum / positions.length);
  return sum;
}

List<ScoreInstance> allArrows(List<List<ScoreInstance>> arrows, [int id]) {
  if (id != null) {
    return arrows
        .expand((element) => element)
        .toList()
        .where((element) => element.isUntouched == 0)
        .toList()
        .where((element) => element.arrowInformation.id == id)
        .toList();
  }
  return arrows.expand((element) => element).toList().where((element) => element.isUntouched == 0).toList();
}

List<ScoreInstance> allArrowsExcept(List<List<ScoreInstance>> arrows, [int id]) {
  if (id != null) {
    return arrows
        .expand((element) => element)
        .toList()
        .where((element) => element.isUntouched == 0)
        .toList()
        .where((element) => element.arrowInformation.id != id)
        .toList();
  }
  return [];
}

Offset normGroupCenter(List<ScoreInstance> arrows, double targetDiameterCM, TargetType targetType) {
  if (arrows == null || arrows.isEmpty) {
    return Offset(0, 0);
  }

  return arrows.map((e) => e.getRelativeCartesianCoordinates(targetDiameterCM, targetType)).reduce((a, b) => a + b) / arrows.length.toDouble() / targetDiameterCM;
}

List<ArrowInformation> allArrowInformation(List<List<ScoreInstance>> arrows) {
  return allArrows(arrows).map((e) => e.arrowInformation).toSet().toList();
}

//https://sites.math.northwestern.edu/~mlerma/papers/princcomp2d.pdf
List<Offset> calculateConfidenceEllipse(List<ScoreInstance> arrows, double targetRadius, TargetType targetType) {
  List<double> xCoordinates = allArrows([arrows]).map((e) => e.getRelativeCartesianCoordinates(targetRadius, targetType).dx).toList();
  List<double> yCoordinates = allArrows([arrows]).map((e) => e.getRelativeCartesianCoordinates(targetRadius, targetType).dy).toList();

  if (xCoordinates == null || xCoordinates.isEmpty || xCoordinates.length != yCoordinates.length) {
    return [];
  }

  int n = xCoordinates.length;
  double xMean = xCoordinates.reduce((a, b) => a + b) / n;
  double yMean = yCoordinates.reduce((a, b) => a + b) / n;

  List<double> xCoordinatesNorm = xCoordinates.map((e) => e - xMean).toList();
  List<double> yCoordinatesNorm = yCoordinates.map((e) => e - yMean).toList();

  // means are 0 now
  double sigmaX_squared = xCoordinatesNorm.map((e) => e * e).reduce((a, b) => a + b) / n;
  double sigmaY_squared = yCoordinatesNorm.map((e) => e * e).reduce((a, b) => a + b) / n;
  double sigmaXY = 0;

  for (int i = 0; i < n; i++) {
    sigmaXY += xCoordinatesNorm[i] * yCoordinatesNorm[i];
  }
  sigmaXY /= n;

  double rootResult = sqrt(pow(sigmaX_squared - sigmaY_squared, 2) + 4 * sigmaXY * sigmaXY);
  double lambdaPlus = (sigmaX_squared + sigmaY_squared + rootResult) / 2;
  double lambdaMinus = (sigmaX_squared + sigmaY_squared - rootResult) / 2;

  vecMath.Vector2 vPlus = vecMath.Vector2(sigmaX_squared + sigmaXY - lambdaMinus, sigmaY_squared + sigmaXY - lambdaMinus).normalized();
  vecMath.Vector2 vMinus = vecMath.Vector2(sigmaX_squared + sigmaXY - lambdaPlus, sigmaY_squared + sigmaXY - lambdaPlus).normalized();

  return [Offset(vPlus.x, vPlus.y) * sqrt(lambdaPlus) * 2, Offset(vMinus.x, vMinus.y) * sqrt(lambdaMinus) * 2];
}
