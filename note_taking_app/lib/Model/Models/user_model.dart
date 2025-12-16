import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

class User {
  final String uid;
  final String? name;
  final String? email;
  final String? profileUrl;
  final UserType? userType;

  User({
    required this.uid,
    this.name,
    this.email,
    this.profileUrl,
    this.userType,
  });

  factory User.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return User(
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
}
