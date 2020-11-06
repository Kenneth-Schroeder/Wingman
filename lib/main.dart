import 'package:flutter/material.dart';
import 'Overview.dart';

void main() {
  runApp(MyApp());
}

MaterialColor swatchify(MaterialColor color, int value) {
  return MaterialColor(color[value].hashCode, <int, Color>{
    50: color[value],
    100: color[value],
    200: color[value],
    300: color[value],
    400: color[value],
    500: color[value],
    600: color[value],
    700: color[value],
    800: color[value],
    900: color[value],
  });
}

/*
yellow ffeb3b
red f44336
blue 2196f3

teal 00695c
lime 827717

 */

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Archery',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: swatchify(Colors.blue, 800),
        //primaryColor: Color(0xff7A1C15), //061d80,5A0675
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Recent Training Sessions'),
    );
  }
}
