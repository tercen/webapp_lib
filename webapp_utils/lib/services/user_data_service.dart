import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/mixin/data_cache.dart';

class UserDataService with DataCache {
  Future<List<String>> fetchUserList(String username) async {
    if (hasCachedValue(username)) {
      return getCachedValue(username);
    } else {
      tercen.ServiceFactory factory = tercen.ServiceFactory();

      List<String> teamNameList = [];
      var user = await factory.userService.get(username, useFactory: true);

      for (var ace in user.teamAcl.aces) {
        teamNameList.add(ace.principals[0].principalId);
      }
      teamNameList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      teamNameList.insert(0, username);
      addToCache(username, teamNameList);
      return teamNameList;
    }
  }
}