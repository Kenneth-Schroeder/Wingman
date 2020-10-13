import 'package:flutter/material.dart';
import 'database_service.dart';
import 'SizeConfig.dart';
import 'ArrowInformation.dart';

class QuiverOrganizer extends StatefulWidget {
  QuiverOrganizer(this.numArrowsToSelect, this.selectedArrowInformationIDs, {Key key}) : super(key: key);

  int numArrowsToSelect;
  List<int> selectedArrowInformationIDs = [];

  @override
  _QuiverOrganizerState createState() => _QuiverOrganizerState();
}

class _QuiverOrganizerState extends State<QuiverOrganizer> {
  DatabaseService dbService;
  bool startRoutineFinished = false;
  int selectedArrows = 0;
  List<ArrowSet> arrowSets;

  int initPosition = 0;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    arrowSets = await dbService.getAllArrowSets();

    for (var arrowSet in arrowSets) {
      for (var arrowInfo in arrowSet.arrowInfos) {
        if (widget.selectedArrowInformationIDs.contains(arrowInfo.id)) {
          arrowInfo.selected = true;
          selectedArrows += 1;
        }
      }
    }

    SizeConfig().init(context);

    startRoutineFinished = true;
    setState(() {});
  }

  double _screenWidth() {
    // todo make sure to use these
    return SizeConfig.screenWidth == null ? 1 : SizeConfig.screenWidth;
  }

  DataColumn tableColumn(String text, bool numeric) {
    return DataColumn(
      label: Expanded(
        child: Text(text, textAlign: TextAlign.center, textScaleFactor: 1.3),
      ),
      numeric: numeric,
    );
  }

  DataCell tableCell(ArrowInformation arrowInformation) {
    return DataCell(
      Center(
        child: Container(
          padding: EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(32),
            ),
            child: TextFormField(
              key: Key(arrowInformation.label),
              decoration: new InputDecoration(
                suffixIcon: Icon(Icons.edit),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(left: 15, bottom: 11, top: 11, right: 15),
                hintText: "",
              ),
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
              initialValue: arrowInformation.label,
              keyboardType: TextInputType.name,
              onChanged: (text) {
                arrowInformation.label = text;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget arrowTableForSetWithIndex(int index) {
    List<DataRow> rows = [];

    for (int i = 0; i < arrowSets[index].arrowInfos.length; i++) {
      List<DataCell> cells = [];
      cells.add(tableCell(arrowSets[index].arrowInfos[i]));
      cells.add(
        DataCell(
          Center(
            child: Checkbox(
              value: arrowSets[index].arrowInfos[i].selected,
              onChanged: (bool value) {
                setState(() {
                  if (value) {
                    selectedArrows += 1;
                  } else {
                    selectedArrows -= 1;
                  }

                  arrowSets[index].arrowInfos[i].selected = value;
                });
              },
            ),
          ),
        ),
      );

      cells.add(
        DataCell(
          Center(
            child: IconButton(
              icon: Icon(Icons.remove_circle_outline),
              onPressed: () {
                deleteArrowInformation(index, i);
              },
            ),
          ),
        ),
      );

      rows.add(DataRow(cells: cells));
      cells = [];
    }

    List<DataColumn> columns = [
      tableColumn('Arrow Label', false),
      tableColumn('Select', false),
      tableColumn('Delete', false),
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          DataTable(
            showCheckboxColumn: true,
            columns: columns,
            rows: rows,
            columnSpacing: 25,
            dataRowHeight: 60,
          ),
          Container(
            width: 100,
            child: RaisedButton(
              color: Colors.greenAccent,
              padding: EdgeInsets.all(0),
              //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.0)),
              //padding: EdgeInsets.all(4.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    Text(
                      "add arrow",
                      textScaleFactor: 0.8,
                    )
                  ],
                ),
              ),
              onPressed: () {
                arrowSets[index].addArrow(arrowSets[index].arrowInfos.length.toString());
                setState(() {});
                return;
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Text(
              "selected " + selectedArrows.toString() + "/" + widget.numArrowsToSelect.toString() + " arrows",
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> deleteArrowInformation(int setIndex, int infoIndex) async {
    await dbService.deleteArrowInformation(arrowSets[setIndex].arrowInfos[infoIndex]);
    arrowSets[setIndex].arrowInfos.removeAt(infoIndex);
    setState(() {});
  }

  Future<bool> deleteArrowSetAtIndex(int index) async {
    await dbService.deleteArrowSet(arrowSets[index]);
    arrowSets.removeAt(index);
    setState(() {});
  }

  Widget tabBodyGenerator(int index, int length) {
    if (index == length) {
      return Center(
        child: Text(
          "Press the green button on top\nto create a new set of arrows.",
          textScaleFactor: 1.3,
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                //width: _screenWidth(),
                padding: EdgeInsets.only(top: 20), //.all(50),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: _screenWidth() * 0.3,
                        child: TextFormField(
                          key: Key(arrowSets[index].label),
                          initialValue: arrowSets[index].label,
                          decoration: const InputDecoration(
                            labelText: 'Change Set Label',
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(25.0),
                              ),
                              borderSide: BorderSide(),
                            ),
                          ),
                          keyboardType: TextInputType.name,
                          onChanged: (text) {
                            arrowSets[index].label = text;
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(20),
                        width: 120,
                        child: Container(
                          width: 100.0,
                          height: 50.0,
                          child: RaisedButton(
                            color: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0), side: BorderSide(color: Colors.red)),
                            child: Icon(Icons.delete),
                            onPressed: () {
                              deleteArrowSetAtIndex(index);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              arrowTableForSetWithIndex(index),
            ],
          ),
        ),
      ),
    );
  }

  Widget tabHeaderGenerator(BuildContext context, int index, int length) {
    if (index == length) {
      return Container(
        width: _screenWidth() / 7,
        child: SizedBox(
          width: double.infinity, // match_parent
          height: double.infinity,
          child: RaisedButton(
            color: Colors.greenAccent,
            padding: EdgeInsets.all(0),
            //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.0)),
            //padding: EdgeInsets.all(4.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  Text(
                    "add set",
                    textScaleFactor: 0.8,
                  )
                ],
              ),
            ),
            onPressed: () {
              arrowSets.add(ArrowSet("Set " + arrowSets.length.toString()));
              setState(() {});
            },
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(15),
      child: Text(arrowSets[index].label),
    );
  }

  Widget createTabScreen() {
    return CustomTabView(
      initPosition: initPosition,
      itemCount: arrowSets.length + 1,
      tabBuilder: (context, index) {
        return Tab(
          child: tabHeaderGenerator(context, index, arrowSets.length),
        );
      },
      pageBuilder: (context, index) => tabBodyGenerator(index, arrowSets.length),
      onPositionChange: (index) {
        initPosition = index;
        setState(() {});
      },
      onScroll: (position) {},
    );
  }

  Future<bool> onSaveAndContinue() async {
    await onLeave(); // guarantee that onLeave gets called first
    List<ArrowSet> arrowSetsWithID = await dbService.getAllArrowSets(); // guarantee that all elements have an id
    List<int> arrowInformationIDs = [];

    assert(arrowSets.length == arrowSetsWithID.length);
    for (int i = 0; i < arrowSets.length; i++) {
      assert(arrowSets[i].arrowInfos.length == arrowSetsWithID[i].arrowInfos.length);
      for (int j = 0; j < arrowSets[i].arrowInfos.length; j++) {
        if (arrowSets[i].arrowInfos[j].selected) {
          arrowInformationIDs.add(arrowSetsWithID[i].arrowInfos[j].id);
        }
      }
    }

    Navigator.pop(context, arrowInformationIDs);
    return true;
  }

  Widget _bottomBar() {
    if (selectedArrows != widget.numArrowsToSelect) {
      return BottomAppBar(
        color: Colors.green,
        child: Container(
          width: 0,
          height: 0,
        ),
      );
    }

    return BottomAppBar(
      color: Colors.white,
      child: RaisedButton(
        color: Colors.green,
        padding: EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.save),
            Text("Save and Continue"),
          ],
        ),
        onPressed: onSaveAndContinue,
      ),
    );
  }

  Future<bool> onLeave() async {
    await dbService.updateAllArrowSets(arrowSets);
    return true;
  }

  Widget emptyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quiver"),
      ),
      body: Text("loading..."),
    );
  }

  Widget showContent() {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text("Quiver"),
        ),
        bottomNavigationBar: _bottomBar(),
        body: SafeArea(
          child: createTabScreen(),
        ),
      ),
      onWillPop: onLeave,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (startRoutineFinished) {
      return showContent();
    }

    return emptyScreen();
  }
}

