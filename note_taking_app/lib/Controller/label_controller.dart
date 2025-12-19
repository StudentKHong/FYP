import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Repository/label_repository.dart';

class LabelController extends Controller<Label> {
  var noteLabels = <Label>[].obs;
  var taskLabels = <Label>[].obs;
  var suggestedLabels = <Label>[].obs;

  StreamSubscription<List<Label>>? _noteLabelSubscription;
  StreamSubscription<List<Label>>? _taskLabelSubscription;

  LabelController() : super(repository: Get.find<LabelRepository>());

  @override
  void onClose() {
    _noteLabelSubscription?.cancel();
    _taskLabelSubscription?.cancel();
    super.onClose();
  }

  @override
  ComponentFilter<Label>? createFilter() {
    return null;
  }

  @override
  Future<Label?> create(Label entity) async {
    try {
      errorMessage.value = "";
      final isExisted = list
          .where((label) => label.name == entity.name)
          .toList();

      if (isExisted.isNotEmpty) {
        throw Exception("Label already existed.");
      }
      final newLabel = await repository.create(entity);
      list.add(newLabel);

      if (currentFilter.value == null || currentFilter.value!.isEmpty) {
        filteredList.add(newLabel);
      } else {
        final filter = currentFilter.value!;

        if (filter.baseFilter(newLabel)) {
          filteredList.add(newLabel);
        }
      }

      return newLabel;
    } catch (ex) {
      if (ex.toString().isNotEmpty) {
        errorMessage.value = ex.toString();
      } else {
        errorMessage.value = "Something went wrong";
      }
      return null;
    }
  }

  Future<void> incrementCount(Label label) async {
    try {
      errorMessage.value = "";
      final labelRepository = super.repository as LabelRepository;
      await labelRepository.incrementCount(label.id!, 1);
      content.value = label.copyWith(count: label.count + 1);
    } on FirebaseException catch (ex) {
      if (ex.code == 'not-found') {
        final labelRepository = super.repository as LabelRepository;
        await labelRepository.edit([label]);
      }
      if (ex.message != null) {
        errorMessage.value = ex.message!;
      }
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    }
  }

  Future<void> decrementCount(Label label) async {
    try {
      errorMessage.value = "";
      final labelRepository = super.repository as LabelRepository;
      await labelRepository.decrementCount(label.id!, -1);
      content.value = label.copyWith(count: label.count - 1);
    } on FirebaseException catch (ex) {
      if (ex.code == 'not-found') {
        final labelRepository = super.repository as LabelRepository;
        await labelRepository.edit([label]);
      }
      if (ex.message != null) {
        errorMessage.value = ex.message!;
      }
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    }
  }

  Future<void> generateLabel(ComponentType forType, String text) async {
    // Generate labels using Python backend.
    try {
      final labelRepository = super.repository as LabelRepository;
      final existingLabels = forType == ComponentType.note
          ? noteLabels
          : taskLabels;
      final labelNames = existingLabels.map((label) => label.name).toList();
      print("Existing Label Names: $labelNames");
      final moreLabelsToConsider = _defineDefaultLabels();
      print("More Label Names: $moreLabelsToConsider");
      final compiledList = [...labelNames, ...moreLabelsToConsider];
      final suggestedLabelNames = await labelRepository.generateLabel(
        text,
        compiledList,
      );
      print("Text: $text");
      print("Label Names: $suggestedLabelNames");

      // Check if label already exists.
      final exist = list.any(
        (label) => suggestedLabelNames.contains(label.name),
      );
      if (exist) {
        final labels = list
            .where((label) => suggestedLabelNames.contains(label.name))
            .toList();
        suggestedLabels.assignAll(labels);
      } else {
        // Not creating in Firebase Firestore yet, just return the new label.
        // Only create when user selects the label.
        final newLabels = suggestedLabelNames
            .map(
              (labelName) => Label(
                id: UniqueKey().toString(),
                name: labelName,
                type: forType,
                count: 0,
              ),
            )
            .toList();
        suggestedLabels.assignAll(newLabels);
      }
    } catch (ex) {
      errorMessage.value = ex.toString();
      debugPrint(ex.toString());
    }
  }

  // Generate a list of labels that AI can consider when generating label.
  List<String> _defineDefaultLabels() {
    final role = Get.find<RoleController>().getUserRole();
    if (role == null) return [];

    if (role == UserType.student) {
      return ["Math", "Biology", "History", "Computer Science", "Economics"];
    } else if (role == UserType.teacher) {
      return ["Grading", "Exam", "Lecture", "Assignment", "Revision"];
    } else if (role == UserType.worker) {
      return ["Meeting", "Action Item", "Project", "Decision", "Planning"];
    }
    return [];
  }

  void getNoteLabels() {
    errorMessage.value = "";
    final labelRepository = LabelRepository();
    _noteLabelSubscription?.cancel();
    _noteLabelSubscription = labelRepository.watchNoteLabels().listen((data) {
      noteLabels.assignAll(data);
    }, onError: (_) => errorMessage.value = "Note labels cannot be retrieved.");
  }

  void getTaskLabels() {
    errorMessage.value = "";
    final labelRepository = LabelRepository();
    _taskLabelSubscription?.cancel();
    _taskLabelSubscription = labelRepository.watchTaskLabels().listen((data) {
      taskLabels.assignAll(data);
    }, onError: (_) => errorMessage.value = "Task labels cannot be retrieved.");
  }
}
