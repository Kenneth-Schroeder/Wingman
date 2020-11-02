import 'package:flutter/material.dart';
import 'database_service.dart';
import 'ArrowInformation.dart';
import 'package:flutter/services.dart';
import 'utilities.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'SizeConfig.dart';

class QuiverOrganizer extends StatefulWidget {
  QuiverOrganizer(this.numArrowsToSelect, this.selectedArrowInformationIDs, {Key key}) : super(key: key);

  int numArrowsToSelect;
  List<int> selectedArrowInformationIDs = [];

  @override
  _QuiverOrganizerState createState() => _QuiverOrganizerState();
}

class _QuiverOrganizerState extends State<QuiverOrganizer> with TickerProviderStateMixin {
  DatabaseService dbService;
  bool startRoutineFinished = false;
  int selectedArrows = 0;
  List<ArrowSet> arrowSets;
  GlobalKey _addSetKey = GlobalObjectKey("addSet");
  GlobalKey _editSetKey = GlobalObjectKey("editSet");
  GlobalKey _arrowRowKey = GlobalObjectKey("arrowRow");
  GlobalKey _arrowCountKey = GlobalObjectKey("arrowCount");
  ScrollController _scrollController = ScrollController();

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

  void showCoachMarkAddSet() {
    CoachMark coachMark = CoachMark();

    if (_addSetKey.currentContext == null) {
      return;
    }

    RenderBox target = _addSetKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = markRect.inflate(20.0);

    coachMark.show(
      targetContext: _addSetKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
    );
  }

  void showCoachMarkEditSet() {
    CoachMark coachMark = CoachMark();

    if (_editSetKey.currentContext == null) {
      int setIndex = initPosition;
      if (arrowSets.length > setIndex && arrowSets[setIndex].arrowInfos != null && arrowSets[setIndex].arrowInfos.isNotEmpty) {
        _scrollController
            .animateTo(
              _scrollController.position.minScrollExtent,
              duration: Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
            )
            .then((value) => showCoachMarkArrowRow());
      }
      return;
    }

    RenderBox target = _editSetKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 1.3, height: markRect.height * 1.1);

