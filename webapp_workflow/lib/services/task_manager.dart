import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_model/sci_model.dart' as sci;
import 'package:webapp_utils/services/project_data_service.dart';

/// Singleton service that tracks running tasks and their step information
/// This service runs in the background and maintains up-to-date task information
class TaskManager {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  // Current running tasks with their step information
  final Map<String, TaskData> _runningTasks = {};
  
  // Event stream subscriptions per channel
  final Map<String, StreamSubscription> _channelSubscriptions = {};
  
  // Callbacks for when tasks finish (used to trigger UI updates)
  final List<VoidCallback> _taskFinishedCallbacks = [];
  
  // Timer for periodic cleanup
  Timer? _cleanupTimer;
  
  bool _isInitialized = false;

  /// Get all currently running tasks
  List<TaskData> get runningTasks => _runningTasks.values.toList();

  /// Check if the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the task manager (should be called when workflow runner starts)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('[TaskManager] Initializing...');
    
    // Start periodic cleanup of finished tasks
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _cleanupFinishedTasks();
    });
    
    // Load initial tasks
    await _refreshTasks();
    
    _isInitialized = true;
    print('[TaskManager] Initialized with ${_runningTasks.length} running tasks');
  }

  /// Dispose the task manager
  void dispose() {
    _cleanupTimer?.cancel();
    for (var subscription in _channelSubscriptions.values) {
      subscription.cancel();
    }
    _channelSubscriptions.clear();
    _runningTasks.clear();
    _taskFinishedCallbacks.clear();
    _isInitialized = false;
  }

  /// Register a callback to be called when any task finishes
  void addTaskFinishedCallback(VoidCallback callback) {
    _taskFinishedCallbacks.add(callback);
  }

  /// Remove a task finished callback
  void removeTaskFinishedCallback(VoidCallback callback) {
    _taskFinishedCallbacks.remove(callback);
  }

  /// Helper method to fetch project information for a workflow
  Future<Map<String, String>> _getProjectInfo(String workflowId) async {
    try {
      final factory = tercen.ServiceFactory();
      final workflow = await factory.workflowService.get(workflowId);
      final project = await ProjectDataService().fetchProject(projectId: workflow.projectId);
      return {
        'projectId': project.id,
        'projectName': project.name,
      };
    } catch (e) {
      print('[TaskManager] Failed to fetch project info for workflow $workflowId: $e');
      return {
        'projectId': '',
        'projectName': 'Unknown Project',
      };
    }
  }

  /// Register a new workflow task (called by WorkflowRunner when starting a workflow)
  Future<void> registerWorkflowTask(String workflowId, String taskId, String channelId) async {
    print('[TaskManager] Registering workflow task: $taskId for workflow: $workflowId');
    
    try {
      final factory = tercen.ServiceFactory();
      final workflow = await factory.workflowService.get(workflowId);
      final task = await factory.taskService.get(taskId);
      final projectInfo = await _getProjectInfo(workflowId);
      
      final taskData = TaskData(
        taskId: taskId,
        workflowId: workflowId,
        workflowName: workflow.name,
        stepName: workflow.name, // For workflow tasks, use workflow name
        taskType: TaskType.workflow,
        state: task.state.kind,
        channelId: channelId,
        lastUpdate: task.lastModifiedDate,
        projectId: projectInfo['projectId']!,
        projectName: projectInfo['projectName']!,
      );
      
      _runningTasks[taskId] = taskData;
      
      // Subscribe to this channel for events
      _subscribeToChannel(channelId);
      
    } catch (e) {
      print('[TaskManager] Failed to register workflow task $taskId: $e');
    }
  }

  /// Register a new computation task (called when a computation task starts)
  Future<void> registerComputationTask(String taskId, String workflowId, String stepId, String channelId) async {
    print('[TaskManager] Registering computation task: $taskId for step: $stepId');
    
    try {
      final factory = tercen.ServiceFactory();
      final workflow = await factory.workflowService.get(workflowId);
      final task = await factory.taskService.get(taskId);
      final projectInfo = await _getProjectInfo(workflowId);
      
      // Find the step name
      final step = workflow.steps.firstWhere(
        (s) => s.id == stepId,
        orElse: () => sci.Step(),
      );
      
      final stepName = step.id.isNotEmpty ? step.name : 'Unknown Step';
      
      final taskData = TaskData(
        taskId: taskId,
        workflowId: workflowId,
        workflowName: workflow.name,
        stepName: stepName,
        taskType: TaskType.computation,
        state: task.state.kind,
        channelId: channelId,
        lastUpdate: task.lastModifiedDate,
        projectId: projectInfo['projectId']!,
        projectName: projectInfo['projectName']!,
      );
      
      _runningTasks[taskId] = taskData;
      
      // Subscribe to this channel for events
      _subscribeToChannel(channelId);
      
    } catch (e) {
      print('[TaskManager] Failed to register computation task $taskId: $e');
    }
  }

  /// Refresh all tasks from the server (fallback method)
  Future<void> _refreshTasks() async {
    try {
      final factory = tercen.ServiceFactory();
      final rawTasks = await factory.taskService.getTasks([]);
      
      final activeTasks = rawTasks.where((task) =>
        (task.kind == 'RunWorkflowTask' || task.kind == 'RunComputationTask') &&
        !task.state.isFinal &&
        task.state.kind != 'InitState'
      );
      
      // Clear old tasks
      _runningTasks.clear();
      
      // Group tasks by workflow
      final workflowTaskMap = <String, List<sci.Task>>{};
      for (var task in activeTasks) {
        String? workflowId;
        
        if (task is sci.RunWorkflowTask) {
          workflowId = task.workflowId;
        } else if (task is sci.RunComputationTask) {
          // Try to find workflow ID from task metadata
          final workflowMeta = task.meta.firstWhere(
            (m) => m.key == 'workflow.id',
            orElse: () => sci.Pair(),
          );
          if (workflowMeta.value.isNotEmpty) {
            workflowId = workflowMeta.value;
          }
        }
        
        if (workflowId != null) {
          workflowTaskMap.putIfAbsent(workflowId, () => []).add(task);
        }
      }
      
      // Process each workflow's tasks
      for (var entry in workflowTaskMap.entries) {
        try {
          final workflow = await factory.workflowService.get(entry.key);
          final projectInfo = await _getProjectInfo(entry.key);
          
          for (var task in entry.value) {
            String stepName = '';
            TaskType taskType = TaskType.workflow;
            
            if (task is sci.RunComputationTask) {
              taskType = TaskType.computation;
              
              // Try to find the step
              final step = workflow.steps.firstWhere(
                (s) => s.state.taskId == task.id,
                orElse: () => sci.Step(),
              );
              
              stepName = step.id.isNotEmpty ? step.name : 'Unknown Step';
            } else {
              stepName = workflow.name;
            }
            
            final taskData = TaskData(
              taskId: task.id,
              workflowId: workflow.id,
              workflowName: workflow.name,
              stepName: stepName,
              taskType: taskType,
              state: task.state.kind,
              channelId: task.channelId,
              lastUpdate: task.lastModifiedDate,
              projectId: projectInfo['projectId']!,
              projectName: projectInfo['projectName']!,
            );
            
            _runningTasks[task.id] = taskData;
            _subscribeToChannel(task.channelId);
          }
        } catch (e) {
          print('[TaskManager] Failed to process workflow ${entry.key}: $e');
        }
      }
      
      print('[TaskManager] Refreshed ${_runningTasks.length} running tasks');
      
    } catch (e) {
      print('[TaskManager] Failed to refresh tasks: $e');
    }
  }

  /// Subscribe to a channel for task events
  void _subscribeToChannel(String channelId) {
    if (_channelSubscriptions.containsKey(channelId)) {
      return; // Already subscribed
    }
    
    try {
      final factory = tercen.ServiceFactory();
      final stream = factory.eventService.channel(channelId);
      
      final subscription = stream.listen(
        (event) {
          if (event is sci.TaskStateEvent) {
            _handleTaskStateEvent(event);
          }
        },
        onError: (error) {
          print('[TaskManager] Error in channel $channelId stream: $error');
        },
        onDone: () {
          _channelSubscriptions.remove(channelId);
        },
      );
      
      _channelSubscriptions[channelId] = subscription;
      print('[TaskManager] Subscribed to channel: $channelId');
      
    } catch (e) {
      print('[TaskManager] Failed to subscribe to channel $channelId: $e');
    }
  }

  /// Handle task state events
  void _handleTaskStateEvent(sci.TaskStateEvent event) {
    final taskId = event.taskId;
    
    if (_runningTasks.containsKey(taskId)) {
      // Update existing task
      final taskData = _runningTasks[taskId]!;
      _runningTasks[taskId] = taskData.copyWith(state: event.state.kind);
      
      print('[TaskManager] Updated task $taskId state to ${event.state.kind}');
      
      if (event.state.isFinal) {
        // Task finished
        final taskData = _runningTasks[taskId]!;
        _runningTasks.remove(taskId);
        _channelSubscriptions[taskData.channelId]?.cancel();
        _channelSubscriptions.remove(taskData.channelId);
        
        print('[TaskManager] Task $taskId finished, removed from tracking');
        
        // Only notify callbacks when workflow tasks finish (not computation tasks)
        // This prevents excessive UI updates for individual computation steps
        if (taskData.taskType == TaskType.workflow) {
          print('[TaskManager] Workflow task finished, notifying callbacks');
          for (var callback in _taskFinishedCallbacks) {
            try {
              callback();
            } catch (e) {
              print('[TaskManager] Error in task finished callback: $e');
            }
          }
        }
      }
    } else {
      // Unknown task - might be a new computation task
      if (!event.state.isFinal) {
        _handleUnknownTask(taskId, event);
      }
    }
  }

  /// Handle unknown tasks that appear in events (auto-discovery of computation tasks)
  Future<void> _handleUnknownTask(String taskId, sci.TaskStateEvent event) async {
    try {
      final factory = tercen.ServiceFactory();
      final task = await factory.taskService.get(taskId);
      
      if (task is sci.RunComputationTask) {
        // Try to find workflow and step information from event metadata
        final workflowMeta = event.meta.firstWhere(
          (m) => m.key == 'workflow.id',
          orElse: () => sci.Pair(),
        );
        
        final stepMeta = event.meta.firstWhere(
          (m) => m.key == 'step.id',
          orElse: () => sci.Pair(),
        );
        
        if (workflowMeta.value.isNotEmpty) {
          final workflow = await factory.workflowService.get(workflowMeta.value);
          
          String stepName = 'Unknown Step';
          if (stepMeta.value.isNotEmpty) {
            // Find the step by ID
            final step = workflow.steps.firstWhere(
              (s) => s.id == stepMeta.value,
              orElse: () => sci.Step(),
            );
            if (step.id.isNotEmpty) {
              stepName = step.name;
            }
          } else {
            // Try to find step by task ID
            final step = workflow.steps.firstWhere(
              (s) => s.state.taskId == taskId,
              orElse: () => sci.Step(),
            );
            if (step.id.isNotEmpty) {
              stepName = step.name;
            }
          }
          
          final taskData = TaskData(
            taskId: taskId,
            workflowId: workflow.id,
            workflowName: workflow.name,
            stepName: stepName,
            taskType: TaskType.computation,
            state: event.state.kind,
            channelId: task.channelId,
            lastUpdate: task.lastModifiedDate,
            projectId: '', // TODO: Set actual project ID
            projectName: '', // TODO: Set actual project name
          );
          
          _runningTasks[taskId] = taskData;
          print('[TaskManager] Auto-discovered computation task: $taskId ($stepName)');
        }
      }
    } catch (e) {
      print('[TaskManager] Failed to handle unknown task $taskId: $e');
    }
  }

  /// Clean up finished tasks periodically
  void _cleanupFinishedTasks() {
    final tasksToRemove = <String>[];
    
    for (var entry in _runningTasks.entries) {
      // Check if task still exists on server
      tercen.ServiceFactory().taskService.get(entry.key).then((task) {
        if (task.state.isFinal) {
          tasksToRemove.add(entry.key);
        }
      }).catchError((e) {
        // Task doesn't exist anymore, remove it
        tasksToRemove.add(entry.key);
      });
    }
    
    for (var taskId in tasksToRemove) {
      final taskData = _runningTasks[taskId];
      if (taskData != null) {
        _runningTasks.remove(taskId);
        _channelSubscriptions[taskData.channelId]?.cancel();
        _channelSubscriptions.remove(taskData.channelId);
        
        // Notify callbacks that a task finished
        for (var callback in _taskFinishedCallbacks) {
          try {
            callback();
          } catch (e) {
            print('[TaskManager] Error in task finished callback: $e');
          }
        }
      }
    }
    
    if (tasksToRemove.isNotEmpty) {
      print('[TaskManager] Cleaned up ${tasksToRemove.length} finished tasks');
    }
  }

  /// Get task data by task ID
  TaskData? getTask(String taskId) {
    return _runningTasks[taskId];
  }

  /// Get all tasks for a specific workflow
  List<TaskData> getTasksForWorkflow(String workflowId) {
    return _runningTasks.values
        .where((task) => task.workflowId == workflowId)
        .toList();
  }

  /// Check if a workflow has running tasks
  bool hasRunningTasks(String workflowId) {
    return _runningTasks.values.any((task) => task.workflowId == workflowId);
  }

  /// Get count of running tasks
  int get runningTaskCount => _runningTasks.length;
}

