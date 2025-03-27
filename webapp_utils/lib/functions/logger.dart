class Logger {
  static const ALL = 0;
  static const FINER = 50;
  static const FINE = 100;
  static const WARN = 200;

  

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