class Logger {
  static const NONE = 0;
  static const WARN = 50;
  static const FINER = 100;
  static const FINE = 250;
  static const INFO = 500;
  static const ALL =  100000;

  

  int currenLevel = Logger.WARN;

  static final Logger _singleton = Logger._internal();

  factory Logger() {
    return _singleton;
  }

  Logger._internal();

  String levelString(int level){
    switch (level) {
      case Logger.FINE:
        return "[FINE] ";
      case Logger.FINER:
        return "[FINER] ";
      case Logger.WARN:
        return "[WARN] ";
      case Logger.ALL:
        return "[INFO] ";
      default:
        return "";
    }
  }

  void log( { int level = Logger.WARN, String message = "" } ){
    if( level <= currenLevel ){
      print("${levelString(level)}$message");
    }
  }
  
}