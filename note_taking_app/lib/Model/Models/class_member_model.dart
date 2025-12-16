import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

enum ClassMemberRole {
  student,
  teacher;

  static const Map<String, ClassMemberRole> _roleMap = {
    'student': ClassMemberRole.student,
    'teacher': ClassMemberRole.teacher,
  };

  static ClassMemberRole? convertRoleToMemberRole(String role) {
    final String cleanedRole = role.toLowerCase().trim();
    return _roleMap[cleanedRole];
  }

  static ClassMemberRole? convertUserTypeToMemberRole(UserType userType) {
    final role = userType.name;
    return _roleMap[role];
  }
}

class ClassMember {
  final String? id;
  final String classId;
  final String userId;
  final DateTime joinedAt;
  final ClassMemberRole? role;

  ClassMember({
    required this.id,
    required this.classId,
    required this.userId,
    required this.joinedAt,
    this.role,
  });

  factory ClassMember.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return ClassMember(
      id: documentSnapshot.id,
      classId: data['classId'] as String,
      userId: data['userId'] as String,
      joinedAt: data['joinedAt'] as DateTime,
      role: ClassMemberRole.convertRoleToMemberRole(data['role'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'userId': userId,
      'joinedAt': joinedAt,
      'role': role!.name,
    };
  }
}
