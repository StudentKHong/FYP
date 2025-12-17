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
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/SharedComponents/filter_popup.dart';
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
  final VoidCallback? onAddTap;
  final void Function(T item)? onItemTap;
  final Function(SelectionMode mode)? onSelectionModeChanged;
  final Function(List<dynamic> selected)? onSelectionChanged;

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
    this.onAddTap,
    this.onItemTap,
    this.onSelectionModeChanged,
    this.onSelectionChanged,
  });

  @override
  State<ListScreen<T>> createState() => _ListScreenState<T>();
}

class _ListScreenState<T extends BaseEntity> extends State<ListScreen<T>> {
  final AuthenticationController authController =
      Get.find<AuthenticationController>();
  final RoleController roleController = Get.find<RoleController>();
  final TextEditingController _searchController = TextEditingController();
  late final Controller<T> _controller;
  // late final Controller<T> _noteTaskController;

  final List<T> _selectedItems = [];
  late SelectionMode _selectionMode;
  int filteredListUpdateCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;
    _selectionMode = widget.initialSelectionMode;
    // // Get NoteController or TaskController
    // if (T == Note) {
    //   _noteTaskController = Get.find<NoteController>() as Controller<T>;
    // } else if (T == Task) {
    //   _noteTaskController = Get.find<TaskController>() as Controller<T>;
    // }

