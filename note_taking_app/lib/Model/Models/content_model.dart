// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:note_taking_app/Model/Models/enumeration.dart';
// import 'package:signature/signature.dart';

// class Content {
//   final String? id;
//   final ContentType type;
//   final String content;
//   final int position;
//   final bool hasChanged;

//   QuillController? textController;
//   FocusNode? focusNode;
//   SignatureController? drawingController;

//   Content({
//     required this.id,
//     required this.type,
//     required this.content,
//     required this.position,
//     this.hasChanged = false,
//     this.textController,
//     this.focusNode,
//     this.drawingController,
//   });

//   factory Content.fromFirestore(DocumentSnapshot documentSnapshot) {
//     final data = documentSnapshot.data() as Map<String, dynamic>;
//     return Content(
//       id: documentSnapshot.id,
//       type: data['type'] as ContentType,
//       content: data['content'] as String,
//       position: (data['position'] as num).toInt(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {'id': id, 'type': type, 'content': content, 'position': position};
//   }

//   Content copyWith({ContentType? type, String? content, int? position}) {
//     return Content(
//       id: id,
//       type: type ?? this.type,
//       content: content ?? this.content,
//       position: position ?? this.position,
//       hasChanged: true,
//     );
//   }
// }
