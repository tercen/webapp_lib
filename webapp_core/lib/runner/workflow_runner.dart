import 'package:intl/intl.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_core/runner/utils/workflow/workflow_folder_config.dart';

enum TimestampType { full, short }

typedef PostRunCallback = Future<sci.Workflow> Function(sci.Workflow workflow);

class WorkflowRunner {
  final List<PostRunCallback> _callbacks = [];
  final WorkflowFolderConfig? workflowFolder;
  late final String timestamp;

  WorkflowRunner(
      {var timestampType = TimestampType.full, this.workflowFolder}) {
    if (timestampType == TimestampType.short) {
      timestamp = DateFormat("yyyy.MM.dd").format(DateTime.now());
    } else {
      timestamp = DateFormat("yyyy.MM.dd_HH:mm").format(DateTime.now());
    }
  }

  void addPostRun({required PostRunCallback callback}) {
    _callbacks.add(callback);
  }

  Future<sci.Workflow> copyToProject(
      {required String projectId,
      required String workflowId,
      String? workflowName,
      required String teamName,
      String folderId = ""}) async {
    var factory = tercen.ServiceFactory();
    var workflow = await tercen.ServiceFactory()
        .workflowService
        .copyApp(workflowId, projectId);

    workflow.folderId = await workflowFolder?.getFolderId(
            projectId: projectId, owner: teamName) ??
        "";
    workflow.name = workflowName ?? workflow.name;
    workflow.acl = (sci.Acl()..owner = teamName);
    workflow.isHidden = false;
    workflow.isDeleted = false;
    workflow.projectId = projectId;

    workflow.id = "";
    workflow.rev = "";
    // print("WorkflowFolder -- ${workflow.folderId}");
    // print("WorkflowOwner -- ${workflow.acl.owner}");
    workflow = await factory.workflowService.create(workflow);

    return workflow;
  }

  Future<sci.Workflow> saveWorkflow( {required sci.Workflow workflow}) async {
    workflow.rev = await tercen.ServiceFactory().workflowService.update(workflow);
    return workflow;
  }


  Future<sci.Workflow> runWorkflow({required sci.Workflow workflow, List<String> stepsToRun = const [], List<String> stepsToReset = const[],
     bool persistentEvents = true,
     bool saveAfterRun = true,
     Function? onTaskProgress,
     Function? onTaskState}) async{
    var workflowTask = sci.RunWorkflowTask()
      ..state = sci.InitState()
      ..owner = workflow.acl.owner
      ..projectId = workflow.projectId
      ..workflowId = workflow.id
      ..workflowRev = workflow.rev;

    if( persistentEvents ){
      workflowTask.meta.add(sci.Pair.from("channel.persistent", "true"));
    }


    if (stepsToRun.isNotEmpty) {
      workflowTask.stepsToRun.addAll(stepsToRun);
    }

    if (stepsToReset.isNotEmpty) {
      workflowTask.stepsToReset.addAll(stepsToReset);
    }
    
    workflowTask =
        await tercen.ServiceFactory().taskService.create(workflowTask) as sci.RunWorkflowTask;

    workflow.addMeta("run.workflow.task.id", workflowTask.id);
    workflow.rev = await tercen.ServiceFactory().workflowService.update(workflow);

    var taskStream = tercen.ServiceFactory().eventService.channel(workflowTask.channelId);

    await tercen.ServiceFactory().taskService.runTask(workflowTask.id);

    await for (var evt in taskStream) {
      if (evt is sci.PatchRecords) {
        workflow = evt.apply(workflow);
      }
      if (evt is sci.TaskStateEvent) {
        if( onTaskState != null ){
          onTaskState( evt );
        }
        if (evt.state.isFinal && evt.taskId == workflowTask.id) {
          break;
        }
      }
      if (evt is sci.TaskProgressEvent) {
        if( onTaskProgress != null ){
          onTaskProgress( evt.message );
        }
      }
      if (evt is sci.TaskLogEvent) {
        if( onTaskProgress != null ){
          onTaskProgress( evt.message );
        }
      }
    }

    if( saveAfterRun ){
      workflow.rev = await tercen.ServiceFactory().workflowService.update(workflow);    
    }


    return workflow;
  }



}
