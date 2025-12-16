import 'package:get/get.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';

class CountController extends GetxController{
  final RoleController _roleController;
  final NoteController _noteController;
  final TaskController _taskController;
  final ClassController _classController;
  final TeamController _teamController;
  final NotificationController _notificationController;

  var noteCounts = <String, RxInt>{}.obs;
  var taskCounts = <String, RxInt>{}.obs;
  var notesCount = 0.obs;
  var tasksCount = 0.obs;
  var notificationCount = 0.obs;
  var groupCount = 0.obs;

  String? errorMessage;

  CountController({
    required RoleController roleController,
    required NoteController noteController, 
    required TaskController taskController,
    required ClassController classController,
    required TeamController teamController,
    required NotificationController notificationController
  }) : _roleController = roleController,
       _noteController = noteController,
       _taskController = taskController,
       _classController = classController,
       _teamController = teamController,
       _notificationController = notificationController;

  Future<void> getNoteCount(String labelId) async {
    final size = await _noteController.getCountByLabel(labelId);
    noteCounts[labelId]!.value = size ?? 0;
  }

  Future<void> getTaskCount(String labelId) async {
    final size = await _taskController.getCountByLabel(labelId);
    taskCounts[labelId]!.value = size ?? 0;
  }

  Future<void> getAllNotesCount() async {
    _noteController.getAllCount();
    notesCount.value = _noteController.totalCount.value;
  }

  Future<void> getAllTasksCount() async {
    _taskController.getAllCount();
    tasksCount.value = _taskController.totalCount.value;
  }

  Future<void> getAllNotificationsCount() async {
    _notificationController.getAllCount();
    notificationCount.value = _notificationController.totalCount.value;
  }

  Future<void> getAllGroupsCount() async {
    bool allowed = _roleController.hasPermission(PermissionType.viewClass);
    int? size;
    if (allowed){
      _classController.getAllCount();
      size = _classController.totalCount.value;
    }
    else{
      _teamController.getAllCount();
      size = _teamController.totalCount.value;
    }
    groupCount.value = size;
  }
}
