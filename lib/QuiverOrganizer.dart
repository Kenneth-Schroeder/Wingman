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
  List<bool> enabled = [];

  int initPosition = 0;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    arrowSets = await dbService.getAllArrowSets();
    enabled = List.filled(arrowSets.length, false, growable: true);

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

  void prepareEdit(int index) async {
    enabled[index] = true;
    setState(() {});
  }

  DataColumn tableColumn(String text, bool numeric) {
    return DataColumn(
      label: Text(text),
      numeric: numeric,
    );
  }

  DataCell tableCell(String content) {
    return DataCell(
      Text(
        content,
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget arrowTableForSet(ArrowSet set) {
    List<DataRow> rows = [];

    for (int i = 0; i < set.arrowInfos.length; i++) {
      List<DataCell> cells = [];
      cells.add(tableCell(set.arrowInfos[i].label));
      cells.add(
        DataCell(
          Checkbox(
            value: set.arrowInfos[i].selected,
            onChanged: (bool value) {
              setState(() {
                if (value) {
                  selectedArrows += 1;
                } else {
                  selectedArrows -= 1;
                }

                set.arrowInfos[i].selected = value;
              });
            },
          ),
        ),
      );

      rows.add(DataRow(cells: cells));
      cells = [];
    }

    List<DataColumn> columns = [
      tableColumn('Arrow Label', false),
      tableColumn('Selected', false),
    ];

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            DataTable(
              showCheckboxColumn: true,
              columns: columns,
              rows: rows,
              columnSpacing: 25,
              dataRowHeight: 40,
            ),
            RaisedButton(
              color: Colors.greenAccent,
              child: Text("+"),
              onPressed: () {
                set.addArrow(set.arrowInfos.length.toString());
                setState(() {});
                return;
              },
            ),
            Text("selected " + selectedArrows.toString() + "/" + widget.numArrowsToSelect.toString()),
          ],
        ),
      ),
    );
  }

  Widget tabBodyGenerator(int index, int length) {
    if (index == length) {
      return Container();
    }

    return arrowTableForSet(arrowSets[index]);
  }

  Widget tabHeaderGenerator(int index, int length) {
    if (index == length) {
      return Container(
        width: _screenWidth() / 7,
        child: SizedBox(
          width: double.infinity, // match_parent
          height: double.infinity,
          child: FlatButton(
            color: Colors.lightGreen,
            //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.0)),
            //padding: EdgeInsets.all(4.0),
            child: Icon(Icons.add),
            onPressed: () {
              enabled.add(false);
              arrowSets.add(ArrowSet("Set " + arrowSets.length.toString()));
              setState(() {});
            },
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(0), // ???
          width: _screenWidth() / 7,
          child: TextField(
            enabled: enabled[index],
            controller: TextEditingController()..text = arrowSets[index].label,
            onChanged: (text) => {arrowSets[index].label = text},
          ),
        ),
        GestureDetector(
            onTap: () {
              prepareEdit(index);
            },
            child: Icon(Icons.edit)),
      ],
    );
  }

  Widget createTabScreen() {
    return CustomTabView(
      initPosition: initPosition,
      itemCount: arrowSets.length + 1,
      tabBuilder: (context, index) => Tab(
        child: tabHeaderGenerator(index, arrowSets.length),
      ), //Text(data[index])),
      pageBuilder: (context, index) => tabBodyGenerator(index, arrowSets.length),
      onPositionChange: (index) {
        for (int i = 0; i < enabled.length; i++) {
          enabled[i] = false;
        }
        // print('current position: $index');
        initPosition = index;
        setState(() {});
      },
      onScroll: (position) {}, // (position) => print('$position'),
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

  @override
  void initState() {
    _currentPosition = widget.initPosition ?? 0;
    controller = TabController(
      length: widget.itemCount,
      vsync: this,
      initialIndex: _currentPosition,
    );
    controller.addListener(onPositionChange);
    controller.animation.addListener(onScroll);
    _currentCount = widget.itemCount;
    super.initState();
  }

  @override
  void didUpdateWidget(CustomTabView oldWidget) {
    if (_currentCount != widget.itemCount) {
      controller.animation.removeListener(onScroll);
      controller.removeListener(onPositionChange);
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
          alignment: Alignment.center,
          child: TabBar(
            labelPadding: EdgeInsets.all(0),
            isScrollable: true,
            controller: controller,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).hintColor,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
            tabs: List.generate(
              widget.itemCount,
              (index) => widget.tabBuilder(context, index),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
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
