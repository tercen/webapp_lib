// import 'package:flutter/services.dart';
// import 'package:json_string/json_string.dart';

// class StepMap {
//   final String shortName;
//   final String stepName;
//   final String stepId;

//   StepMap(this.shortName, this.stepName, this.stepId);
// }

// class WorkflowStepsMapper {
//   final Map<String, StepMap> _stepMap = {};

  

//   String _buildKey(String workflowKey, String shortName) {
//     return "${workflowKey}_$shortName";
//   }

//   String getStepId(String workflowKey, String shortName){
//     var key = _buildKey(workflowKey, shortName);

//     if( _stepMap.containsKey(key)){
//       return _stepMap[key]!.stepId;
//     }else{
//       return "";
//     }
//   }

//   Future<void> loadSettingsFile(String path) async {
//     if( path == ""){
//       return;
//     }
//     try {
//       String settingsStr = await rootBundle.loadString(path);
    
//       final jsonString = JsonString(settingsStr);
//       final stepsJson = jsonString.decodedValueAsMap;

//       var workflowKeys = stepsJson.keys;

//       for (var key in workflowKeys) {
//         for (int i = 0; i < stepsJson[key].length; i++) {
//           Map<String, dynamic> jsonEntry = stepsJson[key][i];

//           StepMap step = StepMap(jsonEntry["shortName"], jsonEntry["stepName"],
//               jsonEntry["stepId"]);

//           var mapKey = _buildKey(key, step.shortName);
//           _stepMap[mapKey] = step;
//         }
//       }
//     } on Exception catch (e) {
//       print('Invalid JSON: $e');
//     }
//   }
// }
