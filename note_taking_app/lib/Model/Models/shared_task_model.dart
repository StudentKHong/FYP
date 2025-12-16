// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:note_taking_app/Model/Models/enumeration.dart';
// import 'package:note_taking_app/Model/Models/label_model.dart';
// import 'package:note_taking_app/Model/Models/task_model.dart';

// class SharedTask extends TaskLike {
//   @override
//   final String? id;
//   final String? taskTitle;
//   final String? taskDescription;
//   final DateTime? startDateTime;
//   final DateTime? endDateTime;
//   final List<String>? assignedTo;
//   final DateTime assignedAt;
//   final DateTime updatedAt;
//   final String? labelName;
//   final double completionPercentage;
//   final bool isPinned;
//   @override
//   final Status status;

//   SharedTask({
//     required this.id,
//     this.taskTitle,
//     this.taskDescription,
//     this.startDateTime,
//     this.endDateTime,
//     this.assignedTo,
//     required this.assignedAt,
//     required this.updatedAt,
//     this.labelName,
//     required this.completionPercentage,
//     required this.isPinned,
//     required this.status,
//   });

//   static SharedTask convertFromTask(Task task) {
//     return SharedTask(
//       id: UniqueKey().toString(),
//       taskTitle: task.title,
//       taskDescription: task.description,
//       startDateTime: task.startDateTime,
//       endDateTime: task.endDateTime,
//       assignedTo: null,
//       assignedAt: DateTime.now(),
//       updatedAt: DateTime.now(),
//       labelName: task.label?.name,
//       completionPercentage: 0,
//       isPinned: false,
//       status: Status.unknown,
//     );
//   }

//   factory SharedTask.fromFirestore(DocumentSnapshot documentSnapshot) {
//     final data = documentSnapshot.data() as Map<String, dynamic>;
//     return SharedTask(
//       id: documentSnapshot.id,
//       taskTitle: data['taskTitle'] as String?,
//       taskDescription: data['taskDescription'] as String?,
//       startDateTime: data['startDateTime'] as DateTime?,
//       endDateTime: data['endDateTime'] as DateTime?,
//       assignedTo: data['assignedTo'] as List<String>?,
//       assignedAt: (data['assignedAt'] as Timestamp).toDate(),
//       updatedAt: (data['updatedAt'] as Timestamp).toDate(),
//       labelName: data['labelName'] as String?,
//       completionPercentage: (data['completionPercentage'] as num).toDouble(),
//       isPinned: data['isPinned'] as bool,
//       status: Status.unknown,
//     );
//   }

//   @override
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'taskTitle': taskTitle,
//       'taskDescription': taskDescription,
//       'startDateTime': startDateTime,
//       'endDateTime': endDateTime,
//       'assignedTo': assignedTo,
//       'assignedAt': assignedAt,
//       'updatedAt': updatedAt,
//       'labelName': labelName,
//       'completionPercentage': completionPercentage,
//       'isPinned': isPinned,
//     };
//   }

//   SharedTask copyWith({
//     String? id,
//     String? taskTitle,
//     String? taskDescription,
//     DateTime? startDateTime,
//     DateTime? endDateTime,
//     List<String>? assignedTo,
//     String? labelName,
//     double? completionPercentage,
//     Status? status,
//     bool isAssigned = false,
//     bool isUpdated = true,
//     bool? isPinned,
//   }) {
//     return SharedTask(
//       id: id ?? this.id,
//       taskTitle: taskTitle ?? this.taskTitle,
//       taskDescription: taskDescription ?? this.taskDescription,
//       startDateTime: startDateTime ?? this.startDateTime,
//       endDateTime: endDateTime ?? this.endDateTime,
//       assignedTo: assignedTo ?? this.assignedTo,
//       assignedAt: isAssigned ? DateTime.now() : assignedAt,
//       updatedAt: isUpdated ? DateTime.now() : updatedAt,
//       labelName: labelName ?? this.labelName,
//       completionPercentage: completionPercentage ?? this.completionPercentage,
//       isPinned: isPinned ?? this.isPinned,
//       status: status ?? this.status,
//     );
//   }

//   @override
//   DateTime? get dateCreated => assignedAt;

//   @override
//   String? get description => taskDescription;

//   @override
//   String? get name => taskTitle;

//   @override
//   DateTime? get dateModified => updatedAt;

//   @override
//   Label? get label => Label(
//     id: UniqueKey().toString(),
//     name: labelName ?? '',
//     type: ComponentType.task,
//     count: 0,
//   );
// }

// class MemberTaskStatus {
//   final String? id;
//   final String memberId;
//   final Status taskStatus;
//   final DateTime statusUpdatedAt;

//   MemberTaskStatus({
//     required this.id,
//     required this.memberId,
//     required this.taskStatus,
//     required this.statusUpdatedAt,
//   });

//   factory MemberTaskStatus.fromFirestore(DocumentSnapshot documentSnapshot) {
//     final data = documentSnapshot.data() as Map<String, dynamic>;
//     return MemberTaskStatus(
//       id: documentSnapshot.id,
//       memberId: data['memberId'] as String,
//       taskStatus: Status.convertFromString(data['taskStatus'] as String),
//       statusUpdatedAt: (data['statusUpdatedAt'] as Timestamp).toDate(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'memberId': memberId,
//       'taskStatus': taskStatus,
//       'statusUpdatedAt': statusUpdatedAt,
//     };
//   }

//   MemberTaskStatus copyWith({
//     String? id,
//     String? memberId,
//     Status? taskStatus,
//     bool isUpdated = true,
//   }) {
//     return MemberTaskStatus(
//       id: id ?? this.id,
//       memberId: memberId ?? this.memberId,
//       taskStatus: taskStatus ?? this.taskStatus,
//       statusUpdatedAt: isUpdated ? DateTime.now() : statusUpdatedAt,
//     );
//   }
// }