/// Implementation ------------------------------------------------------------------------------------------

class CustomTabView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder tabBuilder;
  final IndexedWidgetBuilder pageBuilder;
  final Widget stub;
  final ValueChanged<int> onPositionChange;
  final ValueChanged<double> onScroll;
  final int initPosition;

  CustomTabView({
    @required this.itemCount,
    @required this.tabBuilder,
    @required this.pageBuilder,
    this.stub,
    this.onPositionChange,
    this.onScroll,
    this.initPosition,
  });

  @override
  _CustomTabsState createState() => _CustomTabsState();
}

class _CustomTabsState extends State<CustomTabView> with TickerProviderStateMixin {
  TabController controller;
  int _currentCount;
  int _currentPosition;

  onTap() {
    if (controller.index == widget.itemCount - 1) {
      int index = controller.previousIndex;
      setState(() {
        controller.index = index;
      });
    }
  }

  @override
  void initState() {
    _currentPosition = widget.initPosition ?? 0;
    controller = TabController(
      length: widget.itemCount,
      vsync: this,
      initialIndex: _currentPosition,
    );
    controller.addListener(onPositionChange);
    controller.addListener(onTap);
    controller.animation.addListener(onScroll);
    _currentCount = widget.itemCount;
    super.initState();
  }

  @override
  void didUpdateWidget(CustomTabView oldWidget) {
    if (_currentCount != widget.itemCount) {
      controller.animation.removeListener(onScroll);
      controller.removeListener(onPositionChange);
      controller.removeListener(onTap);
      controller.dispose();

      if (widget.initPosition != null) {
        _currentPosition = widget.initPosition;
      }

      if (_currentPosition > widget.itemCount - 1) {
        _currentPosition = widget.itemCount - 1;
        _currentPosition = _currentPosition < 0 ? 0 : _currentPosition;
        if (widget.onPositionChange is ValueChanged<int>) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onPositionChange(_currentPosition);
            }
          });
        }
      }

      _currentCount = widget.itemCount;
      setState(() {
        controller = TabController(
          length: widget.itemCount,
          vsync: this,
          initialIndex: _currentPosition,
        );
        controller.addListener(onPositionChange);
        controller.addListener(onTap);
        controller.animation.addListener(onScroll);
      });
    } else if (widget.initPosition != null) {
      controller.animateTo(widget.initPosition);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.animation.removeListener(onScroll);
    controller.removeListener(onPositionChange);
    controller.removeListener(onTap);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount < 1) return widget.stub ?? Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          color: Theme.of(context).primaryColor,
          alignment: Alignment.center,
          child: TabBar(
            labelPadding: EdgeInsets.all(0),
            isScrollable: true,
            controller: controller,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)), color: Colors.white),

            /*labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).hintColor,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
            */

            tabs: List.generate(
              widget.itemCount,
              (index) => widget.tabBuilder(context, index),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            controller: controller,
            children: List.generate(
              widget.itemCount,
              (index) => widget.pageBuilder(context, index),
            ),
          ),
        ),
      ],
    );
  }

  onPositionChange() {
    if (!controller.indexIsChanging) {
      _currentPosition = controller.index;
      if (widget.onPositionChange is ValueChanged<int>) {
        widget.onPositionChange(_currentPosition);
      }
    }
  }

  onScroll() {
    if (widget.onScroll is ValueChanged<double>) {
      widget.onScroll(controller.animation.value);
    }
  }
}
