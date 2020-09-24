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
enum CompetitionType { training, qualifying, finals }
enum Gender { none, female, male }

class TrainingInstance {
  int id = -1;
  String title;
  DateTime creationTime;
  int arrowsPerEnd = 6;
  int numberOfEnds = 0; // 0 means open
  TargetType targetType = TargetType.Full;
  double targetDiameterCM = 122; // 40, 60, 80 oder 122
  double arrowDiameterMM = 5;
  CompetitionType competitionType = CompetitionType.training;
  Gender referencedGender = Gender.none;
  int competitionLevel = 1;

  TrainingInstance(this.title, this.creationTime);

  TrainingInstance.fromMap(Map<String, dynamic> map)
      : assert(map["title"] != null),
        assert(map["creationTime"] != null),
        id = map["id"] == null ? -1 : map["id"],
        targetType = map["targetType"] == null ? TargetType.Full : TargetType.values[map["targetType"]],
        competitionType = map["competitionType"] == null ? CompetitionType.training : CompetitionType.values[map["competitionType"]],
        referencedGender = map["referencedGender"] == null ? Gender.none : Gender.values[map["referencedGender"]],
        targetDiameterCM = map["targetDiameterCM"] == null ? 122 : map["targetDiameterCM"],
        arrowDiameterMM = map["arrowDiameterMM"] == null ? 5 : map["arrowDiameterMM"],
        numberOfEnds = map["numberOfEnds"] == null ? 0 : map["numberOfEnds"],
        title = map["title"],
        arrowsPerEnd = map["arrowsPerEnd"],
        competitionLevel = map["competitionLevel"],
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
      "arrowDiameterMM": this.arrowDiameterMM,
      "competitionType": this.competitionType.index,
      "referencedGender": this.referencedGender.index,
      "numberOfEnds": this.numberOfEnds,
      "competitionLevel": this.competitionLevel,
    };
  }

  double relativeArrowWidth() {
    return arrowDiameterMM / targetDiameterCM / 10;
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
