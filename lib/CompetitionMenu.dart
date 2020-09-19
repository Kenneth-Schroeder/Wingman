import 'package:flutter/material.dart';

class CompetitionMenu extends StatefulWidget {
  CompetitionMenu({Key key}) : super(key: key);

  @override
  _CompetitionMenuState createState() => _CompetitionMenuState();
}

class _CompetitionMenuState extends State<CompetitionMenu> {
  double sliderValue = 5;
  List<int> selected = [-1, -1, -1];

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {}

  Widget floatingBoxWrapper(String image, String title, Color textColor, Alignment titleAlign, int category, int option) {
    BorderRadius radius = BorderRadius.only(bottomLeft: Radius.circular(10), topRight: Radius.circular(10));
    bool highlighted = selected[category] == option;

    Widget imageWidget = ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.grey[900],
        BlendMode.multiply,
      ),
      child: Image.asset(
        "assets/images/" + image,
        fit: BoxFit.cover,
      ),
    );

    if (highlighted) {
      imageWidget = Image.asset(
        "assets/images/" + image,
        fit: BoxFit.cover,
      );
    }

    return Expanded(
      child: Stack(
        children: [
          Container(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: GestureDetector(
                onTap: () {
                  selected[category] = option;
                  setState(() {});
                },
                child: imageWidget,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.8),
                  spreadRadius: 3,
                  blurRadius: 6,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: titleAlign,
              child: Container(
                padding: EdgeInsets.all(4),
                //margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.85),
                  borderRadius: radius,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // images from https://svgsilh.com/image/2025609.html and https://svgsilh.com/image/156849.html
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Competition Simulation"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              floatingBoxWrapper("outdoor.jpg", "Outdoors", Colors.white, Alignment.bottomLeft, 0, 0),
              SizedBox(width: 20),
              floatingBoxWrapper("indoor.jpg", "Indoors", Colors.white, Alignment.topRight, 0, 1),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              floatingBoxWrapper("female.png", "Female", Colors.white, Alignment.bottomLeft, 1, 0),
              SizedBox(width: 20),
              floatingBoxWrapper("male.png", "Male", Colors.white, Alignment.topRight, 1, 1),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              floatingBoxWrapper("qualification.jpg", "Qualifying", Colors.white, Alignment.bottomLeft, 2, 0),
              SizedBox(width: 20),
              floatingBoxWrapper("finals.jpg", "Finals", Colors.white, Alignment.topRight, 2, 1),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Column(
              children: [
                Text(
                  "DIFFICULTY",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Slider(
                  value: sliderValue,
                  onChanged: (newVal) {
                    sliderValue = newVal;
                    setState(() {});
                  },
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: sliderValue.toInt().toString(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 22),
                      child: Text("BEGINNER", style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 22),
                      child: Text("INHUMAN", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.8),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
