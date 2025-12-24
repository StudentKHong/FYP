import 'dart:async';

import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/user_model.dart';
import 'package:note_taking_app/Model/Repository/note_repository.dart';

class NoteController extends Controller<Note> {
  final NoteRepository _noteRepository;
  final LabelController _labelController;

  StreamSubscription<List<Note>>? _watchByLabelSubscription;
  StreamSubscription<List<Note>>? _watchByGroupSubscription;
  StreamSubscription<List<Note>>? _watchArchivedSubscription;

  RxString activeLabelId = ''.obs;

  NoteController()
    : _labelController = Get.find<LabelController>(),
      _noteRepository = Get.find<NoteRepository>(),
      super(repository: Get.find<NoteRepository>());

  @override
  void onInit() {
    super.onInit();

    final AuthenticationController authController =
        Get.find<AuthenticationController>();
    ever(authController.user, (AppUser? user) {
      watchAllSubscription?.cancel();
      watchAllCountSubscription?.cancel();
      watchByIdSubscription?.cancel();
      _watchByLabelSubscription?.cancel();
      _watchByGroupSubscription?.cancel();
      _watchArchivedSubscription?.cancel();

      if (user != null) {
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
    required Note entity,
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
  Future<Note?> create(Note entity) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      String? createdLabelId;
      if (entity.label != null && entity.label!.id != null) {
        final existingLabels = _labelController.noteLabels;
        if (existingLabels.any((label) => label.name == entity.label?.name)) {
          _labelController.incrementCount(entity.label!);
          createdLabelId = entity.label!.id;
        } else {
          final createdLabel = await _labelController.create(entity.label!);
          createdLabelId = createdLabel?.id;
        }
      }

      final labelWithId = entity.label?.copyWithId(createdLabelId);
      final entityToCreate = entity.copyWith(label: labelWithId);
      final newEntity = await repository.create(entityToCreate);

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
      filteredList.refresh();

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
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> getAll() async {
    // try {
    isLoading.value = true;
    errorMessage.value = "";
    // Fetch notes.
    _watchByLabelSubscription?.cancel();
    activeLabelId.value = '';
    watchAllSubscription?.cancel();

    watchAllSubscription = _noteRepository.watchAll().listen(
      (notes) {
        final labels = _labelController.noteLabels;

        final notesWithLabels = notes.map((note) {
          final labelId = note.label?.id;
          return labelId != null && labels.any((label) => label.id == labelId)
              ? note.copyWith(
                  label: labels.firstWhere((label) => label.id == labelId),
                )
              : note;
        }).toList();

        list.assignAll(notesWithLabels);
        filteredList.assignAll(notesWithLabels);
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
    // print('Initial List: ${list.map((e) => '${e.id}:${e.isPinned}').toList()}');
    // print(
    //   'Initial Filtered List: ${filteredList.map((e) => '${e.id}:${e.isPinned}').toList()}',
    // );
    // } catch (ex) {
    //   errorMessage.value = "Something went wrong.";
    // } finally {
    //   isLoading.value = false;
    // }
  }

  Future<void> getByGroup(String groupId, String groupType) async {
    try {
      isLoading.value = true;
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
    } finally {
      isLoading.value = false;
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

  Future<int?> getCountByLabel(String labelId) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      int? size;
      size = await _noteRepository.getNoteCount(labelId);
      return size;
    } catch (ex) {
      errorMessage.value = "Something went wrong";
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareMultiple(
    List<Note> groupContents,
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
      // final List<Note> createdGroupContents =
      await (repository as NoteRepository).shareMultiple(
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

  Future<void> editShared(Note note, String groupId, String groupType) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final newEntity = await (repository as NoteRepository).editShared(
        note,
        groupId,
        groupType,
      );

      // Update reactive list and filteredList.
      pushItemToTop(entity: newEntity, forList: true, forFilteredList: true);
    } catch (ex) {
      errorMessage.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteShared(
    List<String> noteIds,
    String groupId,
    String groupType,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      // Delete selected shared notes.
      final notes = list.where((note) => noteIds.contains(note.id)).toList();
      await (repository as NoteRepository).deleteShared(
        noteIds,
        groupId,
        groupType,
      );

      // // Update the count of the label.
      // final labelsToUpdate = <String, Label>{};
      // for (var note in notes) {
      //   final label = note.label;
      //   if (label != null && label.id != null) {
      //     labelsToUpdate[label.id!] = label;
      //   }
      // }
      // await Future.wait(
      //   labelsToUpdate.values.map(
      //     (label) => _labelController.decrementCount(label),
      //   ),
      // );

      // Remove notes from lists.
      final deletedNoteIds = notes.map((task) => task.id).toList();
      list.removeWhere((item) => deletedNoteIds.contains(item.id));
      filteredList.removeWhere((item) => deletedNoteIds.contains(item.id));
    } catch (ex) {
      errorMessage.value = "Failed to delete notes.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setLabelToNotes(String labelId, List<String> noteIds) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      // Set label.
      await _noteRepository.setLabel(labelId, noteIds);
      _labelController.getById(labelId);

      // Update lists with the latest label.
      for (var note in list) {
        if (noteIds.contains(note.id)) {
          note = note.copyWith(label: _labelController.content.value);
        }
      }
      for (var note in filteredList) {
        if (noteIds.contains(note.id)) {
          note = note.copyWith(label: _labelController.content.value);
        }
      }

      // Push the notes to the top due to update.
      for (var id in noteIds) {
        final note = list.firstWhere((note) => note.id == id);
        pushItemToTop(entity: note, forList: true, forFilteredList: true);
      }
    } catch (ex) {
      errorMessage.value = "Something went wrong";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeLabelFromNotes(String labelId) async {
    final notesToUpdate = list.map((item) {
      if (item.label?.id == labelId) {
        return item.copyWith(label: null, replaceLabel: true);
      }
      return item;
    }).toList();
    await edit(notesToUpdate, pushToTop: false);
  }

  Future<void> togglePinStatus(Note note) async {
    final updatedItem = note.copyWith(
      isPinned: !note.isPinned,
      isArchived: !(note.isPinned) ? false : (note.isArchived ?? false),
    );
    _sortLists(list: filteredList);
    _sortLists(list: list);
    await edit([updatedItem], pushToTop: false);
  }

  // Sort Notes and Tasks only.
  void _sortLists({required List<Note> list}) {
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

  Future<void> toggleArchiveStatus(Note note) async {
    final updatedItem = note.copyWith(
      isArchived: !(note.isArchived ?? false),
      isPinned: !(note.isArchived ?? false) ? false : note.isPinned,
    );
    await edit([updatedItem], pushToTop: false);
  }

  Future<void> getArchived() async {
    isLoading.value = true;
    errorMessage.value = "";
    _watchArchivedSubscription?.cancel();
    _watchArchivedSubscription = (repository as NoteRepository)
        .watchArchived()
        .listen(
          (notes) {
            final labels = _labelController.noteLabels;
            final notesWithLabels = notes.map((note) {
              final labelId = note.label?.id;
              return labelId != null &&
                      labels.any((label) => label.id == labelId)
                  ? note.copyWith(
                      label: labels.firstWhere((label) => label.id == labelId),
                    )
                  : note;
            }).toList();

            filteredList.assignAll(notesWithLabels);
            isLoading.value = false;
          },
          onError: (ex) {
            errorMessage.value = ex.toString();
            isLoading.value = false;
          },
        );
  }

  @override
  ComponentFilter<Note>? createFilter() {
    return NoteFilter();
  }
}
