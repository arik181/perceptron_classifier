import 'dart:core';
import 'dart:io';
import 'dart:json';
import 'dart:math';

/**
 * The essential job of main is as follows:
 * 1.) create the perceptron classifiers
 * 2.) train the classifiers over training data subsets
 * 3.) run the classifiers over test data subsets
 * 4.) report results
 */
void main() {
  /** 
   * Adjustments
   * 
   * Adjust these variables in order to 
   * tweak the training algorithm. I saw
   * very little difference between learning
   * rates 0.2, 0.8 and 0.05. I also detected
   * little variation between setting the 
   * number of training runs to 1, 10, 20, 50, 
   * 100 and 1000. YMMV.
   */
  // Number of runs to make during training
  int runs = 1000;
  // Also known as Ada
  double learningRate = 0.8;
  
  // Start
  print("start");
  print("reading files");
  
  // ** Data
  Path trainingDataPath = new Path(r'bin/optdigits.train');
  Path testDataPath = new Path(r'bin/optdigits.test');
  var trainingDataFile = new File.fromPath(trainingDataPath);
  var testDataFile = new File.fromPath(testDataPath);
  
  // Read training data file to list of Strings
  List<String> trainingData;
  List<String> testData;
  trainingData = trainingDataFile.readAsLinesSync();
  testData     = testDataFile.readAsLinesSync();
  
  // Confusion Matrix
  List<List<int>> confusionMatrix = new List<List<int>>();
  int i = 0;
  int j = 0;
  for (i=0;i<10;++i) {
    confusionMatrix.add(new List<int>());
    for (j=0;j<10;++j) {
      confusionMatrix[i].add(0);
    }
  }
  
  // ** Create Perceptron Classifiers
  print("creating perceptron classifiers");
  List<pClassifier> pc = new List<pClassifier>();
  // Create all 45 Classifier combinations
  i=0;
  j=0;
  List<bool> unmarked = new List.filled(10, false);
  for (i=0; i<10; ++i) {
    unmarked[i] = true;
    for (j=1; j<10; ++j) {
      if (!unmarked[j]) {
        pc.add(new pClassifier( trainingData, 
                                testData, 
                                i, j, 
                                learningRate, 
                                confusionMatrix));
      }
    }
  }
  
  // ** Get busy
  int totalFailures  = 0;
  int totalSuccesses = 0;
  int totalFP        = 0;
  int totalFN        = 0;
  int totalTP        = 0;
  int totalTN        = 0;
  print("training classifiers");
  for (final classifier in pc) {
    // Train the classifier
    classifier.train(runs);
    // Report findings
    classifier.report();        
    // Get stats
    totalFailures  += classifier.failures;
    totalSuccesses += classifier.successes;
    totalFP        += classifier.FP;
    totalFN        += classifier.FN;
    totalTP        += classifier.TP;
    totalTN        += classifier.TN;
  }
  print("reporting training data");
  finalReport(totalFailures, 
              totalSuccesses, 
              totalFP, 
              totalFN, 
              totalTP, 
              totalTN,
              learningRate,
              confusionMatrix,
              runs);
  
  print("running classifiers");
  for (final classifier in pc) {
    // Run the classifier on test data
    classifier.test();
    // Report findings
    classifier.report();        
    // Get stats
    totalFailures  += classifier.failures;
    totalSuccesses += classifier.successes;
    totalFP        += classifier.FP;
    totalFN        += classifier.FN;
    totalTP        += classifier.TP;
    totalTN        += classifier.TN;
  }
  
  print("reporting test data");
  finalReport(totalFailures, 
              totalSuccesses, 
              totalFP, 
              totalFN, 
              totalTP, 
              totalTN,
              learningRate,
              confusionMatrix,
              runs);
}

/** 
 * Main reporting function
 */
