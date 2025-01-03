mixin ComponentCache {
  //Cache Control
  final Map<String, dynamic> _cacheMap = {};

  dynamic getCachedValue(String key){
    return _cacheMap[key];
  }

  bool hasCachedValue(String key){
    return _cacheMap.containsKey(key);
  }

  void addToCache(String key, dynamic value){
    _cacheMap[key] = value;
  }
}