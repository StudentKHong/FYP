import 'dart:async';

import 'package:get/get.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Repository/note_repository.dart';

class NoteController extends Controller<Note> {
  final NoteRepository _noteRepository;
  final LabelController _labelController;

  StreamSubscription<List<Note>>? _watchByLabelSubscription;
  StreamSubscription<List<Note>>? _watchByGroupSubscription;

  RxString activeLabelId = ''.obs;

  NoteController()
    : _labelController = Get.find<LabelController>(),
      _noteRepository = Get.find<NoteRepository>(),
      super(repository: Get.find<NoteRepository>());

  @override
  void onClose() {
    _watchByLabelSubscription?.cancel();
    _watchByGroupSubscription?.cancel();
    super.onClose();
  }

  @override
  Future<Note?> create(Note entity) async {
    try {
      errorMessage.value = "";
      final newEntity = await repository.create(entity);

      if (entity.label != null && entity.label!.id != null) {
        _labelController.incrementCount(entity.label!);
      }
      // list.add(newEntity);

      // if (currentFilter.value == null || currentFilter.value!.isEmpty) {
      //   filteredList.add(newEntity);
      // } else {
      //   final filter = currentFilter.value!;

      //   if (filter.baseFilter(newEntity)) {
      //     filteredList.add(newEntity);
      //   }
      // }

      // pushItemToTop(entity: newEntity);

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
      final notes = list
          .where((note) => componentIds.contains(note.id))
          .toList();
      await repository.delete(componentIds);

      final labelsToUpdate = <String, Label>{};
      for (var note in notes) {
        final label = note.label;
        if (label != null && label.id != null) {
          labelsToUpdate[label.id!] = label;
        }
      }
      await Future.wait(
        labelsToUpdate.values.map(
          (label) => _labelController.decrementCount(label),
        ),
      );

      final noteIds = notes.map((task) => task.id).toList();
      list.removeWhere((item) => noteIds.contains(item.id));
      filteredList.removeWhere((item) => noteIds.contains(item.id));
    } catch (ex) {
      errorMessage.value = "Failed to delete notes.";
    }
  }

  @override
  Future<void> getAll() async {
    try {
      errorMessage.value = "";
      // Fetch notes.
      _watchByLabelSubscription?.cancel();
      activeLabelId.value = '';
      watchAllSubscription?.cancel();
      watchAllSubscription = _noteRepository.watchAll().listen((notes) {
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
      // Fetch notes.
      _watchByGroupSubscription?.cancel();
      _watchByGroupSubscription = _noteRepository
          .watchByGroup(groupId, groupType)
          .listen((notes) {
            list.assignAll(notes);
            if (activeLabelId.value.isEmpty) {
              filteredList.assignAll(notes);
            }
          });

      // Refilter if current filter exists.
      if (currentFilter.value != null &&
          currentFilter.value!.labelNames != null) {
        filter();
      }
    } catch (ex) {
      errorMessage.value = ex.toString();
    }
  }

  Future<void> getByLabel(String labelId) async {
    errorMessage.value = "";
    activeLabelId.value = labelId;
    watchAllSubscription?.cancel();
    _watchByLabelSubscription?.cancel();
    _watchByLabelSubscription = _noteRepository.watchByLabel(labelId).listen((
      notes,
    ) {
      filteredList.assignAll(notes);
    }, onError: (_) => errorMessage.value = "Failed to fetch notes.");
  }

  // Future<void> getRecent() async {
  //   try {
  //     errorMessage.value = "";
  //     final recentNotes = await _noteRepository.getRecentNotes();
  //     list.assignAll(recentNotes);
  //   } catch (ex) {
  //     errorMessage.value = "Something went wrong.";
  //   }
  // }

  Future<int?> getCountByLabel(String labelId) async {
    try {
      errorMessage.value = "";
      int? size;
      size = await _noteRepository.getNoteCount(labelId);
      return size;
    } catch (ex) {
      errorMessage.value = "Something went wrong";
      return null;
    }
  }

  Future<Label?> getLabel(String labelId) async {
    try {
      errorMessage.value = "";
      _labelController.getById(labelId);
      return _labelController.content.value;
    } catch (ex) {
      errorMessage.value = ex.toString();
      return null;
    }
  }

  Future<void> shareMultiple(
    List<Note> groupContents,
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
      final List<Note> createdGroupContents =
          await (repository as NoteRepository).shareMultiple(
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

  Future<void> editShared(Note note, String groupId, String groupType) async {
    try {
      errorMessage.value = "";
      final newEntity = await (repository as NoteRepository).editShared(
        note,
        groupId,
        groupType,
      );

      // Update reactive list and filteredList.
      pushItemToTop(entity: newEntity);
    } catch (ex) {
      errorMessage.value = ex.toString();
    }
  }

  Future<void> deleteShared(
    List<String> noteIds,
    String groupId,
    String groupType,
  ) async {
    try {
      errorMessage.value = "";
      // Delete selected shared notes.
      final notes = list.where((note) => noteIds.contains(note.id)).toList();
      await (repository as NoteRepository).deleteShared(
        noteIds,
        groupId,
        groupType,
      );

      // Update the count of the label.
      final labelsToUpdate = <String, Label>{};
      for (var note in notes) {
        final label = note.label;
        if (label != null && label.id != null) {
          labelsToUpdate[label.id!] = label;
        }
      }
      await Future.wait(
        labelsToUpdate.values.map(
          (label) => _labelController.decrementCount(label),
        ),
      );

      // Remove notes from lists.
      final deletedNoteIds = notes.map((task) => task.id).toList();
      list.removeWhere((item) => deletedNoteIds.contains(item.id));
      filteredList.removeWhere((item) => deletedNoteIds.contains(item.id));
    } catch (ex) {
      errorMessage.value = "Failed to delete notes.";
    }
  }

  Future<void> setLabelToNotes(String labelId, List<String> noteIds) async {
    try {
      errorMessage.value = "";

      // Set label.
      await _noteRepository.setLabel(labelId, noteIds);

      // Update lists with the latest label.
      for (var note in list) {
        if (noteIds.contains(note.id)) {
          note = note.copyWith(label: await getLabel(labelId));
        }
      }
      for (var note in filteredList) {
        if (noteIds.contains(note.id)) {
          note = note.copyWith(label: await getLabel(labelId));
        }
      }

      // Push the notes to the top due to update.
      for (var id in noteIds) {
        final note = list.firstWhere((note) => note.id == id);
        pushItemToTop(entity: note);
      }
    } catch (ex) {
      errorMessage.value = "Something went wrong";
    }
  }

  Future<void> togglePinStatus(Note note) async {
    final updatedItem = note.copyWith(
      isPinned: !note.isPinned,
      isArchived: !(note.isPinned) ? false : (note.isArchived ?? false),
    );
    await edit([updatedItem], pushToTop: false);
  }

  Future<void> toggleArchiveStatus(Note note) async {
    final updatedItem = note.copyWith(
      isArchived: !(note.isArchived ?? false),
      isPinned: !(note.isArchived ?? false) ? false : note.isPinned,
    );
    await edit([updatedItem], pushToTop: false);
  }

  void getArchived() {
    errorMessage.value = "";
    watchAllSubscription?.cancel();
    watchAllSubscription = (repository as NoteRepository)
        .watchArchived()
        .listen((notes) {
          filteredList.assignAll(notes);
        }, onError: (ex) {
          errorMessage.value = ex.toString();
        });
  }

  @override
  ComponentFilter<Note>? createFilter() {
    return NoteFilter();
  }
}
