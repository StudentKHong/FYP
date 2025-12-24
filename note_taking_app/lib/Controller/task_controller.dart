import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Repository/task_repository.dart';

class TaskController extends Controller<Task> {
  final TaskRepository _taskRepository = Get.find<TaskRepository>();
  final LabelController _labelController = Get.find<LabelController>();

  StreamSubscription<List<Task>>? _watchByLabelSubscription;
  StreamSubscription<List<Task>>? _watchByGroupSubscription;
  StreamSubscription<List<Task>>? _watchArchivedSubscription;

  TaskController() : super(repository: Get.find<TaskRepository>());

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthenticationController>();
    ever(authController.user, (user) {
      watchAllSubscription?.cancel();
      watchAllCountSubscription?.cancel();
      watchByIdSubscription?.cancel();
      _watchByGroupSubscription?.cancel();
      _watchByLabelSubscription?.cancel();
      _watchArchivedSubscription?.cancel();

      if (user != null) {
        _labelController.getTaskLabels();
        getAll();
        getAllCount();
      } else {
        list.clear();
        filteredList.clear();
        totalCount.value = 0;
      }
    });
  }

  @override
  void onClose() {
    _watchByLabelSubscription?.cancel();
    _watchByGroupSubscription?.cancel();
    _watchArchivedSubscription?.cancel();
    super.onClose();
  }

  @override
  void pushItemToTop({
    required Task entity,
    bool forList = true,
    bool forFilteredList = true,
  }) {
    if (forList) {
      list.removeWhere((item) => item.id == entity.id);

      final listIndex = list.indexWhere(
        (item) => item.isPinned == entity.isPinned,
      );
      final adjustedIndex = listIndex == -1 ? 0 : listIndex;
      list.insert(adjustedIndex, entity);
      list.refresh();
    }
    if (forFilteredList) {
      filteredList.removeWhere((item) => item.id == entity.id);
      final filteredListIndex = filteredList.indexWhere(
        (item) => item.isPinned == entity.isPinned,
      );
      final adjustedIndex = filteredListIndex == -1 ? 0 : filteredListIndex;
      filteredList.insert(adjustedIndex, entity);
      filteredList.refresh();
    }
  }

  @override
  Future<Task?> create(Task entity) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final newEntity = await repository.create(entity);

      if (entity.label != null && entity.label!.id != null) {
        await _labelController.incrementCount(entity.label!);
      }
      list.add(newEntity);

      if (currentFilter.value == null || currentFilter.value!.isEmpty) {
        filteredList.add(newEntity);
      } else {
        final filter = currentFilter.value!;

        if (filter.baseFilter(newEntity)) {
          filteredList.add(newEntity);
        }
      }
      _sortLists(list: filteredList);
      _sortLists(list: list);

      return newEntity;
    } catch (ex) {
      if (ex.toString().isNotEmpty) {
        errorMessage.value = ex.toString();
      } else {
        errorMessage.value = "Something went wrong";
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> delete(List<String> componentIds) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final tasks = list
          .where((task) => componentIds.contains(task.id))
          .toList();
      await repository.delete(componentIds);

      final labelsToUpdate = <String, Label>{};
      for (var task in tasks) {
        final label = task.label;
        if (label != null && label.id != null) {
          labelsToUpdate[label.id!] = label;
        }
      }
      await Future.wait(
        labelsToUpdate.values.map(
          (label) => _labelController.decrementCount(label),
        ),
      );

      final taskIds = tasks.map((task) => task.id).toList();
      list.removeWhere((item) => taskIds.contains(item.id));
      filteredList.removeWhere((item) => taskIds.contains(item.id));
    } catch (ex) {
      errorMessage.value = "Failed to delete notes.";
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> getAll() async {
    isLoading.value = true;
    errorMessage.value = "";

    _watchByLabelSubscription?.cancel();
    watchAllSubscription?.cancel();

    // Fetch tasks.
    final labels = _labelController.taskLabels;
    watchAllSubscription = _taskRepository.watchAll().listen(
      (tasks) {
        final tasksWithLabels = tasks.map((task) {
          final labelId = task.label?.id;
          return labelId != null && labels.any((label) => label.id == labelId)
              ? task.copyWith(
                  label: labels.firstWhere((label) => label.id == labelId),
                )
              : task;
        }).toList();
        list.assignAll(tasksWithLabels);
        filteredList.assignAll(tasksWithLabels);
        isLoading.value = false;
      },
      onError: (ex) {
        errorMessage.value = ex.toString();
        isLoading.value = false;
      },
    );

    // Refilter if current filter exists.
    if (currentFilter.value != null &&
        currentFilter.value!.labelNames != null) {
      filter();
    }
  }

  Future<void> getByGroup(String groupId, String groupType) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      // Fetch tasks.
      _watchByGroupSubscription = _taskRepository
          .watchByGroup(groupId, groupType)
          .listen((notes) {
            list.assignAll(notes);
            filteredList.assignAll(notes);
          });

      // Refilter if current filter exists.
      if (currentFilter.value != null &&
          currentFilter.value!.labelNames != null) {
        filter();
      }
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getByLabel(String labelId) async {
    errorMessage.value = "";
    _watchByLabelSubscription?.cancel();
    _watchByLabelSubscription = _taskRepository
        .watchByLabel(labelId)
        .listen(
          (tasks) => filteredList.assignAll(tasks),
          onError: (ex) => errorMessage.value = "Failed to fetch tasks.",
        );
  }

  Future<Label?> getLabel(String labelId) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      _labelController.getById(labelId);
      return _labelController.content.value;
    } catch (e) {
      errorMessage.value = "Something went wrong";
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<int?> getCountByLabel(String labelId) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      int? size;
      size = await _taskRepository.getTaskCount(labelId);
      return size;
    } catch (ex) {
      errorMessage.value = "Something went wrong";
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareMultiple(
    List<Task> groupContents,
    String groupId,
    String groupType,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      groupContents = groupContents.map((content) {
        final labelName = content.label?.name;
        return content.copyWith(
          labelName: labelName,
          label: null,
          replaceLabel: true,
          isPinned: false,
        );
      }).toList();
      // final List<Task> createdGroupContents =
      await (repository as TaskRepository).shareMultiple(
        groupContents,
        groupId,
        groupType,
      );
      // filteredList.addAll(createdGroupContents);
      // _sortLists(list: filteredList);
      // list.addAll(createdGroupContents);
      // _sortLists(list: list);
    } catch (ex) {
      errorMessage.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editShared(Task task, String groupId, String groupType) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final newEntity = await (repository as TaskRepository).editShared(
        task,
        groupId,
        groupType,
      );

      // Update reactive list and filteredList.
      pushItemToTop(entity: newEntity);
    } catch (ex) {
      errorMessage.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteShared(
    List<String> taskIds,
    String groupId,
    String groupType,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      // Delete selected shared tasks.
      final tasks = list.where((task) => taskIds.contains(task.id)).toList();
      print("Tasks: ${tasks.map((task) => task.name)}");
      print("Group Id: $groupId");
      print("Group Type: $groupType");
      await (repository as TaskRepository).deleteShared(
        taskIds,
        groupId,
        groupType,
      );

      // // Update the count of the label.
      // final labelsToUpdate = <String, Label>{};
      // for (var task in tasks) {
      //   final label = task.label;
      //   if (label != null && label.id != null) {
      //     labelsToUpdate[label.id!] = label;
      //   }
      // }
      // await Future.wait(
      //   labelsToUpdate.values.map(
      //     (label) => _labelController.decrementCount(label),
      //   ),
      // );

      // Remove tasks from lists.
      final deletedNoteIds = tasks.map((task) => task.id).toList();
      list.removeWhere((item) => deletedNoteIds.contains(item.id));
      filteredList.removeWhere((item) => deletedNoteIds.contains(item.id));
    } catch (ex) {
      errorMessage.value = "Failed to delete notes.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setLabelToTasks(String labelId, List<String> taskIds) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      // Set label.
      await _taskRepository.setLabel(labelId, taskIds);

      // Update lists with the latest label.
      for (var task in list) {
        if (taskIds.contains(task.id)) {
          task = task.copyWith(label: await getLabel(labelId));
        }
      }
      for (var task in filteredList) {
        if (taskIds.contains(task.id)) {
          task = task.copyWith(label: await getLabel(labelId));
        }
      }
    } catch (ex) {
      errorMessage.value = "Something went wrong";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeLabelFromTasks(String labelId) async {
    final tasksToUpdate = list.map((item) {
      if (item.label?.id == labelId) {
        return item.copyWith(label: null, replaceLabel: true);
      }
      return item;
    }).toList();
    await edit(tasksToUpdate, pushToTop: false);
  }

  Future<void> togglePinStatus(Task task) async {
    final bool isPinned = !task.isPinned;

    final updatedItem = task.copyWith(
      isPinned: isPinned,
      isArchived: isPinned ? false : (task.isArchived ?? false),
    );

    _sortLists(list: filteredList);
    _sortLists(list: list);

    await edit([updatedItem], pushToTop: false);
  }

  // Sort Notes and Tasks only.
  void _sortLists({required List<Task> list}) {
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      if (a.isPinned && b.isPinned) {
        return a.pinnedAt!.compareTo(b.pinnedAt!);
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> toggleArchiveStatus(Task task) async {
    final bool isArchived = !(task.isArchived ?? false);

    final updatedItem = task.copyWith(
      isArchived: isArchived,
      isPinned: isArchived ? false : task.isPinned,
    );
    await edit([updatedItem], pushToTop: false);
  }

  @override
  void filter({DateTimeRange? taskPeriod}) {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      if (currentFilter.value == null || currentFilter.value!.isEmpty) {
        return;
      }
      filteredList.assignAll(
        list.isNotEmpty
            ? taskPeriod != null
                  ? (currentFilter.value! as TaskFilter).filterByStartAndEnd(
                      list,
                      taskPeriod,
                    )
                  : currentFilter.value!.filter(list)
            : [],
      );
    } catch (e) {
      errorMessage.value = "Something went wrong";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getArchived() async {
    isLoading.value = true;
    errorMessage.value = "";
    _watchArchivedSubscription?.cancel();
    _watchArchivedSubscription = (repository as TaskRepository)
        .watchArchived()
        .listen(
          (tasks) {
            final labels = _labelController.taskLabels;
            final tasksWithLabels = tasks.map((task) {
              final labelId = task.label?.id;
              return labelId != null &&
                      labels.any((label) => label.id == labelId)
                  ? task.copyWith(
                      label: labels.firstWhere((label) => label.id == labelId),
                    )
                  : task;
            }).toList();
            filteredList.assignAll(tasksWithLabels);
            isLoading.value = false;
          },
          onError: (ex) {
            errorMessage.value = ex.toString();
            isLoading.value = false;
          },
        );
  }

  @override
  ComponentFilter<Task>? createFilter() {
    return TaskFilter();
  }
}
