import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

enum PermissionType {
  viewClass,
  createClass,
  createShared,
  editShared,
  viewCreateTeam
}

class RoleController {
  final AuthenticationController _authController = Get.find<AuthenticationController>();

  final Map<PermissionType, List<UserType>> _permission= {
    PermissionType.viewClass: [UserType.student, UserType.teacher],
    PermissionType.createClass: [UserType.teacher],
    PermissionType.createShared: [UserType.teacher, UserType.worker],
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