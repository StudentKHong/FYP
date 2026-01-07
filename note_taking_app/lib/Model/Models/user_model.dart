// ==================================================
// Program Name   : user_model.dart
// Purpose        : Data model for application user profiles
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 21 December 2025
// ==================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? profileUrl;
  final UserType? userType;

  AppUser({
    required this.uid,
    this.name,
    this.email,
    this.profileUrl,
    this.userType,
  });

  factory AppUser.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return AppUser(
      uid: documentSnapshot.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      profileUrl: data['profileUrl'] as String?,
      userType: (data['userType'] as String?) != null
          ? UserType.convertRoleToUserType(data['userType'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileUrl': profileUrl,
      'userType': UserType.convertUserTypeToRole(userType),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? profileUrl,
    UserType? userType
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profileUrl: profileUrl ?? this.profileUrl,
      userType: userType ?? this.userType
    );
  }
}
