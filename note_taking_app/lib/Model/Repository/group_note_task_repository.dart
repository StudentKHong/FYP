// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:note_taking_app/Model/Models/class_model.dart';
// import 'package:note_taking_app/Model/Models/shared_note_model.dart';
// import 'package:note_taking_app/Model/Models/shared_task_model.dart';
// import 'package:note_taking_app/Model/Repository/crud_repository.dart';
// import 'package:note_taking_app/Model/Repository/shared_note_repository.dart';
// import 'package:note_taking_app/Model/Repository/shared_task_repository.dart';

// class GroupNoteTaskRepository extends BaseRepository<GroupContent> {
//   final SharedNoteRepository _sharedNoteRepository;
//   final SharedTaskRepository _sharedTaskRepository;

//   // Provide dummy data to the parent class.
//   // To support GroupNoteTaskController for filtering.
//   GroupNoteTaskRepository({
//     required SharedNoteRepository sharedNoteRepository,
//     required SharedTaskRepository sharedTaskRepository,
//   }) : _sharedNoteRepository = sharedNoteRepository,
//        _sharedTaskRepository = sharedTaskRepository,
//        super(
//          collection: FirebaseFirestore.instance.collection(""),
//          fromFirestore: (document) => GroupContent.fromFirestore(document),
//        );

//   @override
//   Future<GroupContent> create(GroupContent entity) async {
//     GroupContent createdGroupContent = GroupContent();
//     if (!entity.isNull) {
//       if (entity.isSharedNoteNotNull) {
//         final sharedNote = await _sharedNoteRepository.create(
//           entity.sharedNote!,
//         );
//         createdGroupContent = createdGroupContent.copyWith(
//           sharedNote: sharedNote,
//         );
//       } else {
//         final sharedTask = await _sharedTaskRepository.create(
//           entity.sharedTask!,
//         );
//         createdGroupContent = createdGroupContent.copyWith(
//           sharedTask: sharedTask,
//         );
//       }
//     }
//     return createdGroupContent;
//   }

//   Future<void> createForGroups(
//     List<String> groupIds,
//     String groupType,
//     GroupContent itemToShare,
//   ) async {
//     // Fetch user id.
//     final user = _sharedNoteRepository.authController.user;
//     if (user == null || user.uid.isEmpty) {
//       throw Exception('Please login again to continue.');
//     }
//     final uid = _sharedNoteRepository.authController.user.value!.uid;

//     // Create shared note in selected groups.
//     final cleanedGroupType = groupType.toLowerCase().trim() == 'class'
//         ? 'classes'
//         : 'teams';
//     if (itemToShare.isNull){
//       return;
//     }
//     final collectionName = itemToShare.isSharedNoteNotNull ? 'shared_notes': 'shared_tasks';
    
//     final batch = FirebaseFirestore.instance.batch();
//     for (String groupId in groupIds) {
//       final collection = Repository.baseDocument(
//         uid,
//       ).collection(cleanedGroupType).doc(groupId).collection(collectionName);
//       final documentReference = collection.doc();
//       final noteMap = itemToShare.toMap();
//       noteMap.remove('id');
//       batch.set(documentReference, noteMap);
//     }

//     await batch.commit();
//   }

//   Future<List<GroupContent>> createMultiple(
//     List<GroupContent> groupContents,
//   ) async {
//     List<GroupContent> createdGroupContents = [];
//     final sharedNotes = groupContents
//         .where((content) => content.sharedNote != null)
//         .map((content) => content.sharedNote!)
//         .toList();
//     final sharedTasks = groupContents
//         .where((content) => content.sharedTask != null)
//         .map((content) => content.sharedTask!)
//         .toList();

//     if (sharedNotes.isNotEmpty) {
//       List<SharedNote> createdSharedNotes = await _sharedNoteRepository
//           .createMultiple(sharedNotes);
//       List<GroupContent> createdGroupContent = createdSharedNotes
//           .map((content) => GroupContent(sharedNote: content))
//           .toList();
//       createdGroupContents.addAll(createdGroupContent);
//     } else if (sharedTasks.isNotEmpty) {
//       List<SharedTask> createdSharedTasks = await _sharedTaskRepository
//           .createMultiple(sharedTasks);
//       List<GroupContent> createdGroupContent = createdSharedTasks
//           .map((content) => GroupContent(sharedTask: content))
//           .toList();
//       createdGroupContents.addAll(createdGroupContent);
//     }
//     return createdGroupContents;
//   }

//   @override
//   Future<List<GroupContent>> delete(List<String> componentIds) async {
//     return [];
//   }

//   Future<List<GroupContent>> deleteSharedComponents(
//     List<String> sharedNoteIds,
//     List<String> sharedTaskIds,
//   ) async {
//     final removedSharedNotes = await _sharedNoteRepository.delete(
//       sharedNoteIds,
//     );
//     final removedSharedTasks = await _sharedTaskRepository.delete(
//       sharedTaskIds,
//     );

//     final List<GroupContent> deletedSharedNotes = removedSharedNotes
//         .map((sharedNote) => GroupContent(sharedNote: sharedNote))
//         .toList();
//     final List<GroupContent> deletedSharedTasks = removedSharedTasks
//         .map((sharedTask) => GroupContent(sharedTask: sharedTask))
//         .toList();
//     return [...deletedSharedNotes, ...deletedSharedTasks];
//   }

//   Future<GroupContent> editData(GroupContent entity) async {
//     GroupContent updatedContent = GroupContent();
//     if (!entity.isNull) {
//       if (entity.isSharedNoteNotNull) {
//         final sharedNote = await _sharedNoteRepository.edit(
//           entity.sharedNote!.toMap(),
//         );
//         updatedContent = updatedContent.copyWith(sharedNote: sharedNote);
//       } else {
//         final sharedTask = await _sharedTaskRepository.edit(
//           entity.sharedTask!.toMap(),
//         );
//         updatedContent = updatedContent.copyWith(sharedTask: sharedTask);
//       }
//     }

//     return updatedContent;
//   }

//   @override
//   Future<List<GroupContent>> get() async {
//     final sharedNotes = await _sharedNoteRepository.get();
//     final sharedTasks = await _sharedTaskRepository.get();

//     final List<GroupContent> fetchedNotes = sharedNotes
//         .map((sharedNote) => GroupContent(sharedNote: sharedNote))
//         .toList();
//     final List<GroupContent> fetchedTasks = sharedTasks
//         .map((sharedTask) => GroupContent(sharedTask: sharedTask))
//         .toList();
//     return [...fetchedNotes, ...fetchedTasks];
//   }

//   @override
//   Future<int> getAllCount() async {
//     final noteQuerySnapshot = await _sharedNoteRepository.collection.get();
//     final taskQuerySnapshot = await _sharedTaskRepository.collection.get();
//     return noteQuerySnapshot.size + taskQuerySnapshot.size;
//   }

//   @override
//   Future<GroupContent> getById(String id) async {
//     return GroupContent();
//   }
// }
