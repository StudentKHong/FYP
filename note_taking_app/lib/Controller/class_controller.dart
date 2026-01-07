// ==================================================
// Program Name   : class_controller.dart
// Purpose        : Manages class entities and related operations
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 23 December 2025
// ==================================================

import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Repository/class_repository.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';

class ClassController extends Controller<Class> {
  final AuthenticationController _authenticationController =
      Get.find<AuthenticationController>();
  final ClassRepository _classRepository = Get.find<ClassRepository>();

  ClassController() : super(repository: Get.find<ClassRepository>());

  @override
  void onInit() {
    super.onInit();

    final AuthenticationController authController =
        Get.find<AuthenticationController>();
    ever(authController.user, (user) {
      watchAllSubscription?.cancel();
      watchAllCountSubscription?.cancel();
      watchAllSubscription?.cancel();

      if (user != null) {
        getAll();
        getAllCount();
      } else {
        list.clear();
        filteredList.clear();
        totalCount.value = 0;
      }
    });
  }

  @override
  ComponentFilter<Class>? createFilter() {
    return null;
  }

  Future<Class?> join(String code) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      _authenticationController.checkAuthentication();

      final (data, alreadyJoined) = await _classRepository.join(code);
      if (alreadyJoined) {
        CustomDialog.showInfo("Info", "You are already in the class.");
        return data;
      }
      list.add(data);
      return data;
    } catch (ex) {
      if (ex.toString().isNotEmpty) {
        errorMessage.value = ex.toString();
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> leave(String classId) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      _authenticationController.checkAuthentication();

      await _classRepository.leave(classId);
      list.removeWhere((item) => item.id == classId);
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void getAllCount() {
    isLoading.value = true;
    errorMessage.value = "";
    watchAllCountSubscription?.cancel();
    watchAllCountSubscription = repository.watchAllCount().listen(
      (count) {
        totalCount.value = count;
        isLoading.value = false;
      },
      onError: (ex) {
        errorMessage.value = ex.toString();
        isLoading.value = false;
      },
    );
  }

  @override
  Future<void> filter() async {
    return;
  }
}
