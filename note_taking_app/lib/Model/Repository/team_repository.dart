// ==================================================
// Program Name   : team_repository.dart
// Purpose        : Repository for team persistence and queries
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 21 December 2025
// ==================================================

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Model/Models/team_member_model.dart';
import 'package:note_taking_app/Model/Models/team_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class TeamRepository extends BaseRepository<Team> {
  final AuthenticationController _authController =
      Get.find<AuthenticationController>();
  TeamRepository()
    : super(
        collection: FirebaseFirestore.instance.collection("teams"),
        fromFirestore: (document) => Team.fromFirestore(document),
      );

  @override
  Future<Team> create(Team entity) async {
    // Generate 5-digit team code.
    const String charactersinCode = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final Random random = Random();
    String code = '';
    for (int i = 0; i < 5; i++) {
      code += charactersinCode[random.nextInt(charactersinCode.length)];
    }

    final documentReference = collection.doc();

    // Transform team object into map.
    entity = entity.copyWith(id: documentReference.id, code: code);
    final data = entity.toMap();
    data.remove('id');

    // Create team.
    documentReference.setOfflineSafe(data);

    // Add user as team member.
    _addMemberToTeam(teamId: documentReference.id, memberRole: TeamMemberRole.lead);

    return entity;
  }

  Future<void> _addMemberToTeam({required String teamId, required TeamMemberRole memberRole}) async {
    // Add user as member of the class.
    final teamMemberCollection = FirebaseFirestore.instance.collection(
      'team_members',
    );
    final teamMember = TeamMember(
      id: UniqueKey().toString(),
      teamId: teamId,
      userId: _authController.user.value!.uid,
      joinedAt: DateTime.now(),
      role: memberRole
    );
    final teamMap = teamMember.toMap();
    teamMap.remove('id');
    await teamMemberCollection.add(teamMap);
  }

  @override
  Stream<List<Team>> watchAll() {
    final uid = _authController.user.value?.uid;
    if (uid == null) return Stream.empty();

    // Gather all relevant class ids.
    final stream = FirebaseFirestore.instance
        .collection("team_members")
        .where('userId', isEqualTo: uid)
        .snapshots();

    return stream.asyncMap((snapshot) async {
      final List<String> teamIds = snapshot.docs
          .map((document) => document['teamId'] as String)
          .toSet()
          .toList();

      if (teamIds.isEmpty) {
        return <Team>[];
      }

      // Gather class details based on the class ids.
      final teamsQuerySnapshot = await collection
          .where(FieldPath.documentId, whereIn: teamIds)
          .get();
      List<Team> teams = teamsQuerySnapshot.docs
          .map((document) => Team.fromFirestore(document))
          .toList();

      return teams;
    });
  }

  @override
  Stream<int> watchAllCount() {
    final uid = _authController.user.value?.uid;
    if (uid == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection("team_members")
        .where('userId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.length);
  }

  Future<(Team data, bool alreadyJoined)> join(String code) async {
    // Verify the team code.
    final querySnapshot = await super.collection
        .where('code', isEqualTo: code)
        .get();
    final documentSnapshot = querySnapshot.docs.first;
    final teamId = documentSnapshot.id;
    if (!documentSnapshot.exists) {
      throw Exception("Team not found.");
    }

    // Check if user is already in the team.
    final memberQuerySnapshot = await FirebaseFirestore.instance
        .collection('team_members')
        .where('teamId', isEqualTo: teamId)
        .where('userId', isEqualTo: _authController.user.value?.uid)
        .limit(1)
        .get();
    if (memberQuerySnapshot.docs.isNotEmpty) {
      return (Team.fromFirestore(documentSnapshot), true);
    }

    // Add user as a team member.
    _addMemberToTeam(teamId: documentSnapshot.id, memberRole: TeamMemberRole.member);

    // Increment number of total members by 1.
    final documentReference = super.collection.doc(documentSnapshot.id);
    final RoleController roleController = Get.find<RoleController>();
    if (roleController.getUserRole() == UserType.worker) {
      documentReference.setOfflineSafe({"total": FieldValue.increment(1)});
    }
    return (Team.fromFirestore(documentSnapshot), false);
  }

  Future<void> leave(String teamId) async {
    // Remove user from a team.
    final querySnapshot = await FirebaseFirestore.instance
        .collection('team_members')
        .where('userId', isEqualTo: _authController.user.value?.uid)
        .where('teamId', isEqualTo: teamId)
        .limit(1)
        .get();
    final documentReference = querySnapshot.docs.first.reference;
    await documentReference.delete();

    // Decrement number of total members by 1.
    final memberDocumentReference = super.collection.doc(teamId);
    final RoleController roleController = Get.find<RoleController>();
    if (roleController.getUserRole() == UserType.worker) {
      memberDocumentReference.setOfflineSafe({"total": FieldValue.increment(-1)});
    }
  }
}
