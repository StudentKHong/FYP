import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Model/Models/team_model.dart';
import 'package:note_taking_app/Model/Repository/team_repository.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';

class TeamController extends Controller<Team> {
  final AuthenticationController _authenticationController = Get.find<AuthenticationController>();
  final TeamRepository _teamRepository = Get.find<TeamRepository>();

  TeamController()
    : super(repository: Get.find<TeamRepository>());

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthenticationController>();
    ever(authController.user, (user) {
      watchAllSubscription?.cancel();
      watchAllCountSubscription?.cancel();
      watchByIdSubscription?.cancel();
      
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
  ComponentFilter<Team>? createFilter() {
    return null;
  }

  Future<Team?> join(String code) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      _authenticationController.checkAuthentication();

      final data = await _teamRepository.join(code);
      if (list.any((item) => item.id == data.id)) {
        CustomDialog.showInfo("Info", "You are already in the team.");
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

  Future<void> leave(String teamId) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      _authenticationController.checkAuthentication();
      
      await _teamRepository.leave(teamId);
      list.removeWhere((item) => item.id == teamId);
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> filter() async {
    return;
  }
}