    _fetchData();
    _controller.filteredList.listen((updatedList) {
      filteredListUpdateCount++;
      print("filteredList updated $filteredListUpdateCount times");
      // Optional: print first 3 items to debug
      print("First 3 items: ${updatedList.take(3).toList()}");
    });
  }

  @override
  void didUpdateWidget(covariant ListScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchData();
  }

  Future<void> _fetchData() async {
    // authController.checkAuthentication();

    if (widget.customFetchFunction != null) {
      widget.customFetchFunction!();
      return;
    }
    if (_controller is LabelController) {
      if (widget.pageType == ListScreenType.noteLabels) {
        (_controller as LabelController).getNoteLabels();
      } else if (widget.pageType == ListScreenType.taskLabels) {
        (_controller as LabelController).getTaskLabels();
      }
    } else if (widget.pageType == ListScreenType.sharedNotes ||
        widget.pageType == ListScreenType.sharedTasks) {
      return;
    } else {
      _controller.getAll();
    }
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
              customFetchFunction: () {
                controller.getByLabel(item.id!);
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

  List<IconButton> _buildIconButtons(T item) {
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

    final List<IconButton> iconButtons = [];
    if (item is Note || item is Task) {
      iconButtons.addAll([
        IconButton(
          onPressed: () {
            final isPinned = (item as dynamic).isPinned;
            final newItem = (item as dynamic).copyWith(isPinned: !isPinned);

            final index = _controller.filteredList.indexOf(item);
            if (index != -1) {
              _controller.filteredList.removeAt(index);
              _controller.filteredList.insert(0, newItem);
              sortList();
            }
            if (item is Note) {
              (_controller as NoteController).togglePinStatus(item);
            } else if (item is Task) {
              (_controller as TaskController).edit([newItem]);
            }
          },
          icon: Icon(
            (item as dynamic).isPinned
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            color: Colors.black,
          ),
        ),
        IconButton(
          onPressed: () async {
            final isArchived = (item as dynamic).isArchived;
            final newItem = (item as dynamic).copyWith(isArchived: !isArchived);

            final index = _controller.filteredList.indexOf(item);
            if (index != -1) {
              _controller.filteredList.removeAt(index);
              _controller.filteredList.insert(0, newItem);
              sortList();
            }

            if (item is Note) {
              await (_controller as NoteController).edit([newItem]);
            } else if (item is Task) {
              await (_controller as TaskController).edit([newItem]);
            }
          },
          icon: Icon(
            (item as dynamic).isArchived
                ? Icons.archive
                : Icons.archive_outlined,
            color: Colors.black,
          ),
        ),
      ]);
    }
    return iconButtons;
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
      );
    }
    return CustomExtendedCard(
      key: ValueKey(item.id),
      title: item.name,
      status: item is Task ? item.status : null,
      content: [item.description ?? '', dateCreated],
      otherDetails: otherDetails,
      onTap: onTap,
      iconButtons: iconButtons,
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
                                    isForShared:
                                        widget.pageType ==
                                            ListScreenType.sharedNotes ||
                                        widget.pageType ==
                                            ListScreenType.sharedTasks,
                                    hidePin: true,
                                    hideArchive: true,
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
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  if (widget.description != null) ...[
                    Text(widget.description!),
                    const SizedBox(height: 10),
                  ],
                  CustomSearchBar(
                    searchController: _searchController,
                    onSearch: (value) => _controller.search(value),
                  ),
                  const SizedBox(height: 5),
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
                              icon: Icon(Icons.filter_alt),
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
                            icon: Icon(Icons.sort),
                          ),
                        ],
                      ),

                      if (_selectionMode == SelectionMode.none)
                        widget.pageType == ListScreenType.classes ||
                                widget.pageType == ListScreenType.teams
                            ? AddButtonPopUp(
                                classJoinFunction: (code) async {
                                  if (widget.pageType ==
                                      ListScreenType.classes) {
                                    final joinedClass =
                                        await (_controller as ClassController)
                                            .join(code);
                                    if (joinedClass == null) {
                                      if (_controller
                                          .errorMessage
                                          .value
                                          .isNotEmpty) {
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
                                    final joinedTeam =
                                        await (_controller as TeamController)
                                            .join(code);
                                    if (joinedTeam == null) {
                                      if (_controller
                                          .errorMessage
                                          .value
                                          .isNotEmpty) {
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
                                icon: Icon(Icons.add),
                              )
                            : const SizedBox.shrink(),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Expanded(
                    child: Obx(() {
                      final listToShow =
                          ((widget.pageType == ListScreenType.noteLabels)
                                  ? (_controller as LabelController).noteLabels
                                  : (widget.pageType ==
                                        ListScreenType.taskLabels)
                                  ? (_controller as LabelController).taskLabels
                                  : _controller.filteredList)
                              .cast<T>();

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

                          // if (widget.pageType == ListScreenType.labels &&
                          //     item is Label) {
                          //   return NavigationButtons.drawerTile(
                          //     context: context,
                          //     leadingIcon: Icons.label,
                          //     title: item.name,
                          //     trailingText: item.count.toString(),
                          //     onTap: () => Get.to(
                          //       LabelScreen(
                          //         title: item.name,
                          //         controller: _controller,
                          //       ),
                          //     ),
                          //   );
                          // }

                          // Build card-like widget to display details.
                          final card = _buildCard(
                            item: item,
                            dateCreated: dateCreated,
                            otherDetails: otherDetails,
                            onTap: onTap,
                            iconButtons: _buildIconButtons(item),
                          );

                          final isSelected = _selectedItems.contains(item);
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: card,
                              onTap: _selectionMode != SelectionMode.none
                                  ? () => _selectItem(item)
                                  : null,
                              onLongPress:
                                  _selectionMode == SelectionMode.none ||
                                      widget.pageType != ListScreenType.classes
                                  ? () {
                                      setState(() {
                                        _selectionMode = SelectionMode.regular;
                                        _selectedItems.add(item);

                                        widget.onSelectionModeChanged?.call(
                                          _selectionMode,
                                        );
                                        widget.onSelectionChanged?.call(
                                          List.from(_selectedItems),
                                        );
                                      });
                                    }
                                  : null,
                              trailing: _selectionMode != SelectionMode.none
                                  ? SizedBox(
                                      width: 1,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) {
                                          _selectItem(item);
                                        },
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
  }
}

typedef AsyncJoinCallback = Future<void> Function(String code);

class AddButtonPopUp extends StatefulWidget {
  final AsyncJoinCallback? classJoinFunction;
  const AddButtonPopUp({super.key, this.classJoinFunction});

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
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.white),
                  ),
                  onPressed: () async {
                    final String code = controller.text;
                    if (widget.classJoinFunction != null) {
                      await widget.classJoinFunction!(code);
                    }
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
    return Card(
      elevation: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => localSetState(() {
              isJoinSelected = true;
            }),
            child: Text('Join Class'),
          ),
          TextButton(
            onPressed: () {
              _removePopUp();
              Get.toNamed(Routes.createClass);
            },
            child: Text('Create Class'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: _togglePopUp, icon: Icon(Icons.add));
  }
}
