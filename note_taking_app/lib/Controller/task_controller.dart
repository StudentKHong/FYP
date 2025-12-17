import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  TaskController() : super(repository: Get.find<TaskRepository>());

  @override
  void onClose() {
    _watchByLabelSubscription?.cancel();
    _watchByGroupSubscription?.cancel();
    super.onClose();
  }

  @override
  Future<Task?> create(Task entity) async {
    try {
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

      pushItemToTop(entity: newEntity);

      return newEntity;
    } catch (ex) {
      if (ex.toString().isNotEmpty) {
        errorMessage.value = ex.toString();
      } else {
        errorMessage.value = "Something went wrong";
      }
      return null;
    }
  }

  @override
  Future<void> delete(List<String> componentIds) async {
    try {
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
    }
  }

  @override
  Future<void> getAll() async {
    try {
      errorMessage.value = "";
      // Fetch tasks.
      watchAllSubscription = _taskRepository.watchAll().listen((notes) {
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
    }
  }

  Future<void> getByGroup(String groupId, String groupType) async {
    try {
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

  // Future<void> getRecent() async {
  //   try {
  //     errorMessage.value = "";
  //     final recentTasks = await _taskRepository.getRecentTasks();
  //     list.assignAll(recentTasks);
  //   } catch (ex) {
  //     errorMessage.value = "Something went wrong.";
  //   }
  // }

  Future<Label?> getLabel(String labelId) async {
    try {
      errorMessage.value = "";
      _labelController.getById(labelId);
      return _labelController.content.value;
    } catch (e) {
      errorMessage.value = "Something went wrong";
      return null;
    }
  }

  Future<int?> getCountByLabel(String labelId) async {
    try {
      errorMessage.value = "";
      int? size;
      size = await _taskRepository.getTaskCount(labelId);
      return size;
    } catch (ex) {
      errorMessage.value = "Something went wrong";
      return null;
    }
  }

  Future<void> shareMultiple(
    List<Task> groupContents,
    String groupId,
    String groupType,
  ) async {
    try {
      errorMessage.value = "";
      groupContents = groupContents.map((content) {
        final labelName = content.label?.name;
        return content.copyWith(
          labelName: labelName,
          label: null,
          replaceLabel: true,
        );
      }).toList();
      final List<Task> createdGroupContents =
          await (repository as TaskRepository).shareMultiple(
            groupContents,
            groupId,
            groupType,
          );
      list.addAll(createdGroupContents);
      filteredList.addAll(createdGroupContents);
    } catch (ex) {
      errorMessage.value = ex.toString();
    }
  }

  Future<void> editShared(Task task, String groupId, String groupType) async {
    try {
      errorMessage.value = "";
      final newEntity = await (repository as TaskRepository).editShared(
        task,
        groupId,
        groupType,
      );

      // Update reactive list and filteredList.
      pushItemToTop(
        entity: newEntity,
      );
    } catch (ex) {
      errorMessage.value = ex.toString();
    }
  }

  Future<void> deleteShared(
    List<String> taskIds,
    String groupId,
    String groupType,
  ) async {
    try {
      errorMessage.value = "";
      // Delete selected shared tasks.
      final tasks = list.where((task) => taskIds.contains(task.id)).toList();
      await (repository as TaskRepository).deleteShared(
        taskIds,
        groupId,
        groupType,
      );

      // Update the count of the label.
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

      // Remove tasks from lists.
      final deletedNoteIds = tasks.map((task) => task.id).toList();
      list.removeWhere((item) => deletedNoteIds.contains(item.id));
      filteredList.removeWhere((item) => deletedNoteIds.contains(item.id));
    } catch (ex) {
      errorMessage.value = "Failed to delete notes.";
    }
  }

  Future<void> setLabelToTasks(String labelId, List<String> taskIds) async {
    try {
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
    }
  }

  Future<void> togglePinStatus(Task task) async {
    final updatedItem = task.copyWith(isPinned: !task.isPinned);
    await edit([updatedItem], pushToTop: false);
  }

  Future<void> toggleArchiveStatus(Task task) async {
    final updatedItem = task.copyWith(isArchived: !(task.isArchived ?? true));
    await edit([updatedItem], pushToTop: false);
  }

  @override
  void filter({DateTimeRange? taskPeriod}) {
    try {
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
    }
  }

  void getArchived() {
    errorMessage.value = "";
    watchAllSubscription?.cancel();
    watchAllSubscription = (repository as TaskRepository)
        .watchArchived()
        .listen((tasks) {
          filteredList.assignAll(tasks);
        }, onError: (ex) {
          errorMessage.value = ex.toString();
        });
  }

  @override
  ComponentFilter<Task>? createFilter() {
    return TaskFilter();
  }
}