    coachMark.show(
      targetContext: _editSetKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Use these controls to edit the label of the current set or delete it completely.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
      onClose: () {
        int setIndex = initPosition;
        if (arrowSets.length > setIndex && arrowSets[setIndex].arrowInfos != null && arrowSets[setIndex].arrowInfos.isNotEmpty) {
          _scrollController
              .animateTo(
                _scrollController.position.minScrollExtent,
                duration: Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
              )
              .then((value) => showCoachMarkArrowRow());
        }
      },
    );
  }

  void showCoachMarkArrowCount() {
    CoachMark coachMark = CoachMark();

    if (_arrowCountKey.currentContext == null) {
      return;
    }

    RenderBox target = _arrowCountKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCenter(center: markRect.center, width: markRect.width * 1.3, height: markRect.height * 1.1);

    coachMark.show(
      targetContext: _arrowCountKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "When as many arrows are selected as specified on the previous form, a save button will appear.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
    );
  }

  void showCoachMarkArrowRow() {
    CoachMark coachMark = CoachMark();

    if (_arrowRowKey.currentContext == null) {
      _scrollController
          .animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(seconds: 1),
            curve: Curves.fastOutSlowIn,
          )
          .then((value) => showCoachMarkArrowCount());
      return;
    }

    RenderBox target = _arrowRowKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    Offset center = Offset(screenWidth() / 2, markRect.center.dy);
    markRect = Rect.fromCenter(center: center, width: markRect.width * 7, height: markRect.height * 1.4);

    coachMark.show(
      targetContext: _arrowRowKey.currentContext,
      markRect: markRect,
      markShape: BoxShape.rectangle,
      children: [
        positionWhereSpace(
          markRect,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Here you can edit the label of your arrow, select it for the current training session or delete it completely.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26.0,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      duration: null,
      onClose: () {
        _scrollController
            .animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
            )
            .then((value) => showCoachMarkArrowCount());
      },
    );
  }

  showAreYouSureDialog(BuildContext context, int arrowSetIndex, [int arrowIndex]) {
    Widget deleteButton;
    if (arrowIndex != null) {
      deleteButton = FlatButton(
        child: Text(
          "DELETE",
          style: TextStyle(color: Colors.red),
        ),
        onPressed: () {
          deleteArrowInformation(arrowSetIndex, arrowIndex);
          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
      );
    } else {
      deleteButton = FlatButton(
        child: Text(
          "DELETE",
          style: TextStyle(color: Colors.red),
        ),
        onPressed: () {
          deleteArrowSetAtIndex(arrowSetIndex);
          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
      );
    }

    Widget cancelButton = FlatButton(
      child: Text(
        "Cancel",
        style: TextStyle(color: Colors.grey),
      ),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Are you sure?"),
      content: Text("Deleting arrows from your quiver will also remove them from all training sessions. Consider renaming them instead."),
      actions: [
        cancelButton,
        deleteButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  DataColumn tableColumn(String text, bool numeric) {
    return DataColumn(
      label: Expanded(
        child: Text(text, textAlign: TextAlign.center, textScaleFactor: 1.3),
      ),
      numeric: numeric,
    );
  }

  DataCell tableCell(BuildContext context, ArrowInformation arrowInformation) {
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
                //counter: SizedBox.shrink(),
                suffixIcon: Icon(Icons.edit),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(left: 15, bottom: 11, top: 11, right: 15),
                hintText: "",
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(5),
              ],
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
              initialValue: arrowInformation.label,
              keyboardType: TextInputType.name,
              onChanged: (text) {
                if (text.length <= 5) {
                  arrowInformation.label = text;
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget arrowTableForSetWithIndex(BuildContext context, int index) {
    List<DataRow> rows = [];

    for (int i = 0; i < arrowSets[index].arrowInfos.length; i++) {
      List<DataCell> cells = [];
      cells.add(tableCell(context, arrowSets[index].arrowInfos[i]));
      cells.add(
        DataCell(
          Center(
            child: Checkbox(
              key: i == 0 && index == initPosition ? _arrowRowKey : null,
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
                showAreYouSureDialog(context, index, i);
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
                arrowSets[index].addArrow((arrowSets[index].arrowInfos.length + 1).toString());
                setState(() {});
                return;
              },
            ),
          ),
          Container(
            key: index == initPosition ? _arrowCountKey : null,
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

  Widget tabBodyGenerator(BuildContext context, int index, int length) {
    if (index == length) {
      return Center(
        child: Container(
          key: _addSetKey,
          child: Text(
            "Press press the green button on\ntop to create a new set of arrows.",
            textScaleFactor: 1.3,
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              Container(
                //width: _screenWidth(),
                padding: EdgeInsets.only(top: 20), //.all(50),
                child: Center(
                  child: Row(
                    key: index == initPosition ? _editSetKey : null,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: screenWidth() * 0.3,
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
                              showAreYouSureDialog(context, index);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              arrowTableForSetWithIndex(context, index),
            ],
          ),
        ),
      ),
    );
  }

  Widget tabHeaderGenerator(int index, int length) {
    if (index == length) {
      return Container(
        width: screenWidth() / 7,
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
              arrowSets.last.addArrow((arrowSets.last.arrowInfos.length + 1).toString());
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
          child: tabHeaderGenerator(index, arrowSets.length),
        );
      },
      pageBuilder: (context, index) => tabBodyGenerator(context, index, arrowSets.length),
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
    startRoutineFinished = false;
    setState(() {});
    await dbService.updateAllArrowSets(arrowSets);
    return true;
  }

  Widget emptyScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quiver"),
      ),
      body: SpinKitCircle(
        color: Theme.of(context).primaryColor,
        size: 100.0,
        controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)),
      ),
    );
  }

  Widget showContent() {
    return WillPopScope(
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: Text("Quiver"),
              actions: <Widget>[
                // action button
                IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () {
                    if (arrowSets == null || arrowSets.isEmpty) {
                      showCoachMarkAddSet();
                    } else {
                      _scrollController
                          .animateTo(
                            _scrollController.position.minScrollExtent,
                            duration: Duration(seconds: 1),
                            curve: Curves.fastOutSlowIn,
                          )
                          .then((value) => showCoachMarkEditSet());
                    }
                  },
                ),
              ],
            ),
            bottomNavigationBar: _bottomBar(),
            body: createTabScreen(),
          ),
        ],
      ),
      onWillPop: onLeave,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (startRoutineFinished) {
      return showContent();
    }

    return emptyScreen(context);
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
            indicator: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)), color: Colors.white),
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
