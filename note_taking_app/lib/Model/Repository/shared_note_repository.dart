// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:note_taking_app/Model/Models/shared_note_model.dart';
// import 'package:note_taking_app/Model/Repository/crud_repository.dart';

// class SharedNoteRepository extends BaseRepository<SharedNote> {
//   SharedNoteRepository({required String groupId, required String groupType})
//     : super(
//         collection: FirebaseFirestore.instance
//             .collection(
//               groupType.toLowerCase().trim() == 'class' ? 'classes' : 'teams',
//             )
//             .doc(groupId)
//             .collection('shared_notes'),
//         fromFirestore: (document) => SharedNote.fromFirestore(document),
//       );

//   Future<List<SharedNote>> createMultiple(List<SharedNote> sharedNotes) async {
//     final batch = FirebaseFirestore.instance.batch();
//     final List<SharedNote> createdNotes = [];

//     for (var note in sharedNotes) {
//       final noteWithId = note.copyWith(id: super.collection.doc().id);
//       final noteToCreate = noteWithId.toMap();
//       noteToCreate.remove('id');
//       batch.set(super.collection.doc(), noteToCreate);
//       createdNotes.add(noteWithId);
//     }
//     await batch.commit();
//     return createdNotes;
//   }

//   // @override
//   // Future<GroupContent> create(GroupContent content) async {
//   //   if (content.sharedNote != null) {
//   //     final originalData = content.sharedNote;
//   //     final data = content.sharedNote!.toMap();
//   //     data.remove('id');
//   //     final documentReference = await _noteCollection.add(data);
//   //     final updatedContent = content.copyWith(sharedNote: originalData!.copyWith(id: documentReference.id));
//   //     return updatedContent;
//   //   }
//   //   else if (content.sharedTask != null) {
//   //     final originalData = content.sharedTask;
//   //     final data = content.sharedTask!.toMap();
//   //     data.remove('id');
//   //     final documentReference = await _taskCollection.add(data);
//   //     final updatedContent = content.copyWith(sharedTask: originalData!.copyWith(id: documentReference.id));
//   //     return updatedContent;
//   //   }
//   //   return content;
//   // }

//   // @override
//   // Future<List<GroupContent>> delete(List<String> componentIds) {
//   //   throw UnimplementedError();
//   // }

//   // Future<List<GroupContent>> deleteLists(List<String> sharedNoteIds, List<String> sharedTaskIds) async {
//   //   final batch = FirebaseFirestore.instance.batch();
//   //   final List<GroupContent> deletedList = [];

//   //   for (final id in sharedNoteIds) {
//   //     final documentReference = _noteCollection.doc(id);
//   //     final documentSnapshot = await documentReference.get();
//   //     deletedList.add(SharedNote.fromFirestore(documentSnapshot));

//   //     batch.delete(documentReference);
//   //   }

//   //   await batch.commit();
//   //   return deletedList;
//   //   if (content.sharedNote != null) {
//   //     final originalData = content.sharedNote;
//   //     final data = content.sharedNote!.toMap();
//   //     data.remove('id');
//   //     final documentReference = await _noteCollection.add(data);
//   //     final updatedContent = content.copyWith(sharedNote: originalData!.copyWith(id: documentReference.id));
//   //     return updatedContent;
//   //   }
//   //   else if (content.sharedTask != null) {
//   //     final originalData = content.sharedTask;
//   //     final data = content.sharedTask!.toMap();
//   //     data.remove('id');
//   //     final documentReference = await _taskCollection.add(data);
//   //     final updatedContent = content.copyWith(sharedTask: originalData!.copyWith(id: documentReference.id));
//   //     return updatedContent;
//   //   }
//   //   return content;
//   // }

//   // @override
//   // Future<GroupContent> edit(GroupContent entity) {
//   //   throw UnimplementedError();
//   // }

//   // @override
//   // Future<List<GroupContent>> get() async {
//   //   final snQuerySnapshot = await _noteCollection
//   //       .where('groupType', isEqualTo: groupType)
//   //       .where('groupId', isEqualTo: groupId)
//   //       .get();
//   //   final stQuerySnapshot = await _taskCollection
//   //       .where('groupType', isEqualTo: groupType)
//   //       .where('groupId', isEqualTo: groupId)
//   //       .get();

//   //   final List<GroupContent> noteTaskList = [];
//   //   for (var document in snQuerySnapshot.docs) {
//   //     final note = Note.fromFirestore(document);
//   //     noteTaskList.add(GroupContent(note: note, task: null));
//   //   }

//   //   for (var document in stQuerySnapshot.docs) {
//   //     final task = Task.fromFirestore(document);
//   //     noteTaskList.add(GroupContent(note: null, task: task));
//   //   }

//   //   return noteTaskList;
//   // }

//   // @override
//   // Future<int> getAllCount() {
//   //   throw UnimplementedError();
//   // }

//   // @override
//   // Future<GroupContent> getById(String id) {
//   //   throw UnimplementedError();
//   // }
// }
