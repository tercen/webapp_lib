class Logger {
  static const FINER = 0;
  static const FINE = 50;
  static const WARN = 200;
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