import 'package:flutter/material.dart';
import 'dart:math';

class SizeConfig {
  static MediaQueryData _mediaQueryData;
  static double screenWidth;
  static double screenHeight;
  static double fullScreenHeight;
  static double blockSizeHorizontal;
  static double blockSizeVertical;
  static double minDim;
  static double maxDim;
  static Offset threeSideCenter;
  static Offset appBarHeight;
  static Offset center;

  void init(BuildContext context) {
    // todo also get orientation of screen etc
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    fullScreenHeight = _mediaQueryData.size.height + _mediaQueryData.viewInsets.bottom;
    screenHeight =
        _mediaQueryData.size.height - kToolbarHeight - kBottomNavigationBarHeight - kTextTabBarHeight; //- _mediaQueryData.padding.top  - _mediaQueryData.padding.bottom
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    minDim = min(screenWidth, screenHeight);
    appBarHeight = Offset(0, kToolbarHeight + _mediaQueryData.padding.top);
    threeSideCenter = Offset(minDim / 2, minDim / 2);
    center = Offset(screenWidth / 2, screenHeight / 2);
    maxDim = max(screenWidth, screenHeight);
  }
}
