import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/count_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_theme.dart';
import 'package:note_taking_app/UI/SharedComponents/confirmation_message.dart';
import 'package:note_taking_app/UI/SharedComponents/share_feature.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/note_task.dart';
import 'package:note_taking_app/UI/register.dart';
import 'package:note_taking_app/main.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final String? titleText;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget>? actions;
  final bool replaceDefaultActions;

  const CustomAppBar({
    super.key,
    this.leading,
    this.titleText,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.replaceDefaultActions = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget appBarTitle = titleWidget != null
        ? titleWidget!
        : Text(
            titleText ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: Colors.black),
          );
    return AppBar(
      leading: leading,
      title: subtitle == null
          ? appBarTitle
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appBarTitle,
                const SizedBox(height: 2),
                Text(
                  subtitle ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: Colors.grey.shade800),
                ),
              ],
            ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ),
      actions: replaceDefaultActions
          ? (actions ?? [])
          : [
              ...?actions,
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Icon(Icons.menu, color: Colors.black)),
                  ),
                ),
              ),
            ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class HamburgerMenu extends StatefulWidget {
  const HamburgerMenu({super.key});

  @override
  State<HamburgerMenu> createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu> {
  final countController = Get.find<CountController>();
  final noteController = Get.find<NoteController>();
  final taskController = Get.find<TaskController>();
  final labelController = Get.find<LabelController>();
  final roleController = Get.find<RoleController>();
  final authController = Get.find<AuthenticationController>();
  late final NoteController archivedNotesController;
  late final TaskController archivedTasksController;

  // late final int notificationCount;
  // late final List<Map<String, dynamic>> noteLabels;
  // late final int noteTotalCount;
  // late final List<Map<String, dynamic>> taskLabels;
  // late final int taskTotalCount;

  @override
  void initState() {
    super.initState();

    countController.getAllNotificationsCount();
    labelController.getNoteLabels();
    countController.getAllNotesCount();
    labelController.getTaskLabels();
    countController.getAllTasksCount();
    countController.getAllGroupsCount();
    archivedNotesController = Get.put(NoteController(), tag: 'notes_archived');
    archivedTasksController = Get.put(TaskController(), tag: 'tasks_archived');

    archivedNotesController.getArchived();
    archivedTasksController.getArchived();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   noteController.getArchived();
    //   taskController.getArchived();
    // });

    // _loadNotificationCount();
    // _loadNoteData();
    // _loadTaskData();
  }

  // Future<void> _loadNotificationCount() async {
  //   await countController.getAllNotificationsCount();
  //   notificationCount = countController.notificationCount.value;
  // }

  // Future<void> _loadNoteData() async {
  //   await countController.getNoteLabels();
  //   noteLabels = countController.noteLabels;
  //   await countController.getAllNotesCount();
  //   noteTotalCount = countController.notesCount.value;
  // }

  // Future<void> _loadTaskData() async {
  //   await countController.getTaskLabels();
  //   taskLabels = countController.taskLabels;
  //   await countController.getAllNotesCount();
  //   noteTotalCount = countController.notesCount.value;
  // }

  @override
  Widget build(BuildContext context) {
    final isGuest = authController.user.value?.userType == UserType.guest;

    return Drawer(
      width: MediaQuery.of(context).size.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Colors.white,
          child: Obx(
            () => ListView(
              padding: EdgeInsets.all(10),
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: Get.back,
                ),
                const SizedBox(height: 10),
                ...NavigationButtons.buildDefaultNav(
                  context: context,
                  authController: authController,
                  notificationCount: countController.notificationCount.value,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 5),
                  child: Text(
                    'Notes:',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...NavigationButtons.buildNoteNav(
                  context: context,
                  noteLabels: labelController.noteLabels,
                  totalCount: countController.notesCount.value,
                  archivedCount: archivedNotesController.filteredList.length,
                  noteController: noteController,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 5),
                  child: Text(
                    'Tasks:',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...NavigationButtons.buildTaskNav(
                  context: context,
                  taskLabels: labelController.taskLabels,
                  totalCount: countController.tasksCount.value,
                  archivedCount: archivedTasksController.filteredList.length,
                  taskController: taskController,
                ),
                if (!isGuest) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 5),
                    child: Text(
                      roleController.hasPermission(PermissionType.viewClass)
                          ? "Classes"
                          : "Teams",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...NavigationButtons.buildGroupNav(
                    context: context,
                    totalCount: countController.groupCount.value,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationButtons {
  static void navigate({
    String? routeName,
    Widget? page,
    Map<String, dynamic>? arguments,
  }) {
    Get.back();
    if (routeName != null && Get.currentRoute != routeName) {
      Get.offNamed(routeName, arguments: arguments, preventDuplicates: false);
    } else if (page != null) {
      Get.off(() => page, preventDuplicates: false);
    }
  }

  static Widget drawerTile({
    required BuildContext context,
    required IconData leadingIcon,
    required String title,
    String? trailingText,
    Color? tileColor,
    VoidCallback? onTap,
  }) {
    final backgroundColor = tileColor ?? Colors.white;
    final textColor = AppTheme.getOptimalTextColor(backgroundColor);

    return ListTile(
      tileColor: tileColor,
      leading: Icon(leadingIcon, color: textColor),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(color: textColor),
      ),
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: textColor),
            ),
          Icon(Icons.arrow_forward_ios),
        ],
      ),
      onTap: onTap,
    );
  }

  static List<Widget> buildDefaultNav({
    required BuildContext context,
    required AuthenticationController authController,
    required int notificationCount,
  }) {
    final user = authController.user.value;
    // final email = user?.email;
    final profileUrl = user?.profileUrl;
    final userName = user?.name;
    final isGuest = user?.userType == UserType.guest;

    return [
      Column(
        children: [
          GestureDetector(
            onTap: () => Get.toNamed(
              Routes.profile,
              // arguments: {'name': userName, 'email': email, 'profileUrl': profileUrl},
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundImage: profileUrl != null
                  ? NetworkImage(profileUrl)
                  : AssetImage('assets/profile_pic.jpg'),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            userName ?? 'Unnamed User',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: Colors.black),
          ),
          if (isGuest) ...[
            const SizedBox(height: 5),
            Text(
              '(Logged in as Guest)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: Colors.black),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.black),
              ),
              onPressed: () =>
                  Get.to(RegistrationScreen(isForExistingAccount: true)),
              child: Text(
                "Upgrade to Permanent Account",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      drawerTile(
        context: context,
        leadingIcon: Icons.home,
        title: 'Home',
        onTap: () => navigate(routeName: Routes.home),
      ),
      drawerTile(
        context: context,
        leadingIcon: Icons.calendar_month,
        title: 'Calendar',
        onTap: () => navigate(routeName: Routes.calendar),
      ),
      drawerTile(
        context: context,
        leadingIcon: Icons.notifications,
        title: 'Notifications',
        trailingText: notificationCount.toString(),
        onTap: () => navigate(routeName: Routes.notifications),
      ),
      drawerTile(
        context: context,
        leadingIcon: Icons.settings,
        title: 'Settings',
        onTap: () => navigate(routeName: Routes.settings),
      ),
    ];
  }

  static List<Widget> buildNoteNav({
    required BuildContext context,
    required List<Label> noteLabels,
    required int totalCount,
    required int archivedCount,
    required NoteController noteController,
  }) {
    return [
      ...noteLabels
          .take(3)
          .map(
            (label) => drawerTile(
              context: context,
              leadingIcon: Icons.label_outline,
              title: label.name,
              trailingText: label.count.toString(),
              onTap: () {
                navigate(
                  routeName: Routes.notesByLabelWithId(label.id ?? ''),
                  arguments: {"initialLabel": label, "isLabelReadOnly": true},
                );
              },
            ),
          ),
      drawerTile(
        context: context,
        leadingIcon: Icons.archive,
        title: 'Archived',
        trailingText: archivedCount.toString(),
        onTap: () {
          final NoteController tempController;
          if (Get.isRegistered<NoteController>(tag: "notes_archived")) {
            tempController = Get.put(NoteController(), tag: "notes_archived");
          } else {
            tempController = Get.find<NoteController>(tag: "notes_archived");
          }

          navigate(
            page: ListScreen<Note>(
              title: "Archived Notes",
              pageType: ListScreenType.archivedNotes,
              controller: tempController,
              onAddTap: () => Get.toNamed(Routes.createNote),
            ),
          );
        },
      ),
      drawerTile(
        context: context,
        leadingIcon: Icons.label,
        title: 'View All Notes',
        trailingText: totalCount.toString(),
        onTap: () => Get.offAllNamed(Routes.notes),
      ),
      TextButton(
        onPressed: () => navigate(routeName: Routes.noteLabels),
        child: Text(
          'Show More >',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  static List<Widget> buildTaskNav({
    required BuildContext context,
    required List<Label> taskLabels,
    required int totalCount,
    required int archivedCount,
    required TaskController taskController,
  }) {
    return [
      ...taskLabels
          .take(3)
          .map(
            (label) => drawerTile(
              context: context,
              leadingIcon: Icons.label_outline,
              title: label.name,
              trailingText: label.count.toString(),
              onTap: () {
                navigate(
                  routeName: Routes.tasksByLabelWithId(label.id ?? ''),
                  arguments: {"initialLabel": label, "isLabelReadOnly": true},
                );
              },
            ),
          ),
      drawerTile(
        context: context,
        leadingIcon: Icons.archive,
        title: 'Archived',
        trailingText: archivedCount.toString(),
        onTap: () {
          final TaskController tempController;
          if (Get.isRegistered<TaskController>(tag: "tasks_archived")) {
            tempController = Get.put(TaskController(), tag: "tasks_archived");
          } else {
            tempController = Get.find<TaskController>(tag: "tasks_archived");
          }
          navigate(
            page: ListScreen<Task>(
              title: "Archived Tasks",
              pageType: ListScreenType.archivedTasks,
              controller: tempController,
              onAddTap: () => Get.toNamed(Routes.createTask),
            ),
          );
        },
      ),
      drawerTile(
        context: context,
        leadingIcon: Icons.label,
        title: 'View All Tasks',
        trailingText: totalCount.toString(),
        onTap: () => navigate(routeName: Routes.tasks),
      ),
      TextButton(
        onPressed: () => navigate(routeName: Routes.taskLabels),
        child: Text(
          'Show More >',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  static List<Widget> buildGroupNav({
    required BuildContext context,
    required int totalCount,
  }) {
    final roleController = Get.find<RoleController>();
    return [
      drawerTile(
        context: context,
        leadingIcon: Icons.label,
        title: 'View All',
        trailingText: totalCount.toString(),
        onTap: () => navigate(
          routeName: roleController.hasPermission(PermissionType.viewClass)
              ? Routes.classes
              : Routes.teams,
        ),
      ),
    ];
  }
}

class AdditionalOptions {
  static List<Widget> buildDefaultOptions({
    required BuildContext context,
    required Controller controller,

    TextEditingController? titleController,
    QuillController? contentController,
    TextEditingController? descriptionController,
    List<Note>? notes,
    List<Task>? tasks,
    List<Label>? labels,
    String? groupId,
    String? groupType,
    required bool isForShared,
    bool hidePin = false,
    bool hideArchive = false,
    bool hideDelete = false,
    bool hideShare = false,
    void Function(List updatedItems)? onUpdate,
  }) {
    if (onUpdate == null ||
        (notes == null && tasks == null && labels == null)) {
      return [];
    }

    // Only Notes and Tasks can do all actions.
    // Labels can only access delete.
    return [
      PopupMenuButton(
        icon: Icon(Icons.more_vert),
        onSelected: (value) async {
          switch (value) {
            case 'pin':
              if (notes != null) {
                onUpdate(
                  notes.map((item) => item.copyWith(isPinned: true)).toList(),
                );
              } else if (tasks != null) {
                onUpdate(
                  tasks.map((item) => item.copyWith(isPinned: true)).toList(),
                );
              }
              break;
            case 'unpin':
              if (notes != null) {
                onUpdate(
                  notes.map((item) => item.copyWith(isPinned: false)).toList(),
                );
              } else if (tasks != null) {
                onUpdate(
                  tasks.map((item) => item.copyWith(isPinned: false)).toList(),
                );
              }
              break;
            case 'archive':
              if (notes != null) {
                onUpdate(
                  notes.map((item) => item.copyWith(isArchived: true)).toList(),
                );
              } else if (tasks != null) {
                onUpdate(
                  tasks.map((item) => item.copyWith(isArchived: true)).toList(),
                );
              }
              break;
            case 'unarchive':
              if (notes != null) {
                onUpdate(
                  notes
                      .map((item) => item.copyWith(isArchived: false))
                      .toList(),
                );
              } else if (tasks != null) {
                onUpdate(
                  tasks
                      .map((item) => item.copyWith(isArchived: false))
                      .toList(),
                );
              }
              break;
            case 'delete':
              buildConfirmationMessage(
                context: context,
                title: 'Delete Confirmation',
                content: 'Are you sure you want to delete selections.',
                buttonText1: 'Delete',
                colorForButton1: Colors.red,
                buttonText2: 'Cancel',
                colorForButton2: Colors.grey,
                onTapOption1: () async {
                  final noteIds = notes
                      ?.map((item) => item.id)
                      .whereType<String>()
                      .toList();
                  final taskIds = tasks
                      ?.map((item) => item.id)
                      .whereType<String>()
                      .toList();
                  final labelIds = labels
                      ?.map((item) => item.id)
                      .whereType<String>()
                      .toList();
                  print("Task id: ${tasks?.first.id}");
                  print("isForShared: $isForShared");
                  print("noteIds: $noteIds");
                  print("taskIds: $taskIds");
                  print("labelIds: $labelIds");
                  print("controller type: ${controller.runtimeType}");
                  print("groupId: $groupId, groupType: $groupType");

                  if (isForShared &&
                      noteIds != null &&
                      controller is NoteController) {
                    if (groupId != null && groupType != null) {
                      print("Delete Shared Notes.");
                      await controller.deleteShared(
                        noteIds,
                        groupId,
                        groupType,
                      );
                    }
                  }
                  if (isForShared &&
                      taskIds != null &&
                      controller is TaskController) {
                    if (groupId != null && groupType != null) {
                      print("Delete Shared Tasks.");
                      await controller.deleteShared(
                        taskIds,
                        groupId,
                        groupType,
                      );
                    }
                  }
                  if (!isForShared) {
                    if (noteIds != null) {
                      print("Normal Delete Notes.");
                      await controller.delete(noteIds);
                    }
                    if (taskIds != null) {
                      print("Normal Delete Tasks.");
                      await controller.delete(taskIds);
                      for (String taskId in taskIds) {
                        await flutterLocalNotificationsPlugin.cancel(
                          taskId.hashCode,
                        );
                      }
                    }
                    if (labelIds != null) {
                      print("Normal Delete Labels.");
                      await controller.delete(labelIds);
                    }
                  }

                  if (controller.errorMessage.value.isNotEmpty) {
                    CustomDialog.showError(
                      "Error",
                      controller.errorMessage.value,
                    );
                    return;
                  }
                  CustomDialog.showSuccess(
                    "Success",
                    "Successfully delete selections.",
                  );
                  Get.back();
                },
              );
              break;
            case 'share':
              final content = contentController?.document.toPlainText().trim();
              if (notes != null) {
                onUpdate(
                  notes
                      .map((item) => item.copyWith(searchableContent: content))
                      .toList(),
                );
              } else if (tasks != null) {
                if (descriptionController != null) {
                  onUpdate(
                    tasks
                        .map(
                          (item) => item.copyWith(
                            description: descriptionController.text,
                          ),
                        )
                        .toList(),
                  );
                }
              }

              buildConfirmationMessage(
                context: context,
                title: 'Share Confirmation',
                buttonText1: 'Share within app',
                colorForButton1: Colors.grey,
                buttonText2: 'Share outside app',
                colorForButton2: Colors.grey,
                onTapOption1: () async {
                  if (notes == null && tasks == null) {
                    CustomDialog.showError("Error", "Nothing to share.");
                  }
                  ShareFeature.shareInApp(context, notes: notes, tasks: tasks);
                },
                onTapOption2: () async {
                  final selectedList = [...?notes, ...?tasks];
                  if (selectedList.length != 1) {
                    CustomDialog.showError(
                      "Error",
                      "Please select only one item to share.",
                    );
                    return;
                  }
                  final item = selectedList.first;
                  ShareFeature.shareOutsideApp(
                    context: context,
                    shareTitle: "Share my ${item is Note ? "note" : "task"}",
                    titleController:
                        titleController ??
                        TextEditingController(text: item.name),
                    quillController: item is Note ? contentController : null,
                  );
                },
              );
              break;
          }
        },
        itemBuilder: (context) {
          bool isPinned = true;
          bool isArchived = true;
          if (notes?.length == 1) {
            final item = notes!.first;
            isPinned = item.isPinned;
            if (!isForShared && item.isArchived != null) {
              isArchived = item.isArchived!;
            }
          } else if (tasks?.length == 1) {
            final item = tasks!.first;
            isPinned = item.isPinned;
            if (!isForShared && item.isArchived != null) {
              isArchived = item.isArchived!;
            }
          }

          return [
            if (!hidePin)
              PopupMenuItem(
                value: !isPinned ? 'pin' : 'unpin',
                child: ListTile(
                  leading: Icon(Icons.push_pin),
                  title: Text(!isPinned ? 'Pin' : 'Unpin'),
                ),
              ),

            // Only allow archive for notes and tasks (excluding shared notes and shared tasks).
            if (!hideArchive)
              PopupMenuItem(
                value: !isArchived ? 'archive' : 'unarchive',
                child: ListTile(
                  leading: Icon(Icons.archive),
                  title: Text(!isArchived ? 'Archive' : 'Unarchive'),
                ),
              ),

            if (!hideDelete)
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
              ),
            if (!hideShare)
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                ),
              ),
          ];
        },
      ),
    ];
  }
}
