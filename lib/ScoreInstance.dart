class ScoreInstance {
  int score;
  int endID;
  // TODO coordinates

  ScoreInstance(this.endID, this.score);

  ScoreInstance.fromMap(Map<String, dynamic> map)
      : assert(map["score"] != null),
        assert(map["endID"] != null),
        score = map["score"],
        endID = map["endID"];

  Map<String, dynamic> toMap() {
    return {
      "score": this.score,
      "endID": this.endID,
    };
  }

  String toString() {
    return score.toString();
  }
}
