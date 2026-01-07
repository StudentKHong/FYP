// ==================================================
// Program Name   : attachment_repository.dart
// Purpose        : Repository for attachment persistence and queries
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================
import 'package:get/get.dart';
import 'package:note_taking_app/Model/Models/attachment_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Model/Repository/note_repository.dart';
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

  Stream<List<ResolvedAttachment>> getList() {
    final uid = authController.user.value?.uid;
    if (uid == null) {
      return Stream.empty();
    }

    return watchAll().asyncMap((attachments) async {
      final List<ResolvedAttachment> noteTask = [];
      for (var attachment in attachments) {

        if (attachment.attachmentType == ComponentType.note) {
          final noteCollection = Repository.baseDocument(
            uid,
          ).collection('notes');
          final noteDocumentSnapshot = await noteCollection
              .doc(attachment.attachmentId)
              .get();

          Note note = Note.fromFirestore(noteDocumentSnapshot);
          AttachmentComponent attachmentContent = note;
          if (note.label?.id != null) {
            final labelDocumentSnapshot = await Repository.baseDocument(
              uid,
            ).collection('labels').doc(note.label!.id).get();

            final label = Label.fromFirestore(labelDocumentSnapshot);
            attachmentContent = note.copyWith(label: label);
          }
          noteTask.add(
            ResolvedAttachment(
              attachment: attachment,
              attachmentComponent: attachmentContent,
            ),
          );
        } else if (attachment.attachmentType == ComponentType.task) {
          final taskCollection = Repository.baseDocument(
            uid,
          ).collection('tasks');
          final taskDocumentSnapshot = await taskCollection
              .doc(attachment.attachmentId)
              .get();

          Task task = Task.fromFirestore(taskDocumentSnapshot);

          AttachmentComponent attachmentContent = task;
          if (task.label?.id != null) {
            final labelDocumentSnapshot = await Repository.baseDocument(
              uid,
            ).collection('labels').doc(task.label?.id).get();

            final label = Label.fromFirestore(labelDocumentSnapshot);
            attachmentContent = task.copyWith(label: label);
          }
          noteTask.add(
            ResolvedAttachment(
              attachment: attachment,
              attachmentComponent: attachmentContent,
            ),
          );
        }
      }
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
