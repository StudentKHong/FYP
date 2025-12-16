// import 'package:note_taking_app/Controller/base_controller.dart';
// import 'package:note_taking_app/Model/Models/shared_task_model.dart';
// import 'package:note_taking_app/Model/Repository/shared_task_repository.dart';

// class SharedTaskController extends Controller<SharedTask> {
//   final String groupId;
//   final String groupType;

//   SharedTaskController({required this.groupId, required this.groupType})
//     : super(repository: SharedTaskRepository(groupId: groupId, groupType: groupType));

//   @override
//   ComponentFilter<SharedTask>? createFilter() {
//     return TaskFilter<SharedTask>() as ComponentFilter<SharedTask>;
//   }

//   Future<void> createMultiple(List<SharedTask> groupContents) async {
//     final List<SharedTask> createdGroupContents =
//         await (repository as SharedTaskRepository).createMultiple(groupContents);
//     list.addAll(createdGroupContents);
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