import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/group_model.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';
import 'package:note_taking_app/UI/group_details.dart';
import 'package:note_taking_app/UI/note_task.dart';

class ClassTeamScreen extends StatefulWidget {
  final SelectionMode mode;
  final Group groupObject;
  const ClassTeamScreen({
    super.key,
    required this.mode,
    required this.groupObject,
  });

  @override
  State<ClassTeamScreen> createState() => _ClassTeamScreenState();
}

class _ClassTeamScreenState extends State<ClassTeamScreen>
    with SingleTickerProviderStateMixin {
  final RoleController _roleController = Get.find<RoleController>();

  late Controller _groupController;
  late NoteController _noteController;
  late TaskController _taskController;
  // final TextEditingController _searchController = TextEditingController();

  final List<dynamic> _selectedItems = [];

  late SelectionMode _selectionMode;
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _selectionMode = widget.mode;

    final String groupId = widget.groupObject.id!;
    final String tag = 'group_$groupId';

    Get.put(NoteController(), tag: '${tag}_note');
    Get.put(TaskController(), tag: '${tag}_task');

    _noteController = Get.find<NoteController>(tag: '${tag}_note');
    _taskController = Get.find<TaskController>(tag: '${tag}_task');
    _groupController = widget.groupObject.runtimeType == Class
        ? Get.find<ClassController>()
        : Get.find<TeamController>();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _loadListener();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentIndex = _tabController.index;
      _fetchData();
    });
  }

  @override
  void dispose() {
    final String groupId = widget.groupObject.id!;
    final String tag = 'group_$groupId';

    Get.delete<NoteController>(tag: '${tag}_note');
    Get.delete<TaskController>(tag: '${tag}_task');

    _tabController.removeListener(_loadListener);
    _tabController.dispose();
    super.dispose();
  }

  void _loadListener() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    final groupId = widget.groupObject.id;
    final groupType = widget.groupObject.runtimeType.toString().toLowerCase();

    if (groupId != null) {
      if (_currentIndex == 0) {
        await _noteController.getByGroup(groupId, groupType);
        if (_noteController.errorMessage.value.isNotEmpty) {
          CustomDialog.showError("Error", _noteController.errorMessage.value);
        }
      } else {
        await _taskController.getByGroup(groupId, groupType);
        if (_taskController.errorMessage.value.isNotEmpty) {
          CustomDialog.showError("Error", _taskController.errorMessage.value);
        }
      }
    }
  }

  // // Delete the selected items in the database.
  // Future<void> _deleteSelected() async {
  //   if (_selectedItems.isEmpty) {
  //     return;
  //   }
  //   buildConfirmationMessage(
  //     context: context,
  //     title: 'Delete Confirmation',
  //     content: 'Are you sure you want to delete selections.',
  //     buttonText1: 'Delete',
  //     colorForButton1: Colors.red,
  //     buttonText2: 'Cancel',
  //     colorForButton2: Colors.grey,
  //     onTapOption1: () async {
  //       if (_selectedItems.isNotEmpty) {
  //         List<String> noteIds = _selectedItems
  //             .whereType<Note>()
  //             .map((note) => note.id)
  //             .whereType<String>()
  //             .toList();
  //         List<String> taskIds = _selectedItems
  //             .whereType<Task>()
  //             .map((task) => task.id)
  //             .whereType<String>()
  //             .toList();

  //         if (noteIds.isNotEmpty && widget.groupObject.id != null) {
  //           await _noteController.deleteShared(
  //             noteIds,
  //             widget.groupObject.id!,
  //             widget.groupObject.name,
  //           );
  //         }

  //         if (_noteController.errorMessage.value.isNotEmpty) {
  //           CustomDialog.showError("Error", _noteController.errorMessage.value);
  //         }

  //         if (taskIds.isNotEmpty) {
  //           await _taskController.delete(taskIds);
  //         }
  //         if (_taskController.errorMessage.value.isNotEmpty) {
  //           CustomDialog.showError("Error", _taskController.errorMessage.value);
  //         }
  //         setState(() {
  //           _selectedItems.clear();
  //         });
  //         Get.back();
  //       }
  //     },
  //   );
  //   CustomDialog.showSuccess("Success", "Successfully delete notes.");
  // }

  @override
  Widget build(BuildContext context) {
    final group = widget.groupObject;
    final groupId = group.id;
    final groupType = group.runtimeType.toString().toLowerCase();

    return Scaffold(
      appBar: _selectionMode == SelectionMode.none
          ? CustomAppBar(
              titleWidget: Obx(() {
                final latestGroup = _groupController.list
                    .cast<Group>()
                    .firstWhere(
                      (g) => g.id == widget.groupObject.id,
                      orElse: () => widget.groupObject,
                    );
                return Row(
                  children: [
                    Text(
                      latestGroup.name,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(color: Colors.black),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.to(
                          ClassTeamDetailsScreen(groupObject: latestGroup),
                        );
                      },
                      icon: Icon(Icons.info_outline),
                      color: Colors.black,
                    ),
                  ],
                );
              }),
            )
          : CustomAppBar(
              titleWidget: Obx(() {
                final latestGroup = _groupController.list
                    .cast<Group>()
                    .firstWhere(
                      (g) => g.id == widget.groupObject.id,
                      orElse: () => widget.groupObject,
                    );
                return Text(
                  latestGroup.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(color: Colors.black),
                );
              }),
              actions: [
                ...AdditionalOptions.buildDefaultOptions(
                  context: context,
                  controller: _currentIndex == 0
                      ? _noteController
                      : _taskController,
                  notes: _selectedItems.whereType<Note>().toList().isNotEmpty
                      ? _selectedItems.whereType<Note>().toList()
                      : null,
                  tasks: _selectedItems.whereType<Task>().toList().isNotEmpty
                      ? _selectedItems.whereType<Task>().toList()
                      : null,
                  onUpdate: (updatedItems) {
                    final List<Note> updatedNotes = updatedItems
                        .whereType<Note>()
                        .toList();
                    final List<Task> updatedTasks = updatedItems
                        .whereType<Task>()
                        .toList();
                    if (updatedNotes.isNotEmpty) {
                      _noteController.edit(updatedNotes);
                    }
                    if (updatedTasks.isNotEmpty) {
                      _taskController.edit(updatedTasks);
                    }

                    setState(() {
                      _selectedItems.clear();
                      _selectionMode = SelectionMode.none;
                    });
                  },
                  groupId: groupId,
                  groupType: groupType,
                  isForShared: true,
                  hidePin: true,
                  hideArchive: true,
                ),

                if (_selectionMode == SelectionMode.regular)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedItems.clear();
                        _selectionMode = SelectionMode.none;
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red),
                  ),

                if (_selectionMode == SelectionMode.other)
                  IconButton(
                    onPressed: () => _selectedItems.isNotEmpty
                        ? Get.back(result: _selectedItems)
                        : CustomDialog.showError(
                            "Error",
                            "Please select an item(s) to proceed.",
                          ),
                    icon: Icon(Icons.check),
                  ),
              ],
              replaceDefaultActions: true,
            ),
      endDrawer: const HamburgerMenu(),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Notes'),
              Tab(text: 'Tasks'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListScreen<Note>(
                  showAppBar: false,
                  title: '',
                  forGroupId: groupId,
                  forGroupType: groupType,
                  pageType: ListScreenType.sharedNotes,
                  controller: _noteController,
                  initialSelectionMode: _selectionMode,
                  onItemTap: (note) {
                    Get.to(
                      NoteDetailScreen(
                        mode:
                            (_roleController.hasPermission(
                                  PermissionType.editShared,
                                ) &&
                                group.createdBy ==
                                    Get.find<AuthenticationController>()
                                        .user
                                        ?.uid)
                            ? Mode.editShared
                            : Mode.view,
                        description:
                            "For $groupType ${widget.groupObject.name}",
                        note: note,
                        initialLabel: note.labelName != null
                            ? Label(
                                id: UniqueKey().toString(),
                                name: note.labelName!,
                                type: ComponentType.note,
                                count: 0,
                              )
                            : null,
                        groupId: groupId,
                        groupType: groupType,
                      ),
                    );
                  },
                  onAddTap:
                      _roleController.hasPermission(PermissionType.createShared)
                      ? () {
                          Get.to(
                            NoteDetailScreen(
                              mode: Mode.createShared,
                              groupId: groupId,
                              groupType: groupType,
                              description:
                                  "For $groupType ${widget.groupObject.name}",
                            ),
                          );
                        }
                      : null,
                  onSelectionModeChanged: (mode) {
                    setState(() {
                      _selectionMode = mode;
                    });
                  },
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedItems.removeWhere((item) => item is Note);
                      _selectedItems.addAll(selected.whereType<Note>());
                    });
                  },
                ),
                ListScreen<Task>(
                  showAppBar: false,
                  title: '',
                  pageType: ListScreenType.sharedTasks,
                  forGroupId: groupId,
                  forGroupType: groupType,
                  controller: _taskController,
                  initialSelectionMode: _selectionMode,
                  onItemTap: (task) {
                    Get.to(
                      TaskDetailScreen(
                        mode:
                            (_roleController.hasPermission(
                                  PermissionType.editShared,
                                ) &&
                                group.createdBy ==
                                    Get.find<AuthenticationController>()
                                        .user
                                        ?.uid)
                            ? Mode.editShared
                            : Mode.view,
                        description:
                            "For $groupType ${widget.groupObject.name}",
                        task: task,
                        initialLabel: task.labelName != null
                            ? Label(
                                id: UniqueKey().toString(),
                                name: task.labelName!,
                                type: ComponentType.task,
                                count: 0,
                              )
                            : null,
                        groupId: groupId,
                        groupType: groupType,
                      ),
                    );
                  },
                  onAddTap:
                      _roleController.hasPermission(PermissionType.createShared)
                      ? () {
                          Get.to(
                            TaskDetailScreen(
                              mode: Mode.createShared,
                              groupId: groupId,
                              groupType: groupType,
                              description:
                                  "For $groupType ${widget.groupObject.name}",
                            ),
                          );
                        }
                      : null,
                  onSelectionModeChanged: (mode) {
                    setState(() {
                      _selectionMode = mode;
                    });
                  },
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedItems.removeWhere((item) => item is Task);
                      _selectedItems.addAll(selected.whereType<Task>());
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
