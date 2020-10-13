class ArrowInformation {
  String label;
  int id;
  int setID; // TODO check if needed, when done
  bool selected = false;

  ArrowInformation(this.label);

  int get hashCode => id.hashCode;

  bool operator ==(other) {
    // Dart ensures that operator== isn't called with null
    // if(other == null) {
    //   return false;
    // }
    if (other is! ArrowInformation) {
      return false;
    }
    return id == other.id;
  }

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
    arrowInfos.add(ArrowInformation(label));
  }
}
