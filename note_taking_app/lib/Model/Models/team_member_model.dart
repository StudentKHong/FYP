// ==================================================
// Program Name   : team_member_model.dart
// Purpose        : Data model for a member within a team
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================

import 'package:cloud_firestore/cloud_firestore.dart';

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