/// Data class representing a task
class TaskData {
  final String taskId;
  final String workflowId;
  final String workflowName;
  final String stepName;
  final TaskType taskType;
  final String state;
  final String channelId;
  final sci.Date lastUpdate;
  final String projectId;
  final String projectName;

  TaskData({
    required this.taskId,
    required this.workflowId,
    required this.workflowName,
    required this.stepName,
    required this.taskType,
    required this.state,
    required this.channelId,
    required this.lastUpdate,
    required this.projectId,
    required this.projectName,
  });

  TaskData copyWith({
    String? taskId,
    String? workflowId,
    String? workflowName,
    String? stepName,
    TaskType? taskType,
    String? state,
    String? channelId,
    sci.Date? lastUpdate,
    String? projectId,
    String? projectName,
  }) {
    return TaskData(
      taskId: taskId ?? this.taskId,
      workflowId: workflowId ?? this.workflowId,
      workflowName: workflowName ?? this.workflowName,
      stepName: stepName ?? this.stepName,
      taskType: taskType ?? this.taskType,
      state: state ?? this.state,
      channelId: channelId ?? this.channelId,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
    );
  }

  @override
  String toString() {
    return 'TaskData(taskId: $taskId, workflowName: $workflowName, stepName: $stepName, type: $taskType, state: $state, project: $projectName)';
  }
}

/// Enum for task types
enum TaskType {
  workflow,
  computation,
}

/// Extension to get display name for task type
extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.workflow:
        return 'Workflow';
      case TaskType.computation:
        return 'Computing';
    }
  }
}