finalReport(int failures, int successes, 
            int FP, int FN, int TP, int TN,
            double learningRate,
            List<List<int>> confusionMatrix,
            int runs) {
  double precision = TP / (TP + FP);
  double recall    = TP / (TP + FN);
  double accuracy  = (1.0 - (failures / successes));
  print("____________________________________________");
  print("Learning rate         : " + learningRate.toString());
  print("Training runs         : " + runs.toString());
  print("Total successes       : " + successes.toString());
  print("Total failures        : " + failures.toString());
  print("Precision             : " + precision.toStringAsPrecision(2) + "%");  
  print("Recall                : " + recall.toStringAsPrecision(2)    + "%");
  print("Accuracy              : " + accuracy.toStringAsPrecision(2)  + "%");
  print("____________________________________________");
  // Print confusion matrix
  int i=0;
  int j=0;
  String line;
  String digits;
  print("      0   1   2   3   4   5   6   7   8   9");
  print("____________________________________________");
  for (i=0;i<10;++i) {
    line = "";
    for (j=0;j<10;++j) {
      if (j == 0) {
        line = line + i.toString() + " |";
      }
      if (i == j) {
        digits = "X";
      } else {        
        digits = confusionMatrix[i][j].toString();
      }
      int l = digits.length;
      int k=0;
      // Table Alignment
      for (k=0;k<(4-l);++k) {
        line = line + " ";
      }
      line = line + digits;
    }
    print(line + "\n");
  }
  print("--------------------------------------------");
}

/**
 * Perceptron classifier class
 */
class pClassifier {
  /**
   * Prepended underscore character  
   * indicates private class variable.
   */
  // Trained classes
  int _classA;
  int _classB;
  // Learning Rate
  double Ada = 0.0;
  // Weights
  List <double> _weights;
  // Classes
  List<int> _testClasses;
  List<int> _trainingClasses;
  List<int> _testSubsetClasses;
  List<int> _trainingSubsetClasses;
  // Input
  List<String> _trainingData;
  List<String> _testData;
  List<List<String>> _digitData;
  const int _numberOfInputs  = 64;
  const int _numberOfWeights = 65;
  // Output from classification test run
  double _output = 0.0;
  List<int> _output_data;
  // Confusion Matrix
  List<List<int>> _confusionMatrix;
  // K is the current epoch; 
  int _k=0;
  // State
  bool _hasRun    = false;
  bool _hasTested = false;
  int  _successes = 0;
  int  _failures  = 0;
  int  _FP        = 0;
  int  _FN        = 0;
  int  _TP        = 0;
  int  _TN        = 0;
  int  _runs      = 0;
  // Random seed
  var _rand = new Random();

  /**
   * Constructor -
   * Set initial values for our 
   * Perceptron Classifier
   * 
   * Argument - 
   * inputData - a set of strings representing
   * a raw optdigits dataset.
   */
  pClassifier(List<String> trainingData, 
              List<String> testData,
              int a, 
              int b,
              double learningRate,
              List<List<int>> confusionMatrix) {
    // Classes to train for
    _classA = a;
    _classB = b;
    // Learning rate
    Ada = learningRate;
    // Confusion matrix
    _confusionMatrix = confusionMatrix;
    // Initial weights
    _weights = new List<double>();
    // Set to random values
    // ** Generate random weights (0.0..0.9)
    int i=0;
    int  sign;
    for (i=0; i < _numberOfWeights; ++i) {
      if (_rand.nextBool()) {
        sign = -1;
      } else {
        sign = 1;
      }
      _weights.add(sign * (_rand.nextInt(10).toDouble()/10));
    }

    // Input
    // Get classes from data
    _trainingClasses        = parseClasses(trainingData); 
    _testClasses            = parseClasses(testData); 
    // Convert input to Json
    _trainingData           = parseFeatures(trainingData);
    _testData               = parseFeatures(testData);
    _testSubsetClasses      = new List<int>();
    _trainingSubsetClasses  = new List<int>();
    // Output from classification test run
    _output_data            = new List<int>();
  }
  
