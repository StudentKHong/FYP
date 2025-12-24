import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/group_model.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Models/team_model.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/Navigation/ui_scaffold_state.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/SharedComponents/filter_popup.dart';
import 'package:note_taking_app/UI/SharedComponents/loading_state.dart';
import 'package:note_taking_app/UI/SharedComponents/search.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/sort_popup.dart';
import 'package:note_taking_app/UI/group.dart' as class_page;
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';

enum SelectionMode { none, regular, other }

enum ListScreenType {
  notes,
  sharedNotes,
  tasks,
  sharedTasks,
  archivedNotes,
  archivedTasks,
  classes,
  teams,
  noteLabels,
  taskLabels,
  notesByLabel,
  tasksByLabel,
}

class ListScreen<T extends BaseEntity> extends StatefulWidget {
  final bool showAppBar;
  final String title;
  final String? description;
  final String? forGroupId;
  final String? forGroupType;
  final ListScreenType pageType;
  final Controller<T> controller;
  final void Function()? customFetchFunction;
  final SelectionMode initialSelectionMode;
  final List<T>? preSelectedItems;
  final VoidCallback? onAddTap;
  final void Function(T item)? onItemTap;
  final Function(SelectionMode mode)? onSelectionModeChanged;
  final Function(List<dynamic> selected)? onSelectionChanged;
  final bool keepAlive;

  const ListScreen({
    super.key,
    this.showAppBar = true,
    required this.title,
    this.description,
    this.forGroupId,
    this.forGroupType,
    required this.pageType,
    required this.controller,
    this.customFetchFunction,
    this.initialSelectionMode = SelectionMode.none,
    this.preSelectedItems,
    this.onAddTap,
    this.onItemTap,
    this.onSelectionModeChanged,
    this.onSelectionChanged,
    this.keepAlive = false,
  });

  @override
  State<ListScreen<T>> createState() => _ListScreenState<T>();
}

