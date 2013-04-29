import 'dart:core';
import 'dart:io';
import 'dart:json';
import 'dart:math';

void main() {
  // Output
  num output = 0;
  
  // Data
  Path data_path = new Path(r'bin/optdigits.train');
  var data_file = new File.fromPath(data_path);
  List<String> data;
  // Read training data file to list of Strings
  data = data_file.readAsLinesSync();
  //print(data);
  
  // Perceptron classifier
  pClassifier pc = new pClassifier(data);
  // Train the classifier
  pc.train();
  // Report findings
//  pc.report();
  
  //print("Hello, World!");
}

/**
 * Perceptron classifier class
 */
class pClassifier {
  /**
   * Prepended underscore character  
   * indicates private class variable.
   */
  // Learning Rate
  const num Ada = 0.2;
  // Weights
  List <double> _weights;
  // Classes
  List <int> _classes;
  // Input
  List<String> _data;
  const int _number_of_inputs  = 64;
  const int _number_of_weights = 65;
  // Output
  double _output = 0.0;
  // K is the current epoch; 
  // The number of times the classifier has been run.
  // We assume that this number is smaller than the 
  // maximum size of an int. (Perhaps a bad assumption...)
  int _k=0;
  // Random seed
  var _rand = new Random();

  /**
   * Constructor:
   * Set initial values for our 
   * Perceptron Classifier
   */
  pClassifier(List<String> inputData) {
    // Initial weights
    _weights = new List<double>();
    // Set to random values
    int i=0;
    for (i=0; i < _number_of_weights; ++i) {
      // Generates random double to one
      // decimal of precision s.t. 
      // (0 <= d <= 0.9), then adds that
      // value to our list of weights.
      _weights.add(_rand.nextInt(10).toDouble()/10);
    }
//    print(_weights);
    // Input
    // Get classes from data
    _classes  = createClasses(inputData); 
    // Convert input to Json
    _data   = createFeatures(inputData);
//    print(_data);
//    print(_classes);
  }
  
  /** 
   * Output function - 
   * Run the Perceptron to get output "o"
   */
  run(inputs) {
    int i=0;
    for (i=1; i < inputs.length; ++i) {
      _output = _output + (_weights[i] * inputs[i]) + _weights[0]; 
    }
    ++_k;
  }

  /** 
   * Wrapper for output function - 
   * Run the Perceptron to get output "o"
   * to be used during training
   */
  training_run() {
    var inputData = parse(_data[_k]);
    List<double> _inputs = inputData[_k.toString()];
    run(_inputs);
  }
  
  /** 
   * Training function -
   * Train the classifier (one epoch)
   * using gradient descent
   */
  train() {
    training_run(); // Run the perceptron to get a new output value
    int i=0;
    double delta_w = 0.0; // say that three times fast...
    var inputData = parse(_data[_k]);
    List<double> _inputs = inputData[_k.toString()];
    for (i=1; i < _inputs.length; ++i) {
      delta_w = Ada * (_classes[i] - _output) * _inputs[i];
      _weights[i] = _weights[i] + delta_w;
    }
  }
  
  /**
   * Report state to the user
   */
  report() {
    
  }
  
  createClasses(List<String> data) {
    List<int> classes = new List<int>();
    RegExp classDigit = new RegExp(r'\d+$');
    for (final item in data) {
      classes.add(int.parse(classDigit.firstMatch(item).group(0)));
    }
    return classes;
  }
  
  createFeatures(List<String> data) {
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
}