  /** 
   * Getters/Setters
   */
  int get failures  => _failures;
  int get successes => _successes;
  int get FP        => _FP;
  int get FN        => _FN;
  int get TP        => _TP;
  int get TN        => _TN;
  
  /** 
   * Output function - 
   * Run the Perceptron to get output "o"
   * Implements the primary "run" algorithm
   */
  run(List<int> inputs) {
    int i=0;
    // Implement run formula
    _output = _weights[0];
    for (i=1; i < inputs.length; ++i) {
      //print("" + _weights[i].toString() + " " + inputs[i].toString());
      _output += (_weights[i] * inputs[i]); 
    }
    // Signum
    if (_output >= 0){
      _output = 1.0;
    } else {
      _output = -1.0;
    }
  }
  
  /** 
   * Wrapper for output function - 
   * Run the Perceptron to get output "o"
   * from test data
   */
  testRun(List<String> testData) {
    int i=0;
    for (final test in testData) {      
      var inputData = parse(test);
      // TODO : This line is pretty weak. Figure out a better way to
      // get one set of values from a hashmap in Dart. Or refactor.
      List<double> inputs = inputData[inputData.keys.single.toString()];
      run(inputs);
      if (_output == -1.0) {
        _output_data.add(_classB);
      } else {
        _output_data.add(_classA);
      }
      ++i;
    }
    _hasRun = true;
    tabulate();
  }
  
  /** 
   * Marshall data for testRun()
   */
  test() {
    List<String> subsetData = new List<String>();
    // Create subset of complete data which
    // includes only the two useful classes
    int i=0;
    for (final cls in _testClasses) {
      if ( cls == _classA || cls == _classB ) {
        subsetData.add(_testData[i]);
        _testSubsetClasses.add(cls);
      }
      ++i;
    }
    // Run the perceptron to get a new set of 
    // output values for the test data
    testRun(subsetData); 
  }
  
  /** 
   * Wrapper for output function - 
   * Evaluate training data
   */
  trainingRun(List<String> trainingData) {
    int i=0;
    for (final test in trainingData) {      
      var inputData = parse(test);
      // TODO : This line is pretty weak. Figure out a better way to
      // get one set of values from a hashmap in Dart. Or refactor.
      List<double> inputs = inputData[inputData.keys.single.toString()];
      run(inputs);
      if (_output == -1.0) {
        _output_data.add(_classB);
      } else {
        _output_data.add(_classA);
      }
      ++i;
    }
    _hasTested = true;
    tabulate();
    
  }
  
  /** 
   * Training function -
   * Train the classifier (one epoch)
   */
  train(int runs) {
    // Just for tracking purposes
    _runs = runs;
    // Create subset of complete data which
    // includes only the two useful classes 
    List<String> subsetData  = new List<String>();
    List<int>    subsetT     = new List<int>();
    int i=0;
    for (final cls in _trainingClasses) {
      if ( cls == _classA || cls == _classB ) {
        subsetData.add(_trainingData[i]);
        _trainingSubsetClasses.add(cls);
        if (cls == _classA) {
          subsetT.add(1);
        } else {
          subsetT.add(-1);
        }
      }
      ++i;
    }
    // Train, using Stochastic Gradient Descent
    int n=0;
//    const maxRuns = 100;
    for (n=0;n<runs;++n) {
      // Iterate over each training case
      _k = 0;
      int currentSuccess = 0;
      for (final key in subsetData) {        
        // Implement training formula
        double deltaW = 0.0; // say that three times fast...
        var inputData = parse(subsetData[_k]);
        // TODO : This line is pretty weak. Figure out a better way to
        // get one set of values from a hashmap in Dart. Or refactor.
        List<double> _inputs = inputData[inputData.keys.single.toString()];
        i=0;
        for (i=0; i < _inputs.length; ++i) {
          //print("Ada : " + Ada.toString() + " subsetT[i] : " + subsetT[i].toString() + " _output : " + _output.toString() + " _inputs[i] : " + _inputs[i].toString());
          deltaW = ((subsetT[_k] - _output) * _inputs[i]);
          deltaW *= Ada;
          _weights[i] = _weights[i] + deltaW;
        }
        _k++;
      }
    }
    // Run the perceptron to get a new output value
    trainingRun(subsetData);
    _hasTested = true;
    // Record statistics for posterity
    tabulate();
    _output_data = new List<int>();
  }
  
