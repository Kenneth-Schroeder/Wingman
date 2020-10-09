import 'TrainingInstance.dart';
import 'dart:math';

class CompetitionSimulator {
  CompetitionSimulator(this._type, this._gender, this._outdoors, this._level) {
    assert(this._type != CompetitionType.training);
    assert(this._gender != Gender.none);

    double lambdaPro = _lambdaTablePro[this._type.index - 1][this._outdoors == true ? 0 : 1][this._gender.index - 1];
    double lambdaBeginner = _lambdaTableBeginner[this._type.index - 1][this._outdoors == true ? 0 : 1][this._gender.index - 1];
    double lambdaStepSize = (lambdaBeginner - lambdaPro) / 19; // todo hardcoded because 19 levels
    _lambda = lambdaBeginner - lambdaStepSize * (this._level - 1);
    // _lambda *= 1 + (1 - this._level / 18) * 5.0; // 1/9 to 10/9, 8/9 to -1/9, 17/9 to 8/9
    cumulativeProbabilities = generateCumulativeProbabilityList(_lambda);
    //test();
  }

  CompetitionType _type;
  Gender _gender;
  bool _outdoors;
  int _level;
  double _lambda;
  List<double> cumulativeProbabilities;

  List<List<List<double>>> _lambdaTablePro = [
    [
      // qualifying
      [1.328704, 1.256944], // outdoors
      [0.208333, 0.086111], // indoors
    ],
    [
      // finals
      [1.640000, 1.404412], // outdoors
      [0.290323, 0.171429], // indoors
    ],
  ];

  List<List<List<double>>> _lambdaTableBeginner = [
    [
      // qualifying
      [7.0, 7.0], // outdoors, female - male
      [4.0, 4.0], // indoors
    ],
    [
      // finals
      [7.0, 7.0], // outdoors
      [4.0, 4.0], // indoors
    ],
  ];

  int factorial(int score) {
    int result = 1;
    for (int i = score; i > 0; i--) result *= i;
    return result;
  }

  double poisson(double lambda, int x) {
    return pow(lambda, x) * exp(-lambda) / factorial(x);
  }

  List<double> generateCumulativeProbabilityList(double lambda) {
    List<double> list = [];

    if (_outdoors) {
      // list needs 12 elements, 0=X and 11=0
      list.add(poisson(lambda, 0));
      for (int i = 1; i < 11; i++) {
        list.add(list.last + poisson(lambda, i));
      }
      list.add(1);
    } else {
      // list needs 6 elements, 0=10 and 5=0
      list.add(poisson(lambda, 0));
      for (int i = 1; i <= 4; i++) {
        list.add(list.last + poisson(lambda, i));
      }
      list.add(1);
    }

    return list;
  }

  void test() {
    List<int> scores = getScores(10000);
    print(scores.reduce((a, b) => a + b) / 10000);
  }

  int getScore() {
    Random rng = new Random();
    double number = rng.nextDouble();

    int index = cumulativeProbabilities.indexWhere((element) => element >= number);

    if (_outdoors) {
      if (index <= 1) // todo adjust for X
        return 10;
      return 11 - index;
    } else {
      if (index == 5) return 0;
      return 10 - index;
    }
  }

  List<int> getScores(int number) {
    List<int> scores = [];

    for (int i = 0; i < number; i++) {
      scores.add(getScore());
    }

    return scores;
  }
}
