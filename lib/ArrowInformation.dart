class ArrowInformation {
  String label;
  int id;
  int setID; // TODO check if needed, when done
  bool selected = false;

  ArrowInformation(this.label);

  ArrowInformation.fromMap(Map<String, dynamic> map)
      : assert(map["id"] != null),
        assert(map["setID"] != null),
        assert(map["label"] != null),
        label = map["label"],
        id = map["id"],
        setID = map["setID"];

  Map<String, dynamic> toMapWithSetID(int id) {
    return {
      "label": this.label,
      "setID": id,
    };
  }
}

class ArrowSet {
  String label;
  int id;
  List<ArrowInformation> arrowInfos = [];

  ArrowSet(this.label);

  ArrowSet.fromMap(Map<String, dynamic> map)
      : assert(map["id"] != null),
        assert(map["label"] != null),
        id = map["id"],
        label = map["label"],
        arrowInfos = map["arrowInfos"];

  Map<String, dynamic> toMap() {
    return {
      "label": this.label,
    };
  }

  void addArrow(String label) {
    arrowInfos.add(ArrowInformation(
      label,
    ));
  }
}