  /**
   * parseClasses() -
   * Create a List of integers containing the
   * classes of a dataset.
   */
  parseClasses(List<String> data) {
    List<int> classes = new List<int>();
    RegExp classDigit = new RegExp(r'\d+$');
    for (final item in data) {
      classes.add(int.parse(classDigit.firstMatch(item).group(0)));
    }
    return classes;
  }
  
  /**
   * parseFeatures() -
   * Create a list of strings which contains a
   * Json representation of a dataset of features,
   * minus digit representing the actual class
   * 
   * Arguments -
   * data - dataset to be parsed
   */
  parseFeatures(List<String> data) {
    List<String> json     = new List<String>();
    List<double> features = new List<double>();
    RegExp start      = new RegExp(r'^');      // Start of line
    RegExp classDigit = new RegExp(r',\d+$');  // Digit and end of line
    int i = 0;
    for (final item in data) {
      // The new string is a Json list of features 
      // for one set of test data (or one epoch k)
      String newString = item
                            .replaceAll(start, '{ "$i" : [ ')
                            .replaceAll(classDigit, r' ]}');
      json.add(newString);
      ++i;
    }
    return json;
  }
  
  /**
   * Tabulate statistics for use in training.
   * as well as in reporting, this includes
   * success vs failure, positives vs negatives
   * as well as the creation of the confusion
   * matrix.
   */
  tabulate() {
    List<int> classes;
    if (_hasTested) {
      classes = _trainingSubsetClasses;  
    }
    if (_hasRun) {
      classes = _testSubsetClasses;
    }
    if (_hasRun
     || _hasTested ) {
      int i=0;
      _successes =0;
      _failures  =0;
      _FP = 0;
      _FN = 0;
      _TP = 0;
      _TN = 0;
      for (final cls in classes) {
        //print(cls.toString() + "          " + _output_data[i].toString());
        if (cls == _output_data[i]) {
          ++_successes;
          if (cls == _classA) {
            ++_TP;
          } else {
            ++_TN;
          }
        } else {
          ++_failures;
          if (cls == _classA) {
            // Add to confusion Matrix
            ++_confusionMatrix[_classA][_classB];
            ++_FP;
          } else {
            // Add to confusion Matrix
            ++_confusionMatrix[_classB][_classA];
            ++_FN;
          }
        }
        ++i;
      }
    }
  }

  /**
   * Perceptron reporting function
   */
  report() {
    if (_hasRun) {
      print("--------------------------------------------");
      print("( " + _classA.toString() + ", " + _classB.toString() + " )");
      print("Successes       : " + _successes.toString());
      print("Failures        : " + _failures.toString());
      print("False Positives : " + _FP.toString());
      print("False Negatives : " + _FN.toString());
      //print(_weights);
      double precision = _TP / (_TP + _FP);
      double recall    = _TP / (_TP + _FN);
      double accuracy  = (1.0 - (_failures / _successes));
      print("______________________________");
      print("Learning rate         : " + Ada.toString());
      print("Training runs         : " + _runs.toString());
      print("Total successes       : " + successes.toString());
      print("Total failures        : " + failures.toString());
      print("Precision             : " + precision.toStringAsPrecision(2) + "%");  
      print("Recall                : " + recall.toStringAsPrecision(2)    + "%");
      print("Accuracy              : " + accuracy.toStringAsPrecision(2)  + "%");
      print("--------------------------------------------");
    } else {
      //print('Nothing to report. Please run the classifier before reporting.');
    }
  }
}