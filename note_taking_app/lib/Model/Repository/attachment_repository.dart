import 'package:note_taking_app/Model/Models/attachment_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class AttachmentRepository extends UserRepository<Attachment> {
  AttachmentRepository({required String componentId})
    : super(
        collectionBuilder: (uid) {
          return Repository.baseDocument(
            uid,
          ).collection('notes').doc(componentId).collection('attachments');
        },
        fromFirestore: (document) => Attachment.fromFirestore(document),
      );

  @override
  String? get orderByField => null;

  Stream<List<AttachmentComponent>> getList() {
    final uid = authController.user.value?.uid;
    if (uid == null) {
      return Stream.empty();
    }

    return watchAll().asyncMap((attachments) async {
      final List<AttachmentComponent> noteTask = [];
      for (var attachment in attachments) {
        if (attachment.attachmentType == ComponentType.note) {
          final noteCollection = Repository.baseDocument(
            uid,
          ).collection('notes');
          print(
            "DEBUG Path: Attempting to fetch note: ${noteCollection.doc(attachment.attachmentId).path}",
          );
          final note = await noteCollection.doc(attachment.attachmentId).get();
          noteTask.add(Note.fromFirestore(note));
        } else if (attachment.attachmentType == ComponentType.task) {
          final taskCollection = Repository.baseDocument(
            uid,
          ).collection('tasks');
          print(
            "DEBUG Path: Attempting to fetch note: ${taskCollection.doc(attachment.attachmentId).path}",
          );
          final task = await taskCollection.doc(attachment.attachmentId).get();
          noteTask.add(Task.fromFirestore(task));
        }
      }
      print("DEBUG Path: Final list size: ${noteTask.length}");
      return noteTask;
    });
  }

  Future<void> createMultiple(List<Attachment> attachments) async {
    for (var attachment in attachments) {
      final documentReference = super.collection.doc();
      final attachmentWithId = attachment.copyWith(
        id: super.collection.doc().id,
      );
      final attachmentToCreate = attachmentWithId.toMap();
      attachmentToCreate.remove('id');
      documentReference.setOfflineSafe(attachmentToCreate);
    }
  }
}
