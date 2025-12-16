import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
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

      final labelName = await labelRepository.generateLabel(text, labelNames);

      // Check if label already exists.
      final exist = list.any((label) => label.name == labelName);
      if (exist) {
        final label = list.firstWhere((label) => label.name == labelName);
        suggestedLabels.assignAll([label]);
      } else {
        // Not creating in Firebase Firestore yet, just return the new label.
        // Only create when user selects the label.
        final newLabel = Label(
          id: UniqueKey().toString(),
          name: labelName,
          type: forType,
          count: 0,
        );
        suggestedLabels.assignAll([newLabel]);
      }
    } catch (ex) {
      errorMessage.value = "Failed to generate label.";
    }
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
