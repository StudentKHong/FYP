import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';

abstract class Controller<T extends BaseEntity> extends GetxController {
  @protected
  final Repository<T> repository;

  var list = <T>[].obs;
  var filteredList = <T>[].obs;
  var totalCount = 0.obs;
  late final Rxn<ComponentFilter<T>> currentFilter = Rxn<ComponentFilter<T>>();
  late final Rxn<ComponentSort<T>> currentSort = Rxn<ComponentSort<T>>();
  var content = Rxn<T>();
  var errorMessage = "".obs;

  StreamSubscription<List<T>>? watchAllSubscription;
  StreamSubscription<int>? watchAllCountSubscription;
  StreamSubscription<T?>? watchByIdSubscription;

  Controller({required this.repository});

  @override
  void onInit() {
    super.onInit();
    currentFilter.value = createFilter();
    currentSort.value = ComponentSort();
  }

  @override
  void onClose() {
    watchAllSubscription?.cancel();
    watchAllCountSubscription?.cancel();
    watchByIdSubscription?.cancel();
    super.onClose();
  }

  // To ensure updated or created item is always on top of the list.
  @protected
  void pushItemToTop({required T entity}) {
    final othersInList = list.where((item) => item.id != entity.id);
    final newList = [entity, ...othersInList];
    list.value = newList;

    final othersInFilteredList = filteredList.where(
      (item) => item.id != entity.id,
    );
    final newFilteredList = [entity, ...othersInFilteredList];
    filteredList.value = newFilteredList;
  }

  ComponentFilter<T>? createFilter();

  List<T> get mostRecent =>
      list.length <= 3 ? list.toList() : list.sublist(0, 3);

  Future<void> getById(String componentId) async {
    errorMessage.value = "";
    watchByIdSubscription?.cancel();
    watchByIdSubscription = repository.watchById(componentId).listen((data) {
      content.value = data;
    }, onError: (ex) => errorMessage.value = ex.toString());
  }

  void getAll() {
    errorMessage.value = "";
    watchAllSubscription?.cancel();
    watchAllSubscription = repository.watchAll().listen((data) {
      list.assignAll(data);
      filteredList.assignAll(data);
    }, onError: (ex) => errorMessage.value = ex.toString());
  }

  void getAllCount() {
    errorMessage.value = "";
    watchAllCountSubscription?.cancel();
    watchAllCountSubscription = repository.watchAllCount().listen((count) {
      totalCount.value = count;
    }, onError: (ex) => errorMessage.value = ex.toString());
  }

  void resetFilter() {
    currentFilter.value = createFilter();
    filteredList.assignAll(list);
    if (currentSort.value != null) {
      sort();
    }
  }

  void setFilter(ComponentFilter<T> componentFilter) {
    currentFilter.value = componentFilter;
  }

  void filter() {
    try {
      errorMessage.value = "";
      if (currentFilter.value == null || currentFilter.value!.isEmpty) {
        return;
      }
      filteredList.assignAll(
        filteredList.isNotEmpty
            ? currentFilter.value!.filter(filteredList)
            : [],
      );
    } catch (e) {
      errorMessage.value = "Something went wrong";
    }
  }

  void resetSort() {
    currentSort.value = null;
    filteredList.assignAll(list);
    if (currentFilter.value != null) {
      filter();
    }
  }

  void setSort(ComponentSort<T> componentSort) {
    currentSort.value = componentSort;
  }

  void sort() {
    try {
      errorMessage.value = "";
      if (currentSort.value == null || currentSort.value!.isEmpty) {
        return;
      }
      final List<T> listToSort = filteredList.toList();
      if (listToSort.isNotEmpty) {
        final sortedList = currentSort.value!.sort(listToSort);
        filteredList.assignAll(sortedList);
      }
    } catch (e) {
      errorMessage.value = "Something went wrong";
    }
  }

  Future<void> search(String keyword) async {
    try {
      errorMessage.value = "";
      final cleanedKeyword = keyword.toLowerCase();

      if (cleanedKeyword.isEmpty) {
        filteredList.assignAll(list);
        return;
      }
      final searchResult = list.where((item) {
        if (item.name == null || item.description == null) return false;
        return item.name!.toLowerCase().contains(cleanedKeyword) ||
            item.description!.toLowerCase().contains(cleanedKeyword);
      }).toList();
      filteredList.assignAll(searchResult);
    } catch (e) {
      errorMessage.value = "Something went wrong";
    }
  }

