import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';

class Attachment implements BaseEntity {
  @override
  final String? id;
  final ComponentType? attachmentType;
  final String attachmentId;

  Attachment({
    required this.id,
    required this.attachmentType,
    required this.attachmentId,
  });

  factory Attachment.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return Attachment(
      id: documentSnapshot.id,
      attachmentType: ComponentType.convertFromString(
        data['attachmentType'] as String,
      ),
      attachmentId: data['attachmentId'] as String,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attachmentType': ComponentType.convertToString(attachmentType!),
      'attachmentId': attachmentId,
    };
  }

  Attachment copyWith({
    String? id,
    ComponentType? attachmentType,
    String? attachmentId,
  }) {
    return Attachment(
      id: id ?? this.id,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentId: attachmentId ?? this.attachmentId,
    );
  }

  @override
  String? get description => null;

  @override
  String? get name => null;

  @override
  DateTime? get dateCreated => null;

  @override
  Attachment copyWithId(String id) {
    return Attachment(
      id: id,
      attachmentType: attachmentType,
      attachmentId: attachmentId,
    );
  }
}

abstract class AttachmentComponent extends BaseEntity {
  String? get title;
  DateTime? get createdAt;
  DateTime? get viewedAt;
  DateTime? get updatedAt;
  bool? get isPinned;
  bool? get isArchived;
  Label? get label;

  // factory AttachmentComponent.fromSnapshot(DocumentSnapshot documentSnapshot, ComponentType type) {
  //   if (type == ComponentType.note){
  //     return Note.fromFirestore(documentSnapshot);
  //   } else if (type == ComponentType.task){
  //     return Task.fromFirestore(documentSnapshot);
  //   }
  //   throw Exception('Invalid attachment.');
  // }
}

class ResolvedAttachment {
  final Attachment attachment;
  final AttachmentComponent attachmentComponent;

  ResolvedAttachment({required this.attachment, required this.attachmentComponent});
}
