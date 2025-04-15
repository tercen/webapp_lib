import 'dart:async';

class CacheObject {
  final Map<String, dynamic> _cacheMap = {};
  final Map<String, dynamic> _cacheTime = {};

  CacheObject(){
    Timer.periodic(const Duration(seconds: 10), (timer){
      //Avoid concurrent access exception
      var keys = List.from(_cacheTime.keys);

      for( var key in keys ){
        var dt = DateTime.now().difference(_cacheTime[key]);
        if( dt.inMinutes > 10 ){

          _cacheMap.remove(key);
          _cacheTime.remove(key);

        }
      }

      
      if( _cacheMap.isEmpty ){
        timer.cancel();
      }

    });
  }

  dynamic getCachedValue(String key){
    return _cacheMap[key];
  }

  bool hasCachedValue(String key){
    return _cacheMap.containsKey(key);
  }

  void addToCache(String key, dynamic value){
    _cacheMap[key] = value;
    _cacheTime[key] = DateTime.now();
  }

  void clearCache(){
    _cacheMap.clear();
    _cacheTime.clear();
  }

  List<String> get cacheKeys => _cacheMap.keys.toList();

}