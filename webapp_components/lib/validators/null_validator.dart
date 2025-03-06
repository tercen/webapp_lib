import 'package:webapp_components/validators/validator_base.dart';

class NullValidator extends ValidatorBase{
  NullValidator({super.invalidMessage = "Input cannot be empty."});

  bool isValid( String value ){
    return value != "";
  }
}