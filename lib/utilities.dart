import 'package:flutter/material.dart';
import 'dart:math';
import 'SizeConfig.dart';

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
  // todo make sure to use these
  return SizeConfig.screenWidth == null ? 1 : SizeConfig.screenWidth;
}

double screenHeight() {
  return SizeConfig.screenHeight == null ? 1 : SizeConfig.screenHeight;
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

Widget helpOverlay(String image, bool showOverlay, Function onTap) {
  if (showOverlay) {
    return GestureDetector(
      child: Container(
        color: Colors.black,
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Image.asset(
              image,
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
      ),
      onTap: onTap,
      /*() {
        showHelpOverlay = false;
        setState(() {});
      },*/
    );
  }
  return Container();
}
