import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';

class CountController extends GetxController {
  late final RoleController _roleController;
  late final NoteController _noteController;
  late final TaskController _taskController;
  late final ClassController _classController;
  late final TeamController _teamController;
  late final NotificationController _notificationController;

  var noteCounts = <String, RxInt>{}.obs;
  var taskCounts = <String, RxInt>{}.obs;
  var notesCount = 0.obs;
  var tasksCount = 0.obs;
  var notificationCount = 0.obs;
  var groupCount = 0.obs;

  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    _roleController = Get.find<RoleController>();
    _noteController = Get.find<NoteController>();
    _taskController = Get.find<TaskController>();
    _classController = Get.find<ClassController>();
    _teamController = Get.find<TeamController>();
    _notificationController = Get.find<NotificationController>();
    final AuthenticationController authController = Get.find<AuthenticationController>();
    ever(authController.user, (user) {
      if (user != null) {
        getAllNotesCount();
        getAllTasksCount();
        getAllNotificationsCount();
        getAllGroupsCount();
      } else {
        noteCounts.value = {};
        taskCounts.value = {};
        notesCount.value = 0;
        tasksCount.value = 0;
        notificationCount.value = 0;
        groupCount.value = 0;
      }
    });
  }

  Future<void> getNoteCount(String labelId) async {
    final size = await _noteController.getCountByLabel(labelId);
    noteCounts[labelId]!.value = size ?? 0;
  }

  Future<void> getTaskCount(String labelId) async {
    final size = await _taskController.getCountByLabel(labelId);
    taskCounts[labelId]!.value = size ?? 0;
  }

  void getAllNotesCount() {
    _noteController.getAllCount();
    ever(_noteController.totalCount, (int newCount) {
      notesCount.value = newCount;
    });
  }

  void getAllTasksCount() {
    _taskController.getAllCount();
    ever(_taskController.totalCount, (int newCount) {
      tasksCount.value = newCount;
    });
  }

  void getAllNotificationsCount() {
    _notificationController.getAllCount();
    ever(_notificationController.totalCount, (int newCount) {
      notificationCount.value = newCount;
    });
  }

  void getAllGroupsCount() {
    bool allowed = _roleController.hasPermission(PermissionType.viewClass);
    if (allowed) {
      _classController.getAllCount();
      ever(_classController.totalCount, (int newCount) {
        groupCount.value = newCount;
      });
    } else {
      _teamController.getAllCount();
      ever(_teamController.totalCount, (int newCount) {
        groupCount.value = newCount;
      });
    }
  }
}
