// import 'package:note_taking_app/Controller/base_controller.dart';
// import 'package:note_taking_app/Model/Models/shared_note_model.dart';
// import 'package:note_taking_app/Model/Repository/shared_note_repository.dart';

// class SharedNoteController extends Controller<SharedNote> {
//   final String groupId;
//   final String groupType;

//   SharedNoteController({required this.groupId, required this.groupType})
//     : super(repository: SharedNoteRepository(groupId: groupId, groupType: groupType));

//   @override
//   ComponentFilter<SharedNote>? createFilter() {
//     return NoteFilter<SharedNote>() as ComponentFilter<SharedNote>;
//   }

//   Future<void> createMultiple(List<SharedNote> groupContents) async {
//     try {
//       final List<SharedNote> createdGroupContents =
//           await (repository as SharedNoteRepository).createMultiple(groupContents);
//       list.addAll(createdGroupContents);
//     } catch (ex) {
//       errorMessage.value = ex.toString();
//     }
//   }
// }

  // Future<void> createForGroups(
  //   SharedNote itemToShare,
  // ) async {
  //   await repository.createForGroups(
  //     groupIds,
  //     groupType,
  //     itemToShare,
  //   );
  // }

  // Future<void> deleteSharedNotes(
  //   List<String> sharedNoteIds,
  //   List<String> sharedTaskIds,
  // ) async {
  //   List<GroupContent> deletedContents = await _groupNoteTaskRepository
  //       .deleteSharedComponents(sharedNoteIds, sharedTaskIds);
  //   final deletedContentIds = deletedContents
  //       .map((content) => content.id)
  //       .toSet();
  //   list.removeWhere((content) => deletedContentIds.contains(content.id));
  // }

  // @override
  // Future<void> edit(GroupContent entity) async {
  //   try {
  //     errorMessage.value = "";
  //     await _groupNoteTaskRepository.editData(entity);
  //   } catch (e) {
  //     errorMessage.value = "Something went wrong";
  //   }