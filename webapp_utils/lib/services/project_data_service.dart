import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_utils/mixin/data_cache.dart';

class ProjectDataService with DataCache {
  Future<Project> doCreateProject(IdElement projectEl, String team, {String appName = "", String appVersion = ""}) async {
    var factory = tercen.ServiceFactory();
    var projectName = projectEl.label;

    var userProjects = await factory.projectService
        .findByTeamAndIsPublicAndLastModifiedDate(
            startKey: [team, true, '2100'], endKey: [team, false, '']);

    
    for (var p in userProjects) {
      if (p.name == projectName) {
        return p;
      }
    }

    var project = Project();

    project.name = projectName;
    project.acl.owner = team;

    project.meta.add(Pair.from("APP_URL",
        appName));
    project.meta.add(Pair.from("APP_VERSION", appVersion));

    project = await factory.projectService.create(project);

    return project;
  }

}
