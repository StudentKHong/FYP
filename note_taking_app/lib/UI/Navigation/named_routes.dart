import 'package:get/get.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Models/team_model.dart';
import 'package:note_taking_app/UI/add_attachment.dart';
import 'package:note_taking_app/UI/calendar.dart';
import 'package:note_taking_app/UI/create_group.dart';
import 'package:note_taking_app/UI/create_label.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';
import 'package:note_taking_app/UI/home.dart';
import 'package:note_taking_app/UI/login.dart';
import 'package:note_taking_app/UI/list_screen.dart';
import 'package:note_taking_app/UI/notifications.dart';
import 'package:note_taking_app/UI/profile.dart';
import 'package:note_taking_app/UI/register.dart';
import 'package:note_taking_app/UI/settings.dart';

class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String notes = '/notes';
  static const String notesByLabel = '/notes/:labelId';
  static const String createNote = '/add-note';
  static const String editNote = '/edit-note';
  static const String selectNote = '/select-note';
  static const String tasks = '/tasks';
  static const String tasksByLabel = '/tasks/:labelId';
  static const String createTask = '/add-task';
  static const String selectTask = '/select-task';
  static const String editTask = '/edit-task';
  static const String addAttachment = '/add-attachment';
  static const String noteLabels = '/note-labels';
  static const String taskLabels = '/task-labels';
  static const String classes = '/classes';
  static const String teams = '/teams';
  static const String createClass = '/create-class';
  static const String createTeam = '/create-team';

  static String notesByLabelWithId(String labelId) => '/notes/$labelId';
  static String tasksByLabelWithId(String labelId) => '/tasks/$labelId';

  static final List<GetPage> pages = [
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: register, page: () => RegistrationScreen()),

    GetPage(name: home, page: () => HomeScreen()),
    GetPage(name: profile, page: () => ProfileScreen()),
    GetPage(name: calendar, page: () => CalendarScreen()),
    GetPage(name: notifications, page: () => NotificationsScreen()),
    GetPage(name: settings, page: () => SettingsScreen()),

    GetPage(
      name: notes,
      page: () => ListScreen<Note>(
        title: 'Notes',
        pageType: ListScreenType.notes,
        controller: Get.find<NoteController>(),
        onAddTap: () => Get.toNamed(Routes.createNote),
      ),
    ),
    GetPage(
      name: notesByLabel,
      page: () {
        final labelId = Get.parameters['labelId']!.toString();
        final args = Get.arguments as Map<String, dynamic>?;

        final initialLabel = args?['initialLabel'] as Label?;
        final isLabelReadOnly = args?['isLabelReadOnly'] as bool? ?? false;

        final tempController = Get.put(
          NoteController(),
          tag: "notes_label_$labelId",
        );
        return ListScreen<Note>(
          title: initialLabel?.name ?? 'Unknown Label',
          pageType: ListScreenType.notes,
          controller: tempController,
          customFetchFunction: () async {
            await tempController.getByLabel(labelId);
          },
          onAddTap: () => Get.to(
            NoteDetailScreen(
              mode: Mode.create,
              initialLabel: initialLabel,
              isLabelReadOnly: isLabelReadOnly,
            ),
          ),
        );
      },
    ),
    GetPage(
      name: tasks,
      page: () => ListScreen<Task>(
        title: 'Tasks',
        pageType: ListScreenType.tasks,
        controller: Get.find<TaskController>(),
        onAddTap: () => Get.toNamed(Routes.createTask),
      ),
    ),
    GetPage(
      name: tasksByLabel,
      page: () {
        final labelId = Get.parameters['labelId']!.toString();
        final args = Get.arguments as Map<String, dynamic>?;

        final initialLabel = args?['initialLabel'] as Label?;
        final isLabelReadOnly = args?['isLabelReadOnly'] as bool? ?? false;

        final tempController = Get.put(
          TaskController(),
          tag: "tasks_label_$labelId",
        );
        return ListScreen<Task>(
          title: initialLabel?.name ?? 'Unknown Label',
          pageType: ListScreenType.tasks,
          controller: tempController,
          customFetchFunction: () async {
            await tempController.getByLabel(labelId);
          },
          onAddTap: () => Get.to(
            TaskDetailScreen(
              mode: Mode.create,
              initialLabel: initialLabel,
              isLabelReadOnly: isLabelReadOnly,
            ),
          ),
        );
      },
    ),
    GetPage(name: addAttachment, page: () => AddAttachmentScreen()),
    GetPage(
      name: createNote,
      page: () => NoteDetailScreen(mode: Mode.create),
    ),
    GetPage(
      name: editNote,
      page: () => NoteDetailScreen(mode: Mode.edit),
    ),
    GetPage(
      name: selectNote,
      page: () => ListScreen(
        title: 'Select notes to proceed',
        pageType: ListScreenType.notes,
        controller: Get.find<NoteController>(),
        initialSelectionMode: SelectionMode.other,
      ),
    ),
    GetPage(
      name: createTask,
      page: () => TaskDetailScreen(mode: Mode.create),
    ),
    GetPage(
      name: editTask,
      page: () => TaskDetailScreen(mode: Mode.edit),
    ),
    GetPage(
      name: selectTask,
      page: () => ListScreen(
        title: 'Select tasks to proceed',
        pageType: ListScreenType.tasks,
        controller: Get.find<TaskController>(),
        initialSelectionMode: SelectionMode.other,
      ),
    ),
    GetPage(
      name: noteLabels,
      page: () => ListScreen<Label>(
        title: 'Labels',
        pageType: ListScreenType.noteLabels,
        controller: Get.find<LabelController>(),
        onAddTap: () => Get.to(
          CreateLabelScreen<Note>(
            forComponentType: ComponentType.note,
            controller: Get.find<NoteController>(),
          ),
        ),
        onItemTap: (label) {
          Get.toNamed(
            Routes.notesByLabelWithId(label.id ?? ''),
            arguments: {"initialLabel": label, "isLabelReadOnly": true},
          );
        },
      ),
    ),
    GetPage(
      name: taskLabels,
      page: () => ListScreen<Label>(
        title: 'Labels',
        pageType: ListScreenType.taskLabels,
        controller: Get.find<LabelController>(),
        onAddTap: () => Get.to(
          CreateLabelScreen<Task>(
            forComponentType: ComponentType.task,
            controller: Get.find<TaskController>(),
          ),
        ),
        onItemTap: (label) {
          Get.toNamed(
            Routes.notesByLabelWithId(label.id ?? ''),
            arguments: {"initialLabel": label, "isLabelReadOnly": true},
          );
        },
      ),
    ),
    GetPage(
      name: classes,
      page: () => ListScreen<Class>(
        title: 'Classes',
        pageType: ListScreenType.classes,
        controller: Get.find<ClassController>(),
        onAddTap: () =>
            Get.to(CreateGroupScreen(pageType: CreateGroupScreenType.cClass)),
      ),
    ),
    GetPage(
      name: teams,
      page: () => ListScreen<Team>(
        title: 'Teams',
        pageType: ListScreenType.teams,
        controller: Get.find<TeamController>(),
        onAddTap: () =>
            Get.to(CreateGroupScreen(pageType: CreateGroupScreenType.tTeam)),
      ),
    ),
    GetPage(
      name: createClass,
      page: () => CreateGroupScreen(pageType: CreateGroupScreenType.cClass),
    ),
    GetPage(
      name: createTeam,
      page: () => CreateGroupScreen(pageType: CreateGroupScreenType.tTeam),
    ),
  ];
}
