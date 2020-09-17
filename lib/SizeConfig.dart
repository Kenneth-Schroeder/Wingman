import 'package:flutter/material.dart';
import 'dart:math';

class SizeConfig {
  static MediaQueryData _mediaQueryData;
  static double screenWidth;
  static double screenHeight;
  static double blockSizeHorizontal;
  static double blockSizeVertical;

  void init(BuildContext context) {
    // todo also get orientation of screen etc
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height - kToolbarHeight - kBottomNavigationBarHeight - kTextTabBarHeight;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }

  Offset threeSideCenter() {
    // TODO this is not working for horizontal Screen
    double distance = min(screenWidth, screenHeight);
    return Offset(distance / 2, distance / 2);
  }

  Offset center() {
    // TODO this is not working for horizontal Screen?
    return Offset(screenWidth / 2, screenHeight / 2);
  }

  double minDim() {
    return min(screenWidth, screenHeight);
  }
}
