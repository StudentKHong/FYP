import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/count_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/setting_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Repository/auth_repository.dart';
import 'package:note_taking_app/Model/Repository/class_repository.dart';
import 'package:note_taking_app/Model/Repository/label_repository.dart';
import 'package:note_taking_app/Model/Repository/note_repository.dart';
import 'package:note_taking_app/Model/Repository/notification_repository.dart';
import 'package:note_taking_app/Model/Repository/setting_repository.dart';
import 'package:note_taking_app/Model/Repository/task_repository.dart';
import 'package:note_taking_app/Model/Repository/team_repository.dart';
import 'package:note_taking_app/Service/conectivity_service.dart';
import 'package:note_taking_app/Service/upload_image_service.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_theme.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';
import 'package:timezone/data/latest.dart';
import 'package:note_taking_app/UI/login.dart';
import 'package:timezone/data/latest.dart';
import 'package:toastification/toastification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _configureLocalTimeZone() async {
  final String currentTimeZone = await FlutterN
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimeZones();
  await Firebase.initializeApp();

  // Initialize notification settings.
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
  InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      final String? taskId = response.payload;
      if (taskId != null) {
        final taskController = Get.find<TaskController>();
        taskController.getById(taskId);
        final task = taskController.content.value;
        if (task != null) {
          Get.to(() => TaskDetailScreen(mode: Mode.view, task: task));
        }
      }
    },
  );

  // Initialize global repositories.
  Get.put<AuthenticationRepository>(AuthenticationRepository());

  // Initialize global controllers.
  Get.put(AuthenticationController(), permanent: true);
  Get.put(NoteRepository(), permanent: true);
  Get.put(TaskRepository(), permanent: true);
  Get.put(LabelRepository(), permanent: true);
  Get.put(ClassRepository(), permanent: true);
  Get.put(TeamRepository(), permanent: true);
  // Get.put(CountRepository(), permanent: true);
  Get.put(NotificationRepository(), permanent: true);
  Get.put(SettingRepository(), permanent: true);

  // Initialize global controllers.
  final roleController = Get.put(RoleController(), permanent: true);
  Get.put(LabelController(), permanent: true);
  final noteController = Get.put(NoteController(), permanent: true);
  final taskController = Get.put(TaskController(), permanent: true);
  final classController = Get.put(ClassController(), permanent: true);
  final teamController = Get.put(TeamController(), permanent: true);
  final notificationController = Get.put(
    NotificationController(),
    permanent: true,
  );
  Get.put(SettingController(), permanent: true);

  final themeController = Get.put(ThemeController(), permanent: true);

  Get.put(
    CountController(
      roleController: roleController,
      noteController: noteController,
      taskController: taskController,
      classController: classController,
      teamController: teamController,
      notificationController: notificationController,
    ),
    permanent: true,
  );

  // Get.put(NoteTaskController<Task>(repository: TaskRepository(uid: uid)));
  runApp(
    ToastificationWrapper(
      child: GetMaterialApp(
        title: 'Note Taking App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.theme,
        initialRoute: Routes.login,
        getPages: Routes.pages,
        localizationsDelegates: [FlutterQuillLocalizations.delegate],
        home: LoginScreen(),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Get.putAsync(() async => ConnectivityService());
    await themeController.loadLocalTheme();
    await Get.putAsync<UploadImageService>(() async {
      final service = UploadImageService();
      await service.onInit();
      return service;
    });
  });
}
