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

class TrainingInstance {
  int id = -1;
  String title;
  DateTime creationTime;
  TrainingInstance(this.title, this.creationTime);

  TrainingInstance.fromMap(Map<String, dynamic> map)
      : assert(map["title"] != null),
        assert(map["creationTime"] != null),
        id = map["id"] == null ? -1 : map["id"],
        title = map["title"],
        creationTime = map["creationTime"] is String // if it is passed as string, we can convert it to DateTime object
            ? DateTime.parse(map["creationTime"])
            : map["creationTime"];

  Map<String, dynamic> toMap() {
    return {
      "title": this.title,
      "creationTime": this.creationTime.toString(),
    };
  }

  String toString() {
    return title + " " + creationTime.toString();
  }
}
