import 'package:webapp_components/definitions/validator_result.dart';
import 'package:webapp_components/validators/validator_base.dart';
import 'package:webapp_model/id_element.dart';

mixin InputValidator {
  final List<ValidatorBase> validators = [];
  final List<ValidatorResult> results = [];

  void addValidator( ValidatorBase validator ){
    validators.add(validator);
  }


  void validate(){
    // print("Validte of the mixin");
  }

  void validateInputList( List<String> values ) {
    results.clear();
    for( var value in values ){
      validateSingleInput(value, clearPrevious: false);
    }

  }

  void validateSingleInput( String value, {clearPrevious = true} ) {
    if( clearPrevious ){
      results.clear();
    }
    
    results.addAll(
    validators.map((validator) {
      
      var isValid = validator.isValid(value);
      var msg = isValid ?  "" : validator.getInvalidMessage(value: value);
      return ValidatorResult(isValid, msg);
    }));
  }

  bool isInputValid( String value ){
    return validators.isEmpty || !validators.any((v) => !v.isValid(value) );
  }
}