class _ListScreenState<T extends BaseEntity> extends State<ListScreen<T>>
    with AutomaticKeepAliveClientMixin {
  final AuthenticationController authController =
      Get.find<AuthenticationController>();
  final RoleController roleController = Get.find<RoleController>();
  final TextEditingController _searchController = TextEditingController();
  late final Controller<T> _controller;

  late List<T> _selectedItems;
  late SelectionMode _selectionMode;
  int filteredListUpdateCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;
    _selectedItems = widget.preSelectedItems ?? [];
    _selectionMode = widget.initialSelectionMode;

    _fetchData();
  }

  @override
  void didUpdateWidget(covariant ListScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if (!listEquals(widget.preSelectedItems, oldWidget.preSelectedItems)) {
    //   setState(() {
    //     _selectedItems = List.from(widget.preSelectedItems ?? []);
    //   });
    // }
    if (widget.initialSelectionMode != oldWidget.initialSelectionMode) {
      setState(() {
        _selectionMode = widget.initialSelectionMode;
        if (_selectionMode == SelectionMode.none) {
          _selectedItems.clear();
        }
      });
    }
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;
    String? actionText;
    VoidCallback? action;

    switch (widget.pageType) {
      case ListScreenType.notes:
        icon = Icons.note_add_outlined;
        message = 'No notes yet.';
        actionText = 'Create your first note.';
        action = widget.onAddTap;
        break;
      case ListScreenType.tasks:
        icon = Icons.task_outlined;
        message = 'No tasks yet.';
        actionText = 'Create your first task.';
        action = widget.onAddTap;
        break;
      case ListScreenType.classes:
        icon = Icons.class_outlined;
        message = 'No classes yet.';
        actionText =
            'Join ${roleController.hasPermission(PermissionType.createClass) ? 'Or Create' : ''} a class.';
        action = widget.onAddTap;
        break;
      case ListScreenType.teams:
        icon = Icons.group_add_outlined;
        message = 'No classes yet.';
        actionText =
            'Join ${roleController.hasPermission(PermissionType.createClass) ? 'or create' : ''} a class.';
        action = widget.onAddTap;
        break;
      case ListScreenType.noteLabels || ListScreenType.taskLabels:
        icon = Icons.group_add_outlined;
        message = 'No labels yet.';
        actionText = 'Create a label.';
        action = widget.onAddTap;
        break;
      default:
        icon = Icons.question_mark_outlined;
        message = 'Nothing here yet.';
    }

    return EmptyState(
      icon: icon,
      message: message,
      actionText: actionText,
      action: action,
    );
  }

  Future<void> _fetchData() async {
    // authController.checkAuthentication();

    if (widget.customFetchFunction != null) {
      widget.customFetchFunction!();
      return;
    }
    // if (_controller is LabelController) {
    //   if (widget.pageType == ListScreenType.noteLabels) {
    //     (_controller as LabelController).getNoteLabels();
    //   } else if (widget.pageType == ListScreenType.taskLabels) {
    //     (_controller as LabelController).getTaskLabels();
    //   }
    // } else if (widget.pageType == ListScreenType.sharedNotes ||
    //     widget.pageType == ListScreenType.sharedTasks) {
    //   return;
    // } else {
    if (widget.pageType == ListScreenType.archivedNotes &&
        _controller is NoteController) {
      (_controller as NoteController).getArchived();
    } else if (widget.pageType == ListScreenType.archivedTasks &&
        _controller is TaskController) {
      (_controller as TaskController).getArchived();
    }
    // else {
    //   print("Running getAll() function.");
    //   _controller.getAll();
    // }
    // }
  }

  VoidCallback? onTapCard(T item) {
    if (widget.onItemTap != null) {
      return () => widget.onItemTap!.call(item);
    }
    if (item is Note) {
      return () => Get.to(() => NoteDetailScreen(mode: Mode.edit, note: item));
    } else if (item is Task) {
      return () => Get.to(() => TaskDetailScreen(mode: Mode.edit, task: item));
    } else if (item is Group) {
      return () => Get.to(
        () => class_page.ClassTeamScreen(
          mode: SelectionMode.none,
          groupObject: item,
        ),
      );
    } else if (item is Label) {
      if (widget.pageType == ListScreenType.noteLabels) {
        return () {
          final controller = Get.find<NoteController>();
          Get.to(
            () => ListScreen<Note>(
              title: item.name,
              pageType: ListScreenType.notes,
              controller: controller,
              customFetchFunction: () async {
                await controller.getByLabel(item.id!);
              },
              onAddTap: () => Get.to(
                NoteDetailScreen(
                  mode: Mode.create,
                  initialLabel: item,
                  isLabelReadOnly: true,
                ),
              ),
              onItemTap: (value) =>
                  Get.to(() => NoteDetailScreen(mode: Mode.edit, note: value)),
            ),
          );
        };
      } else if (widget.pageType == ListScreenType.taskLabels) {
        return () {
          final controller = Get.find<TaskController>();
          Get.to(
            () => ListScreen<Task>(
              title: item.name,
              pageType: ListScreenType.tasks,
              controller: controller,
              customFetchFunction: () async {
                await controller.getByLabel(item.id!);
              },
              onAddTap: () => Get.to(
                TaskDetailScreen(
                  mode: Mode.create,
                  initialLabel: item,
                  isLabelReadOnly: true,
                ),
              ),
              onItemTap: (value) =>
                  Get.to(() => TaskDetailScreen(mode: Mode.edit, task: value)),
            ),
          );
        };
      }
    }
    return null;
  }

  // Get other details based on item type.
  List<String> _getOtherDetails(T item) {
    final List<String> otherDetails = [];

    if (item is FilterableEntity) {
      String? labelName;
      if (item is Note) {
        labelName = item.label?.name ?? item.labelName;
      } else if (item is Task) {
        labelName = item.label?.name ?? item.labelName;
      }
      if (labelName != null) {
        otherDetails.add(labelName);
      }
    }

    if (item is Class) {
      final totalStudents = item.totalStudents;
      final totalTeachers = item.totalTeachers;
      otherDetails.add("Total Students: ${totalStudents.toString()}");
      otherDetails.add("Total Teachers: ${totalTeachers.toString()}");
    }

    if (item is Team) {
      final totalMembers = item.total;
      otherDetails.add("Total Members: ${totalMembers.toString()}");
    }
    return otherDetails;
  }

  void sortList() {
    _controller.filteredList.sort((a, b) {
      final aPinned = (a as dynamic).isPinned ?? false;
      final bPinned = (b as dynamic).isPinned ?? false;

      // Sort pin first.
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      // Then, sort date created.
      final aTime = (a as dynamic).createdAt ?? DateTime.now();
      final bTime = (b as dynamic).createdAt ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
  }

  List<IconButton> _buildIconButtons(T item) {
    final List<IconButton> iconButtons = [];
    if (item is Note || item is Task) {
      iconButtons.addAll([
        if (widget.pageType != ListScreenType.archivedNotes &&
            widget.pageType != ListScreenType.archivedTasks)
          IconButton(
            onPressed: () {
              final isPinned = (item as dynamic).isPinned;
              final isArchived = (item as dynamic).isArchived ?? false;
              final newItem = (item as dynamic).copyWith(
                isPinned: !isPinned,
                isArchived: !isPinned ? false : isArchived,
              );

              final index = _controller.filteredList.indexOf(item);
              if (index != -1) {
                _controller.filteredList[index] = newItem;
                // _controller.filteredList.removeAt(index);
                // _controller.filteredList.insert(0, newItem);
                sortList();
              }
              if (item is Note) {
                (_controller as NoteController).togglePinStatus(item);
              } else if (item is Task) {
                (_controller as TaskController).togglePinStatus(item);
              }
            },
            icon: Icon(
              (item as dynamic).isPinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              color: Colors.black,
            ),
          ),
        if (widget.pageType != ListScreenType.sharedNotes &&
            widget.pageType != ListScreenType.sharedTasks)
          IconButton(
            onPressed: () async {
              // final isPinned = (item as dynamic).isPinned;
              // final isArchived = (item as dynamic).isArchived ?? false;
              // final newItem = (item as dynamic).copyWith(isArchived: !isArchived, isPinned: !isArchived ? false : isPinned);

              final index = _controller.filteredList.indexOf(item);
              if (index != -1) {
                _controller.filteredList.removeAt(index);
                // sortList();
              }

              if (item is Note) {
                await (_controller as NoteController).toggleArchiveStatus(item);
              } else if (item is Task) {
                await (_controller as TaskController).toggleArchiveStatus(item);
              }
            },
            icon: Icon(
              (item as dynamic).isArchived ?? false
                  ? Icons.archive
                  : Icons.archive_outlined,
              color: Colors.black,
            ),
          ),
      ]);
    }
    return iconButtons;
  }

  Widget _buildAddButton() {
    if (_selectionMode == SelectionMode.none) {
      if (widget.pageType == ListScreenType.archivedNotes ||
          widget.pageType == ListScreenType.archivedTasks) {
        return const SizedBox.shrink();
      }
      return widget.pageType == ListScreenType.classes ||
              widget.pageType == ListScreenType.teams
          ? AddButtonPopUp(
              forGroupType: widget.pageType == ListScreenType.classes
                  ? "class"
                  : "team",
              joinFunction: (code) async {
                if (widget.pageType == ListScreenType.classes) {
                  final joinedClass = await (_controller as ClassController)
                      .join(code);
                  if (joinedClass == null) {
                    if (_controller.errorMessage.value.isNotEmpty) {
                      CustomDialog.showError(
                        "Error",
                        _controller.errorMessage.value,
                      );
                    }
                    return;
                  }
                  Get.to(
                    class_page.ClassTeamScreen(
                      mode: SelectionMode.none,
                      groupObject: joinedClass as Group,
                    ),
                  );
                } else {
                  final joinedTeam = await (_controller as TeamController).join(
                    code,
                  );
                  if (joinedTeam == null) {
                    if (_controller.errorMessage.value.isNotEmpty) {
                      CustomDialog.showError(
                        "Error",
                        _controller.errorMessage.value,
                      );
                    }
                    return;
                  }
                  Get.to(
                    class_page.ClassTeamScreen(
                      mode: SelectionMode.none,
                      groupObject: joinedTeam as Group,
                    ),
                  );
                }
              },
            )
          : widget.onAddTap != null
          ? IconButton(
              onPressed: widget.onAddTap,
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : const SizedBox.shrink();
    }
    return SizedBox.shrink();
  }

  Widget _buildCard({
    required T item,
    required String dateCreated,
    required List<String> otherDetails,
    required Function()? onTap,
    List<IconButton>? iconButtons,
  }) {
    if ((widget.pageType == ListScreenType.noteLabels ||
            widget.pageType == ListScreenType.taskLabels) &&
        item is Label) {
      return NavigationButtons.drawerTile(
        context: context,
        tileColor: Theme.of(context).cardColor,
        leadingIcon: Icons.label,
        title: item.name,
        onTap: onTap,
        hideTrailing: _selectionMode != SelectionMode.none,
      );
    }
    return CustomExtendedCard(
      key: ValueKey(item.id),
      title: item.name,
      status: item is Task ? item.status : null,
      content: [item.description ?? '', dateCreated],
      otherDetails: otherDetails,
      onTap: onTap,
      iconButtons: _selectionMode == SelectionMode.none ? iconButtons : null,
    );
  }

  // Handle selected items.
  void _selectItem(T? item) {
    setState(() {
      if (item != null) {
        if (_selectedItems.contains(item)) {
          _selectedItems.remove(item);
        } else {
          _selectedItems.add(item);
        }
        widget.onSelectionChanged?.call(List.from(_selectedItems));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.keepAlive) super.build(context);
    return ((widget.pageType == ListScreenType.classes &&
                !roleController.hasPermission(PermissionType.viewClass)) ||
            (widget.pageType == ListScreenType.teams &&
                !roleController.hasPermission(PermissionType.viewCreateTeam)))
        ? Scaffold(
            appBar: CustomAppBar(titleText: widget.title),
            endDrawer: const HamburgerMenu(),
            body: Center(
              child: Text(
                "Unauthorized access",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(color: Colors.red),
              ),
            ),
          )
        : Scaffold(
            key: Get.find<UIScaffoldState>().scaffoldKey,
            // Enable multi-deletion.
            appBar: widget.showAppBar
                ? _selectionMode != SelectionMode.none
                      ? _selectionMode == SelectionMode.other
                            ? CustomAppBar(
                                titleText: widget.title,
                                actions: [
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
                              )
                            : CustomAppBar(
                                titleText: widget.title,
                                actions: [
                                  ...AdditionalOptions.buildDefaultOptions(
                                    context: context,
                                    controller: _controller,
                                    notes:
                                        _selectedItems
                                            .whereType<Note>()
                                            .toList()
                                            .isNotEmpty
                                        ? _selectedItems
                                              .whereType<Note>()
                                              .toList()
                                        : null,
                                    tasks:
                                        _selectedItems
                                            .whereType<Task>()
                                            .toList()
                                            .isNotEmpty
                                        ? _selectedItems
                                              .whereType<Task>()
                                              .toList()
                                        : null,
                                    labels:
                                        _selectedItems
                                            .whereType<Label>()
                                            .toList()
                                            .isNotEmpty
                                        ? _selectedItems
                                              .whereType<Label>()
                                              .toList()
                                        : null,
                                    onUpdate: (updatedItems) {
                                      if (_controller is Controller<Note>) {
                                        final List<Note> updatedNotes =
                                            updatedItems
                                                .whereType<Note>()
                                                .toList();
                                        (_controller as Controller<Note>).edit(
                                          updatedNotes,
                                        );
                                      } else if (_controller
                                          is Controller<Task>) {
                                        final List<Task> updatedTasks =
                                            updatedItems
                                                .whereType<Task>()
                                                .toList();
                                        (_controller as Controller<Task>).edit(
                                          updatedTasks,
                                        );
                                      } else if (_controller
                                          is Controller<Label>) {
                                        final List<Label> updatedLabels =
                                            updatedItems
                                                .whereType<Label>()
                                                .toList();
                                        (_controller as Controller<Label>).edit(
                                          updatedLabels,
                                        );
                                      }

                                      setState(() {
                                        _selectedItems.clear();
                                        _selectionMode = SelectionMode.none;
                                      });
                                    },
                                    onActionComplete: () {
                                      setState(() {
                                        _selectedItems.clear();
                                        _selectionMode = SelectionMode.none;
                                      });
                                    },
                                    isForShared:
                                        widget.pageType ==
                                            ListScreenType.sharedNotes ||
                                        widget.pageType ==
                                            ListScreenType.sharedTasks,
                                    hidePin: true,
                                    hideArchive: true,
                                    hideShare:
                                        widget.pageType ==
                                                ListScreenType.noteLabels ||
                                            widget.pageType ==
                                                ListScreenType.taskLabels
                                        ? true
                                        : false,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedItems.clear();
                                        _selectionMode = SelectionMode.none;
                                      });
                                    },
                                    icon: Icon(Icons.close, color: Colors.red),
                                  ),
                                ],
                                replaceDefaultActions: true,
                              )
                      : CustomAppBar(titleText: widget.title)
                : null,
            endDrawer: const HamburgerMenu(),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  if (widget.description != null) ...[
                    Text(widget.description!),
                    const SizedBox(height: 16),
                  ],
                  CustomSearchBar(
                    searchController: _searchController,
                    onSearch: (value) => _controller.search(value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (_controller is Controller<FilterableEntity>)
                            IconButton(
                              onPressed: () async {
                                // Open a filter section at the bottom.
                                await showModalBottomSheet<ComponentFilter<T>>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => FilterPopUp<FilterableEntity>(
                                    controller:
                                        _controller
                                            as Controller<FilterableEntity>,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.filter_alt,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          IconButton(
                            onPressed: () async {
                              await showModalBottomSheet<T>(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext context) => SafeArea(
                                  child: SortPopUp<T>(controller: _controller),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.sort,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      _buildAddButton(),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchData,
                      child: Obx(() {
                        final listToShow =
                            ((widget.pageType == ListScreenType.noteLabels)
                                    ? (_controller as LabelController)
                                          .noteLabels
                                    : (widget.pageType ==
                                          ListScreenType.taskLabels)
                                    ? (_controller as LabelController)
                                          .taskLabels
                                    : _controller.filteredList)
                                .cast<T>();

                        if (_controller.isLoading.value && listToShow.isEmpty) {
                          return LoadingShimmer();
                        }

                        if (listToShow.isEmpty &&
                            !_controller.isLoading.value) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          itemCount: listToShow.length,
                          itemBuilder: (context, index) {
                            final item = listToShow[index];

                            final isFilterable = item is FilterableEntity;
                            String dateCreated = '';
                            if ((isFilterable &&
                                    (item as FilterableEntity).dateCreated !=
                                        null) ||
                                item is Team) {
                              dateCreated = DateFormat.yMd().format(
                                item.dateCreated!,
                              );
                            }
                            List<String> otherDetails = _getOtherDetails(item);
                            final onTap = _selectionMode != SelectionMode.none
                                ? () {
                                    widget.onItemTap?.call(item);
                                    _selectItem(item);
                                  }
                                : onTapCard(item);

                            // Build card-like widget to display details.
                            final card = _buildCard(
                              item: item,
                              dateCreated: dateCreated,
                              otherDetails: otherDetails,
                              onTap: onTap,
                              iconButtons: _buildIconButtons(item),
                            );

                            final isSelected = _selectedItems.contains(item);
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              margin: EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _selectionMode != SelectionMode.none
                                      ? () => _selectItem(item)
                                      : null,
                                  onLongPress:
                                      _selectionMode == SelectionMode.none
                                      ? () {
                                          setState(() {
                                            _selectionMode =
                                                SelectionMode.regular;
                                            _selectedItems.add(item);
                                          });
                                        }
                                      : null,
                                  child: Stack(
                                    children: [
                                      card,
                                      if (_selectionMode != SelectionMode.none)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (_) => _selectItem(item),
                                          ),
                                        ),
                                    ],
                                  ),
                                  // ? ListTile(
                                  //     subtitle: card,
                                  //     onTap:
                                  //         _selectionMode !=
                                  //             SelectionMode.none
                                  //         ? () => _selectItem(item)
                                  //         : null,
                                  //     trailing:
                                  //         _selectionMode !=
                                  //             SelectionMode.none
                                  //         ? SizedBox(
                                  //             width: 1,
                                  //             child: Checkbox(
                                  //               value: isSelected,
                                  //               onChanged: (_) {
                                  //                 _selectItem(item);
                                  //               },
                                  //             ),
                                  //           )
                                  //         : null,
                                  //   )
                                  // : card,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

typedef AsyncJoinCallback = Future<void> Function(String code);

class AddButtonPopUp extends StatefulWidget {
  final String forGroupType;
  final AsyncJoinCallback? joinFunction;
  const AddButtonPopUp({
    super.key,
    required this.forGroupType,
    this.joinFunction,
  });

  @override
  State<AddButtonPopUp> createState() => _AddButtonPopUpState();
}

class _AddButtonPopUpState extends State<AddButtonPopUp> {
  final TextEditingController controller = TextEditingController();
  OverlayEntry? overlayEntry;
  bool isJoinSelected = false;

  void _togglePopUp() {
    if (overlayEntry == null) {
      _showPopUp();
    } else {
      _removePopUp();
    }
  }

  void _removePopUp() {
    overlayEntry?.remove();
    overlayEntry = null;
    isJoinSelected = false;
    controller.clear();
  }

  void _showPopUp() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: _removePopUp,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                top: position.dy + 50,
                right: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 150),
                        child: Container(
                          key: ValueKey(isJoinSelected),
                          child: isJoinSelected
                              ? _codeRequestPopUp(setState)
                              : _popup(setState),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry!);
  }

  Widget _codeRequestPopUp(Function(VoidCallback) localSetState) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 200),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => localSetState(() {
                  isJoinSelected = false;
                }),
                icon: Icon(Icons.arrow_back),
              ),
              const SizedBox(height: 5),
              TextField(
                decoration: InputDecoration(
                  labelText: "Code",
                  border: OutlineInputBorder(),
                ),
                maxLength: 5,
                maxLines: 1,
                controller: controller,
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final String code = controller.text;
                    await widget.joinFunction!(code);
                    _removePopUp();
                  },
                  child: Text(
                    'Join',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popup(Function(VoidCallback) localSetState) {
    final groupType = widget.forGroupType.toLowerCase().trim();
    final isClass = groupType == "class";
    final isTeam = groupType == "team";

    return Card(
      elevation: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => localSetState(() {
              isJoinSelected = true;
            }),
            child: Text('Join ${isClass ? "Class" : "Team"}'),
          ),
          if ((isClass &&
                  Get.find<RoleController>().hasPermission(
                    PermissionType.createClass,
                  )) ||
              (isTeam &&
                  Get.find<RoleController>().hasPermission(
                    PermissionType.viewCreateTeam,
                  )))
            TextButton(
              onPressed: () {
                _removePopUp();
                if (isClass) {
                  Get.toNamed(Routes.createClass);
                } else if (isTeam) {
                  Get.toNamed(Routes.createTeam);
                }
              },
              child: Text('Create ${isClass ? "Class" : "Team"}'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _togglePopUp,
      icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}
