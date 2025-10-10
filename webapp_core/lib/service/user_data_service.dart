import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_core/runner/utils/cache_object.dart';

class UserDataService {
  static final UserDataService _singleton = UserDataService._internal();

  factory UserDataService() {
    return _singleton;
  }
  UserDataService._internal();

  Future<List<String>> fetchUserList(
      {required String username,
      bool useCache = true,
      bool includeUserInList = true}) async {
    final key = "fetchUserList_$username";
    if (useCache && CacheObject().hasCachedValue(key)) {
      return CacheObject().getCachedValue(key);
    } else {
      final teamNameList = <String>[];
      var user = await tercen.ServiceFactory()
          .userService
          .get(username, useFactory: true);

      for (var ace in user.teamAcl.aces) {
        teamNameList.add(ace.principals[0].principalId);
      }
      teamNameList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (includeUserInList) {
        teamNameList.insert(0, username);
      }

      if (useCache) {
        CacheObject().addToCache(key, teamNameList);
      }

      return teamNameList;
    }
  }
}
