import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

enum TeamMemberRole {
  lead,
  member;

  static const Map<String, TeamMemberRole> _roleMap = {
    'lead': TeamMemberRole.lead,
    'member': TeamMemberRole.member,
  };

  static TeamMemberRole? convertRoleToMemberRole(String role) {
    final String cleanedRole = role.toLowerCase().trim();
    return _roleMap[cleanedRole];
  }

  // static TeamMemberRole? convertUserTypeToMemberRole(UserType userType) {
  //   final role = userType.name;
  //   return _roleMap[role];
  // }
}

class TeamMember {
  final String? id;
  final String teamId;
  final String userId;
  final DateTime joinedAt;
  final TeamMemberRole? role;

  TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.joinedAt,
    this.role,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return TeamMember(
      id: documentSnapshot.id,
      teamId: data['teamId'] as String,
      userId: data['userId'] as String,
      joinedAt: data['joinedAt'] as DateTime,
      role: TeamMemberRole.convertRoleToMemberRole(data['role'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'userId': userId,
      'joinedAt': joinedAt,
      'role': role!.name,
    };
  }
}
