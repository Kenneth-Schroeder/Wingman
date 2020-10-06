import 'package:flutter/material.dart';
import 'database_service.dart';
import 'SizeConfig.dart';

class ArrowSetWithSelection {
  String setLabel = "HI";
  int setIndex = 3;
  List<String> arrowLabel = ["3", "7", "1"];
  List<bool> arrowSelected = [false, false, false];
}

class QuiverOrganizer extends StatefulWidget {
  QuiverOrganizer({Key key}) : super(key: key);

  @override
  _QuiverOrganizerState createState() => _QuiverOrganizerState();
}

class _QuiverOrganizerState extends State<QuiverOrganizer> {
  DatabaseService dbService;
  bool startRoutineFinished = false;
  List<ArrowSetWithSelection> arrowSets = [ArrowSetWithSelection(), ArrowSetWithSelection(), ArrowSetWithSelection()];
  List<bool> enabled = [false, false, false];

  int initPosition = 1;

  @override
  void initState() {
    super.initState();
    onStart();
  }

  double _screenWidth() {
    // todo make sure to use these
    return SizeConfig.screenWidth == null ? 1 : SizeConfig.screenWidth;
  }

  void onStart() async {
    dbService = await DatabaseService.create();
    SizeConfig().init(context);
    startRoutineFinished = true;
    setState(() {});
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
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget arrowTableForSet(ArrowSetWithSelection set) {
    List<DataRow> rows = [];

    for (int i = 0; i < set.arrowLabel.length; i++) {
      List<DataCell> cells = [];
      cells.add(tableCell(set.arrowLabel[i]));
      rows.add(DataRow(
          cells: cells,
          selected: set.arrowSelected[i],
          onSelectChanged: (bool) {
            set.arrowSelected[i] = bool;
            setState(() {});
          }));
      cells = [];
    }

    List<DataColumn> columns = [
      tableColumn('Arrow Label', false),
    ];

    return Container(
      color: Colors.white,
      child: DataTable(
        showCheckboxColumn: true,
        columns: columns,
        rows: rows,
        columnSpacing: 25,
        dataRowHeight: 25,
      ),
    );
  }

  Widget createTabScreen() {
    return CustomTabView(
      initPosition: initPosition,
      itemCount: arrowSets.length,
      tabBuilder: (context, index) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _screenWidth() / 7,
              child: TextField(
                enabled: enabled[index],
                autofocus: enabled[index],
                controller: TextEditingController()..text = arrowSets[index].setLabel,
                onChanged: (text) => {arrowSets[index].setLabel = text},
              ),
            ),
            GestureDetector(
                onTap: () {
                  prepareEdit(index);
                },
                child: Icon(Icons.edit)),
          ],
        ),
      ), //Text(data[index])),
      pageBuilder: (context, index) => arrowTableForSet(arrowSets[index]), //Center(child: Text(arrowSets[index].setLabel)),
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

  Widget emptyScreen() {
    return MaterialApp(
      home: AppBar(
        title: Text("loading..."),
      ),
    );
  }

  Widget showContent() {
    return Scaffold(
      body: SafeArea(
        child: createTabScreen(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            enabled.add(false);
            arrowSets.add(ArrowSetWithSelection());
          });
        },
        child: Icon(Icons.add),
      ),
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

/// Implementation

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
