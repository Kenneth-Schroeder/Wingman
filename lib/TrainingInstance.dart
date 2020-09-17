/*
    What each training should contain:
    for now:
    id
    title
    datetime

    later:
    distance
    target type
*/

enum TargetType { Full, SingleSpot, TripleSpot }

class TrainingInstance {
  int id = -1;
  String title;
  DateTime creationTime;
  int arrowsPerEnd = 6;
  TargetType targetType = TargetType.Full;
  double targetDiameterCM = 122; // 40, 60, 80 oder 122

  TrainingInstance(this.title, this.creationTime);

  TrainingInstance.fromMap(Map<String, dynamic> map)
      : assert(map["title"] != null),
        assert(map["creationTime"] != null),
        id = map["id"] == null ? -1 : map["id"],
        targetType = map["targetType"] == null ? TargetType.Full : TargetType.values[map["targetType"]],
        targetDiameterCM = map["targetDiameterCM"] == null ? 122 : map["targetDiameterCM"],
        title = map["title"],
        arrowsPerEnd = map["arrowsPerEnd"],
        creationTime = map["creationTime"] is String // if it is passed as string, we can convert it to DateTime object
            ? DateTime.parse(map["creationTime"])
            : map["creationTime"];

  Map<String, dynamic> toMap() {
    return {
      "title": this.title,
      "creationTime": this.creationTime.toString(),
      "arrowsPerEnd": this.arrowsPerEnd,
      "targetType": this.targetType.index,
      "targetDiameterCM": this.targetDiameterCM,
    };
  }

  String date() {
    return creationTime.month.toString().padLeft(2, '0') +
        "/" +
        creationTime.day.toString().padLeft(2, '0') +
        "/" +
        creationTime.year.toString();
  }

  String time() {
    return creationTime.hour.toString().padLeft(2, '0') + ":" + creationTime.minute.toString().padLeft(2, '0');
  }

  String toString() {
    return title + " " + creationTime.toString();
  }
}