  Future<T?> create(T entity) async {
    try {
      errorMessage.value = "";
      final newEntity = await repository.create(entity);
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

  Future<void> edit(List<T> entities, {bool pushToTop = true}) async {
    try {
      // Update component in Firebase Firestore.
      errorMessage.value = "";
      print("Edit is triggered.");
      final newEntities = await repository.edit(entities);

      // Update reactive list and filteredList.
      for (final updatedEntity in newEntities) {
        if (pushToTop) {
          pushItemToTop(entity: updatedEntity);
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> delete(List<String> componentIds) async {
    try {
      errorMessage.value = "";
      await repository.delete(componentIds);
      list.removeWhere((item) => componentIds.contains(item.id));
      filteredList.removeWhere((item) => componentIds.contains(item.id));
    } catch (ex) {
      errorMessage.value = "Failed to delete notes.";
    }
  }
}

class ComponentSort<T extends BaseEntity> {
  // Assumes true as ascending, false as descending.
  // Null means sort not selected.
  bool? name;
  bool? dateCreated;

  bool get isEmpty => name == null && dateCreated == null;

  ComponentSort({this.name, this.dateCreated});

  List<T> sort(List<T> entities) {
    if (name != null) {
      entities.sort((a, b) {
        final aName = a.name ?? '';
        final bName = b.name ?? '';
        return name! ? aName.compareTo(bName) : bName.compareTo(aName);
      });
    }
    if (dateCreated != null) {
      entities.sort((a, b) {
        final aDate = a.dateCreated ?? DateTime(2000);
        final bDate = b.dateCreated ?? DateTime(2000);
        return dateCreated! ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });
    }
    return entities;
  }
}

abstract class ComponentFilter<T extends BaseEntity> {
  List<String>? labelNames;
  DateTimeRange? dateCreated;
  DateTimeRange? dateModified;

  ComponentFilter({this.labelNames, this.dateCreated, this.dateModified});

  bool get isEmpty =>
      (labelNames == null || labelNames!.isEmpty) &&
      dateCreated == null &&
      dateModified == null;

  bool baseFilter(T entity) {
    if (entity is! FilterableEntity) {
      return true;
    }
    bool match = true;
    if (labelNames != null && labelNames!.isNotEmpty && entity.label != null) {
      match &= labelNames!.contains(entity.label!.name);
    }
    if (dateCreated != null) {
      match &=
          !entity.dateCreated!.isBefore(dateCreated!.start) &&
          !entity.dateCreated!.isAfter(dateCreated!.end);
    }
    if (dateModified != null) {
      match &=
          !entity.dateModified!.isBefore(dateModified!.start) &&
          !entity.dateModified!.isAfter(dateModified!.end);
    }
    return match;
  }

  List<T> filter(List<T> items);
}

// class NoteTaskFilter extends ComponentFilter<GroupContent> {
//   final List<String>? status;
//   final List<ComponentType>? componentTypes;

//   NoteTaskFilter({
//     super.labelNames,
//     super.dateCreated,
//     super.dateModified,
//     this.status,
//     this.componentTypes,
//   });

//   @override
//   bool get isEmpty =>
//       super.isEmpty &&
//       (status == null || status!.isEmpty) &&
//       (componentTypes == null || componentTypes!.isEmpty);

//   @override
//   List<GroupContent> filter(List<GroupContent> items) {
//     final filteredList = items.where((item) {
//       bool match = baseFilter(item);
//       if (status != null && status!.isNotEmpty && item.isTaskStatusNotNull) {
//         match &=
//             status!.contains(
//               Status.convertToString(item.memberTaskStatus!.taskStatus),
//             ) &&
//             match;
//       } else {
//         match = false;
//       }

//       if (componentTypes != null && componentTypes!.isNotEmpty) {
//         final type = item.isSharedNoteNotNull
//             ? ComponentType.note
//             : ComponentType.task;
//         match &= !componentTypes!.contains(type);
//       }
//       return match;
//     }).toList();
//     return filteredList;
//   }
// }

class NoteFilter extends ComponentFilter<Note> {
  NoteFilter({super.labelNames, super.dateCreated, super.dateModified});

  @override
  bool get isEmpty =>
      (labelNames == null || labelNames!.isEmpty) &&
      dateCreated == null &&
      dateModified == null;

  @override
  List<Note> filter(List<Note> items) {
    return items.where((item) => baseFilter(item)).toList();
  }
}

class TaskFilter extends ComponentFilter<Task> {
  DateTimeRange? taskPeriod;
  List<String>? status;

  TaskFilter({
    super.labelNames,
    super.dateCreated,
    super.dateModified,
    this.taskPeriod,
    this.status,
  });

  @override
  bool get isEmpty =>
      (labelNames == null || labelNames!.isEmpty) &&
      dateCreated == null &&
      dateModified == null &&
      taskPeriod == null &&
      status == null;

  @override
  List<Task> filter(List<Task> items) {
    return items.where((item) {
      final match = baseFilter(item);

      bool matchTaskPeriod = true;
      if (taskPeriod != null) {
        matchTaskPeriod =
            !item.dateCreated!.isBefore(dateCreated!.start) &&
            !item.dateCreated!.isAfter(dateCreated!.end);
      }

      bool matchStatus = true;
      if (status != null && status!.isNotEmpty && item.status != null) {
        matchStatus = status!.contains(Status.convertToString(item.status!));
      }
      return matchTaskPeriod && matchStatus && match;
    }).toList();
  }

  List<Task> filterByStartAndEnd(List<Task> items, DateTimeRange? taskPeriod) {
    if (taskPeriod == null) {
      return items;
    }

    final periodStart = taskPeriod.start;
    final periodEnd = taskPeriod.end;

    return items.where((item) {
      if (item.startDateTime == null) {
        return false;
      }
      final taskStart = item.startDateTime!;
      final taskEnd = item.endDateTime ?? taskStart;

      return taskStart.isBefore(periodEnd) && taskEnd.isAfter(periodStart);
    }).toList();
  }
}
