import 'package:webapp_components/validators/validator_base.dart';

class NumericValidator extends ValidatorBase{
  NumericValidator(super.id, {super.invalidMessage = "Input |@| must be numeric."});

  bool isValid( String value ){
    return value == "" || int.tryParse(value) != null || double.tryParse(value) != null;
  }
}