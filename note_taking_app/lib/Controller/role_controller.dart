// ==================================================
// Program Name   : role_controller.dart
// Purpose        : Defines permission enums and role helpers
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 23 December 2025
// ==================================================

import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

enum PermissionType {
  viewClass,
  createClass,
  createShared,
  deleteShared,
  editShared,
  viewCreateTeam
}

class RoleController {
  final AuthenticationController _authController = Get.find<AuthenticationController>();

  final Map<PermissionType, List<UserType>> _permission= {
    PermissionType.viewClass: [UserType.student, UserType.teacher],
    PermissionType.createClass: [UserType.teacher],
    PermissionType.createShared: [UserType.teacher, UserType.worker],
    PermissionType.deleteShared: [UserType.teacher, UserType.worker],
    PermissionType.editShared: [UserType.teacher, UserType.worker],
    PermissionType.viewCreateTeam: [UserType.worker]
  };

  bool hasPermission(PermissionType feature){
    final userType = _permission[feature];
    if (userType == null) return false;
    return userType.contains(_authController.user.value?.userType);
  }

  UserType? getUserRole(){
    return _authController.user.value?.userType;
  }
}