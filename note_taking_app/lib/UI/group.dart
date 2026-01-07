// ==================================================
// Program Name   : group.dart
// Purpose        : UI for listing and interacting with groups/classes
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================

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
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';
import 'package:note_taking_app/UI/group_details.dart';
import 'package:note_taking_app/UI/list_screen.dart';

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

  final List<Note> _selectedNotes = [];
  final List<Task> _selectedTasks = [];

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
  }

  @override
  void dispose() {
    final String groupId = widget.groupObject.id!;
    final String tag = 'group_$groupId';

    Get.delete<NoteController>(tag: '${tag}_note');
    Get.delete<TaskController>(tag: '${tag}_task');

    _tabController.dispose();
    super.dispose();
  }

  void _loadListener() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

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
                    Text(latestGroup.name),
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
                  notes: _selectedNotes,
                  tasks: _selectedTasks,
                  groupId: groupId,
                  groupType: groupType,
                  isForShared: true,
                  hidePin: true,
                  hideArchive: true,
                  hideDelete: !_roleController.hasPermission(
                    PermissionType.deleteShared,
                  ),
                  onActionComplete: () {
                    setState(() {
                      _selectedNotes.clear();
                      _selectedTasks.clear();
                      _selectionMode = SelectionMode.none;
                    });
                  },
                ),

                if (_selectionMode == SelectionMode.regular)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedNotes.clear();
                        _selectedTasks.clear();
                        _selectionMode = SelectionMode.none;
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red),
                  ),

                if (_selectionMode == SelectionMode.other)
                  IconButton(
                    onPressed: () {
                      final selectedItems = [
                        ..._selectedNotes,
                        ..._selectedTasks,
                      ];
                      return selectedItems.isNotEmpty
                          ? Get.back(result: selectedItems)
                          : CustomDialog.showError(
                              "Error",
                              "Please select an item(s) to proceed.",
                            );
                    },
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
                  keepAlive: true,
                  showAppBar: false,
                  title: '',
                  forGroupId: groupId,
                  forGroupType: groupType,
                  pageType: ListScreenType.sharedNotes,
                  controller: _noteController,
                  initialSelectionMode: _selectionMode,
                  preSelectedItems: _selectedNotes.toList(),
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
                                        .value
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
                        hideAttachmentButton: true,
                      ),
                    );
                  },
                  customAddButton:
                      _roleController.hasPermission(PermissionType.createShared)
                      ? ShareButtonPopUp(
                          group: group,
                          type: ComponentType.note,
                          onRefresh: () {
                            setState(() {});
                          },
                          noteController: _noteController,
                          taskController: _taskController,
                        )
                      : null,
                  onSelectionModeChanged: (mode, selectedNote) {
                    setState(() {
                      _selectionMode = mode;
                      _selectedNotes.add(selectedNote);
                    });
                  },
                  onSelectionChanged: (selected) {
                    _selectedNotes.clear();
                    _selectedNotes.addAll(selected.whereType<Note>());
                  },
                  customFetchFunction: groupId != null
                      ? () => _noteController.getByGroup(groupId, groupType)
                      : null,
                ),
                ListScreen<Task>(
                  keepAlive: true,
                  showAppBar: false,
                  title: '',
                  pageType: ListScreenType.sharedTasks,
                  forGroupId: groupId,
                  forGroupType: groupType,
                  controller: _taskController,
                  initialSelectionMode: _selectionMode,
                  preSelectedItems: _selectedTasks.toList(),
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
                                        .value
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
                  customAddButton:
                      _roleController.hasPermission(PermissionType.createShared)
                      ? ShareButtonPopUp(
                          group: group,
                          type: ComponentType.task,
                          onRefresh: () {
                            setState(() {});
                          },
                          noteController: _noteController,
                          taskController: _taskController,
                        )
                      : null,
                  onSelectionModeChanged: (mode, selectedTask) {
                    setState(() {
                      _selectionMode = mode;
                      _selectedTasks.add(selectedTask);
                    });
                  },
                  onSelectionChanged: (selected) {
                    _selectedTasks.clear();
                    _selectedTasks.addAll(selected.whereType<Task>());
                  },
                  customFetchFunction: groupId != null
                      ? () => _taskController.getByGroup(groupId, groupType)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShareButtonPopUp extends StatefulWidget {
  final Group group;
  final ComponentType type;
  final VoidCallback? onRefresh;
  final NoteController noteController;
  final TaskController taskController;

  const ShareButtonPopUp({
    super.key,
    required this.group,
    required this.type,
    this.onRefresh,
    required this.noteController,
    required this.taskController
  });

  @override
  State<ShareButtonPopUp> createState() => _ShareButtonPopUpState();
}

class _ShareButtonPopUpState extends State<ShareButtonPopUp> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        final groupType = widget.group.runtimeType
            .toString()
            .toLowerCase()
            .trim();
        final groupId = widget.group.id!;

        if (value == 'create') {
          if (widget.type == ComponentType.note) {
            // You'll need to pass 'type' or logic here
            await Get.to(
              NoteDetailScreen(
                mode: Mode.createShared,
                hideAttachmentButton: true,
                groupId: groupId,
                groupType: groupType,
              ),
            );
            await widget.noteController.getByGroup(groupId, groupType);
          } else if (widget.type == ComponentType.task) {
            await Get.to(
              TaskDetailScreen(
                mode: Mode.createShared,
                groupId: groupId,
                groupType: groupType,
              ),
            );
            await widget.taskController.getByGroup(groupId, groupType);
          }
          widget.onRefresh?.call();
        } else if (value == 'select') {
          bool success = false;
          if (widget.type == ComponentType.note) {
            final selectedNotes =
                await Get.toNamed(Routes.selectNote) as List<Note>?;
            if (selectedNotes != null && selectedNotes.isNotEmpty) {
              await widget.noteController.shareMultiple(
                selectedNotes,
                widget.group.id!,
                groupType,
              );

              if (widget.noteController.errorMessage.value.isNotEmpty) {
                CustomDialog.showError(
                  "Error",
                  widget.noteController.errorMessage.value,
                );
              } else {
                CustomDialog.showSuccess(
                  "Success",
                  "Successfully share notes to group.",
                );
                success = true;
                await widget.noteController.getByGroup(groupId, groupType);
              }
            } else {
              CustomDialog.showInfo("Info", "No notes selected to share.");
            }
          } else if (widget.type == ComponentType.task) {
            final selectedTasks =
                await Get.toNamed(Routes.selectTask) as List<Task>?;
            if (selectedTasks != null && selectedTasks.isNotEmpty) {
              await widget.taskController.shareMultiple(
                selectedTasks,
                widget.group.id!,
                groupType,
              );

              if (widget.taskController.errorMessage.value.isNotEmpty) {
                CustomDialog.showError(
                  "Error",
                  widget.taskController.errorMessage.value,
                );
              } else {
                CustomDialog.showSuccess(
                  "Success",
                  "Successfully share tasks to group.",
                );
                success = true;
                await widget.taskController.getByGroup(groupId, groupType);
              }
            } else {
              CustomDialog.showInfo("Info", "No tasks selected to share.");
            }
          }

          if (success) {
            widget.onRefresh?.call();
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'create',
          child: Center(child: Text('Create New')),
        ),
        const PopupMenuItem<String>(
          value: 'select',
          child: Center(child: Text('Select From Existing')),
        ),
      ],
    );
  }
}
