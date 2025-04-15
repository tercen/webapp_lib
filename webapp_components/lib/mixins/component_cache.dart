// mixin ComponentCache {
//   //Cache Control
//   final Map<String, dynamic> _cacheMap = {};
//   bool useCache = true;

//   dynamic getCachedValue(String key){
//     return _cacheMap[key];
//   }

//   bool hasCachedValue(String key){
//     return useCache && _cacheMap.containsKey(key);
//   }

//   void addToCache(String key, dynamic value){
//     _cacheMap[key] = value;
//   }

//   void clearCache(){
//     _cacheMap.clear();
//   }
// }