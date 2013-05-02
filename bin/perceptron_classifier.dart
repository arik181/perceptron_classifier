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
  // Output
  num output = 0;
  
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
  
  // ** A Single Perceptron Classifier
  pClassifier pc = new pClassifier(trainingData, testData);
  // Train the classifier
  pc.train(0,5);
  // Run the classifier on test data
  // pc.test();
  // Report findings
//  pc.report();
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
  const num Ada = 0.2;
  // Weights
  List <double> _weights;
  // Classes
  List <int> _testClasses;
  List <int> _trainingClasses;
  // Input
  List<String> _trainingData;
  List<List<String>> _digitData;
  const int _numberOfInputs  = 64;
  const int _numberOfWeights = 65;
  // Output from classification test run
  double _output = 0.0;
  List<bool> _output_data;
  // K is the current epoch; 
  // The number of times the classifier has been run.
  // We assume that this number is smaller than the 
  // maximum size of int. (Perhaps a bad assumption...)
  int _k=0;
  // State
  bool _hasRun = false;
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
  pClassifier(List<String> trainingData, List<String> testData) {
    // Initial weights
    _weights = new List<double>();
    // Set to random values
    int i=0;
    // ** Generate random weights (0.0..0.9)
    for (i=0; i < _numberOfWeights; ++i) {
      _weights.add(_rand.nextInt(10).toDouble()/10);
    }
    // Input
    // Get classes from data
    _trainingClasses  = parseClasses(trainingData); 
    _testClasses      = parseClasses(testData); 
    // Convert input to Json
    _trainingData     = parseFeatures(trainingData);
    // Output from classification test run
    _output_data = new List<bool>();
  }
  
  /** 
   * Output function - 
   * Run the Perceptron to get output "o"
   */
  run(List<int> inputs) {
    int i=0;
    // Implement run formula
    for (i=1; i < inputs.length; ++i) {
      _output = _output + (_weights[i] * inputs[i]) + _weights[0]; 
    }
    ++_k;
  }
  
  /** 
   * Wrapper for output function - 
   * Run the Perceptron to get output "o"
   * from test data
   */
  testRun(List<String> testData) {
    // TODO : do this for every test in the test data
    for (final test in testData) {      
      var inputData = parse(test);
      List<double> inputs = inputData[_k.toString()];
      run(inputs);
    }
    // TODO : save outputs to a list called _output_data
    
    _hasRun = true;
  }
  
  /** 
   * Wrapper function (for cleaner API)
   */
  test() {
    List<String> subsetData = new List<String>();
    // Create subset of complete data which
    // includes only the two useful classes 
    int i=0;
    for (final cls in _testClasses) {
      if ( cls == _classA || cls == _classB ) {
        subsetData.add(_trainingData[i]);
      }
      ++i;
    }
    // Run the perceptron to get a new output value
    testRun(subsetData); 
    // TODO : set up test data and pass to testRun()
  }
  
  /** 
   * Wrapper for output function - 
   * Run the Perceptron to get output "o"
   * from training data
   */
  trainingRun(List<String> trainingData) {
    var inputData = parse(trainingData[_k]);
    List<double> inputs = inputData[_k.toString()];
    run(inputs);
  }
  
  /** 
   * Training function -
   * Train the classifier (one epoch)
   * using gradient descent
   * 
   * Arguments -
   * a - First class to identify
   * b - Second class to identify
   */
  train(int a, int b) {
    // The perceptron now knows that it is 
    // trained to identify two specific classes
    // namely, a and b.
    _classA = a;
    _classB = b;
    // Create subset of complete data which
    // includes only the two useful classes 
    List<String> subsetData = new List<String>();
    int i=0;
    for (final cls in _trainingClasses) {
      if ( cls == _classA || cls == _classB ) {
        subsetData.add(_trainingData[i]);
      }
      ++i;
    }
    // Run the perceptron to get a new output value
    trainingRun(subsetData); 
    // Implement training formula
    i=0;
    double deltaW = 0.0; // say that three times fast...
    var inputData = parse(subsetData[_k]);
    List<double> _inputs = inputData[_k.toString()];
    for (i=1; i < _inputs.length; ++i) {
      deltaW = Ada * (_trainingClasses[i] - _output) * _inputs[i];
      _weights[i] = _weights[i] + deltaW;
    }
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
   * Report state to the user after a test run
   */
  report() {
    if (_hasRun) {
      // TODO : Print output data list
      
    } else {
      print('Nothing to report. Please run the classifier before reporting.');
    }
  }
}