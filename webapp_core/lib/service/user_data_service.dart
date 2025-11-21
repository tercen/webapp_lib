import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_core/runner/utils/cache_object.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;

class UserDataService {
  static final UserDataService _singleton = UserDataService._internal();

  factory UserDataService() {
    return _singleton;
  }
  UserDataService._internal();

  Future<void> createTeam(
      {required String teamName,
      required String owner,
      bool isLibrary = false}) async {
    try {
      await tercen.ServiceFactory().teamService.get(teamName);
      //Team exists, nothing to do
      return;
    } catch (e) {
      final team = sci.Team()
        ..id = teamName
        ..acl.owner = owner
        ..name = teamName;
      team.meta.add(
          sci.Pair.from("is.library", isLibrary == true ? "true" : "false"));

      await tercen.ServiceFactory().teamService.create(team);
    }
  }

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
