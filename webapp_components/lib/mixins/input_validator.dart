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
    print("Validte of the mixin");
  }

  void validateInputList( List<IdElement> els ) {
    results.clear();
    for( var el in els ){
      validateSingleInput(el, clearPrevious: false);
    }

  }

  void validateSingleInput( IdElement el, {clearPrevious = true} ) {
    if( clearPrevious ){
      results.clear();
    }
    
    var value = el.label;
    validators.map((validator) {
      
      var isValid = validator.isValid(value);
      var msg = isValid ? validator.getInvalidMessage(value: value) : "";
      print("Validating $value: $isValid : $msg");;
      return ValidatorResult(isValid, msg);
    }).toList();
  }

  bool isInputValid( String value ){
    return validators.isEmpty || !validators.any((v) => !v.isValid(value) );
  }
}