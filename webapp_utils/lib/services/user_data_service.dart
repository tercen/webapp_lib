import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/cache_object.dart';


class UserDataService  {
  static final UserDataService _singleton = UserDataService._internal();
  
  factory UserDataService() {
    return _singleton;
  }
  UserDataService._internal();

  final CacheObject cache = CacheObject();

  Future<List<String>> fetchUserList(String username) async {
    if (cache.hasCachedValue(username)) {
      return cache.getCachedValue(username);
    } else {
      tercen.ServiceFactory factory = tercen.ServiceFactory();

      List<String> teamNameList = [];
      var user = await factory.userService.get(username, useFactory: true);

      for (var ace in user.teamAcl.aces) {
        teamNameList.add(ace.principals[0].principalId);
      }
      teamNameList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      teamNameList.insert(0, username);
      cache.addToCache(username, teamNameList);
      return teamNameList;
    }
  }
}