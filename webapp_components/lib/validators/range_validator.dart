import 'package:webapp_components/validators/validator_base.dart';

class RangeValidator extends ValidatorBase{
  final int min;
  final bool inclusiveMin;
  final int max;
  final bool inclusiveMax;
  
  RangeValidator(super.id, this.min, this.max, {this.inclusiveMin = true, this.inclusiveMax = true});

  bool isValid( String value ){
    if(super.isValid(value)){
      var numVal = double.parse(value);
      var res = this.inclusiveMin ? numVal >= min : numVal > min;
      res = res && (this.inclusiveMin ? numVal <= max : numVal < max);

      return res;
    }else{
      return false;
    }
  }

}