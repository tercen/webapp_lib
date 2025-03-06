class ValidatorBase {
  String invalidMessage;

  ValidatorBase({this.invalidMessage = "Input |@| is invalid."});
  
  bool isValid( String value ){
    throw Exception("isValid is not implemented for ValidatorBase");
  }

  String getInvalidMessage({String? value}){
    if( value != null){
      return invalidMessage.replaceFirst("|@|", "'$value'");
    }else{
      return invalidMessage.replaceFirst("|@|", "");
    }
    
  }
}