import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Repository/class_repository.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';

class ClassController extends Controller<Class> {
  final AuthenticationController _authenticationController = Get.find<AuthenticationController>();
  final ClassRepository _classRepository = Get.find<ClassRepository>();

  ClassController()
    : super(repository: Get.find<ClassRepository>());

  @override
  ComponentFilter<Class>? createFilter() {
    return null;
  }

  Future<Class?> join(String code) async {
    try {
      errorMessage.value = "";
      _authenticationController.checkAuthentication();

      final data = await _classRepository.join(code);
      if (list.any((item) => item.id == data.id)) {
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
    }
  }

  Future<void> leave(String classId) async {
    try {
      errorMessage.value = "";
      _authenticationController.checkAuthentication();
      
      await _classRepository.leave(classId);
      list.removeWhere((item) => item.id == classId);
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    }
  }

  @override
  void getAllCount() {
    errorMessage.value = "";
    watchAllCountSubscription?.cancel();
    watchAllCountSubscription = repository.watchAllCount().listen((count) {
      totalCount.value = count;
    }, onError: (ex) => errorMessage.value = ex.toString());
  }

  @override
  Future<void> filter() async {
    return;
  }
}
