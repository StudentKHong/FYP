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
import 'package:note_taking_app/UI/Navigation/ui_scaffold_state.dart';
import 'package:note_taking_app/UI/SharedComponents/app_theme.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';
import 'package:timezone/data/latest.dart';
import 'package:note_taking_app/UI/login.dart';
import 'package:toastification/toastification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimeZones();
  await Firebase.initializeApp();

  // Initialize global repositories.
  Get.put<AuthenticationRepository>(
    AuthenticationRepository(),
    permanent: true,
  );

  // Initialize global controllers.
  Get.put(AuthenticationController(), permanent: true);
  Get.put(NoteRepository(), permanent: true);
  Get.put(TaskRepository(), permanent: true);
  Get.put(LabelRepository(), permanent: true);
  Get.put(ClassRepository(), permanent: true);
  Get.put(TeamRepository(), permanent: true);
  Get.put(NotificationRepository(), permanent: true);
  Get.put(SettingRepository(), permanent: true);

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
    onDidReceiveNotificationResponse: (response) async {
      final String? taskId = response.payload;
      if (taskId != null) {
        final taskController = Get.find<TaskController>();
        await taskController.getById(taskId);
        final task = taskController.content.value;
        if (task != null) {
          final notificationController = Get.find<NotificationController>();
          notificationController.markReadStatus(response.id.toString(), true);
          Get.to(() => TaskDetailScreen(mode: Mode.view, task: task));
        }
      }
    },
  );

  // Initialize global controllers.
  Get.put(RoleController(), permanent: true);
  Get.put(LabelController(), permanent: true);
  Get.put(NoteController(), permanent: true);
  Get.put(TaskController(), permanent: true);
  Get.put(ClassController(), permanent: true);
  Get.put(TeamController(), permanent: true);
  Get.put(NotificationController(), permanent: true);
  Get.put(SettingController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(CountController(), permanent: true);

  // Get.put(NoteTaskController<Task>(repository: TaskRepository(uid: uid)));
  runApp(
    ToastificationWrapper(
      child: GetMaterialApp(
        initialBinding: BindingsBuilder(() {
          Get.put(UIScaffoldState());
        }),
        title: 'Note Taking App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: Get.find<ThemeController>().theme,
        initialRoute: Routes.login,
        getPages: Routes.pages,
        localizationsDelegates: [FlutterQuillLocalizations.delegate],
        home: LoginScreen(),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Get.putAsync(() async => ConnectivityService());
    await Get.find<ThemeController>().loadLocalTheme();
    await Get.putAsync<UploadImageService>(() async {
      final service = UploadImageService();
      await service.onInit();
      return service;
    });
  });
}
