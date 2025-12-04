import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_core/runner/utils/functions/logger.dart';
import 'package:webapp_core/service/project_data_service.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

class LibraryDataService {
  static Future<void> installOperator({
    required String url,
    required String team,
    String? projectName,
    String? tag,
    String? branch,
    String? authToken,
  }) async {
    var tagName = tag ?? "latest";
    var proj = await ProjectDataService().fetchProjectByName(
            projectName: "${url}@${tagName}_Test", owner: team) ??
        Project();
    if (proj.id.isEmpty) {
      Logger().log(
          level: Logger.FINE,
          message: "${url}@${tagName}_Test not found. Creating project");
      proj = await ProjectDataService()
          .createProject(name: "${url}@${tagName}_Test", owner: team);

      await _installFromGit(team, proj, authToken, branch, url, tag);
    }
  }

  static Future<void> _installFromGit(String team, Project proj,
      String? authToken, String? branch, String url, String? tag) async {
    final importTask = GitProjectTask()
      ..owner = team
      ..state = InitState();

    importTask.meta.add(Pair.from("PROJECT_ID", proj.id));
    importTask.meta.add(Pair.from("PROJECT_REV", proj.rev));
    importTask.meta.add(Pair.from("GIT_ACTION", "reset/pull"));
    importTask.meta.add(Pair.from("GIT_PAT", authToken ?? ""));
    importTask.meta.add(Pair.from("GIT_BRANCH", branch ?? "main"));
    importTask.meta.add(Pair.from("GIT_URL", url));
    importTask.meta.add(Pair.from("GIT_MESSAGE", ""));

    if (tag != null) {
      importTask.meta.add(Pair.from("GIT_TAG", tag));
    } else if (branch != null) {
      importTask.meta.add(Pair.from("GIT_TAG", branch));
    }

    var task = await tercen.ServiceFactory().taskService.create(importTask);
    await tercen.ServiceFactory().taskService.runTask(task.id);
    task = await tercen.ServiceFactory().taskService.waitDone(task.id);
  }
}
