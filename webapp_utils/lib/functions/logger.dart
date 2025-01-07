class Logger {
  static const ALL = 0;
  static const DEBUG = 50;
  static const WARN = 100;
  static const INFO = 200;
  

  int currenLevel = Logger.WARN;

  static final Logger _singleton = Logger._internal();

  factory Logger() {
    return _singleton;
  }

  Logger._internal();

  String levelString(int level){
    switch (level) {
      case Logger.DEBUG:
        return "[DEBUG] ";
      case Logger.WARN:
        return "[WARN] ";
      case Logger.INFO:
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