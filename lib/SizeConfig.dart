import 'package:flutter/material.dart';
import 'dart:math';

class SizeConfig {
  static MediaQueryData _mediaQueryData;
  static double screenWidth;
  static double screenHeight;
  static double fullScreenHeight;
  static double blockSizeHorizontal;
  static double blockSizeVertical;

  void init(BuildContext context) {
    // todo also get orientation of screen etc
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    fullScreenHeight = _mediaQueryData.size.height + _mediaQueryData.viewInsets.bottom;
    screenHeight = _mediaQueryData.size.height -
        kToolbarHeight -
        kBottomNavigationBarHeight -
        kTextTabBarHeight; //- _mediaQueryData.padding.top  - _mediaQueryData.padding.bottom
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }

  Offset appBarHeight() {
    return Offset(0, kToolbarHeight + _mediaQueryData.padding.top);
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

  double maxDim() {
    return max(screenWidth, screenHeight);
  }
}
