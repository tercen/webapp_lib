import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_commons/utils/logger.dart';

class SimpleCache {
  static const Map<String, dynamic> _cacheMap = {};


  static dynamic getCachedValue(String key){
    return _cacheMap[key];
  }

  static bool hasCachedValue(String key){
    return _cacheMap.containsKey(key);
  }

  static void addToCache(String key, dynamic value){
    if (key.isEmpty) {
      throw sci.ServiceError(500, "Inalid Cache Key", "Cache key cannot be empty.");
    }
    if (value == null) {
      Logger().log(
        level: Logger.WARN,
        message: "Cannot add null value to: $key. Value will be ignored."
      );
      return;
    }

    if( SimpleCache.hasCachedValue(key)){
      Logger().log(
        level: Logger.FINE,
        message: "Overwriting existing cache for key: $key"
      );
    }
    _cacheMap[key] = value;
  }

  static void clearCache(){
    _cacheMap.clear();
  }

  static void invalidateCache(String key) {
    _cacheMap.remove(key);
  }

  static List<String> get cacheKeys => _cacheMap.keys.toList();
}