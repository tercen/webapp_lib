import 'package:webapp_components/validators/numeric_validator.dart';
import 'package:webapp_components/validators/validator_base.dart';

class RangeValidator extends NumericValidator{
  final int min;
  final bool inclusiveMin;
  final int max;
  final bool inclusiveMax;
  
  RangeValidator(super.id, this.min, this.max, {this.inclusiveMin = true, this.inclusiveMax = true }){
    var gt = inclusiveMin ? ">=" : ">";
    var lt = inclusiveMax ? "<=" : "<";
    super.invalidMessage = "Value must be $min $gt |@| $lt $max";
  }

  bool isValid( String value ){
    if( value == ""){
      return true;
    }else if(super.isValid(value)){
      var numVal = double.parse(value);
      var res = this.inclusiveMin ? numVal >= min : numVal > min;
      res = res && (this.inclusiveMin ? numVal <= max : numVal < max);

      return res;
    }else{
      return false;
    }
  }

}