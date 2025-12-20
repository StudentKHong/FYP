import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/count_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/Controller/setting_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/user_model.dart';
import 'package:note_taking_app/Model/Repository/auth_repository.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_theme.dart';

class AuthenticationController extends GetxController {
  final AuthenticationRepository _authRepository =
      Get.find<AuthenticationRepository>();
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<AppUser?> user = Rx<AppUser?>(null);
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      firebaseUser.value = user;

      if (user == null) {
        _onLogout();
      } else {
        _onLogin();
      }
    });
  }

  void _onLogin() {
    Get.find<ThemeController>();
    Get.find<NoteController>();
    Get.find<TaskController>();
    Get.find<ClassController>();
    Get.find<TeamController>();
    Get.find<LabelController>();
    Get.find<SettingController>();
    Get.find<NotificationController>();
    Get.find<CountController>();
  }

  void _onLogout() {
    Get.delete<CountController>(force: true);
    Get.delete<NoteController>(force: true);
    Get.delete<TaskController>(force: true);
    Get.delete<LabelController>(force: true);
    Get.delete<ClassController>(force: true);
    Get.delete<TeamController>(force: true);
    Get.delete<NotificationController>(force: true);
    Get.delete<SettingController>(force: true);
    Get.delete<ThemeController>(force: true);
  }

  void checkAuthentication() {
    if (user.value == null) {
      final previousScreen = Get.currentRoute;
      Get.offAllNamed(Routes.login, arguments: previousScreen);
      throw Exception("Please login again to continue.");
    }
  }

  Future<void> login(String email, String password) async {
    try {
      errorMessage = "";
      // Login user through Firebase Authentication.
      AppUser? user = await _authRepository.login(email, password);
      this.user.value = user;

      // Navigate to the correct screen after successfull login.
      final previousScreen = Get.arguments;

      if (previousScreen != null && previousScreen is String) {
        Get.offAllNamed(previousScreen);
      } else {
        Get.offAllNamed(Routes.home);
      }
    } on FirebaseAuthException catch (ex) {
      if (ex.code == 'user-not-found' ||
          ex.code == 'wrong-password' ||
          ex.code == 'invalid-credential') {
        errorMessage = "Incorrect email or/and password.";
      } else if (ex.code == 'email-already-in-use') {
        errorMessage = "Invalid email.";
      } else {
        errorMessage = ex.message;
      }
    } catch (ex) {
      errorMessage = "Failed to login.";
    }
  }

  Future<void> loginAnonymously() async {
    try {
      errorMessage = "";
      AppUser? user = await _authRepository.loginAnonymously();
      this.user.value = user;

      // Navigate to the correct screen after successfull login.
      final previousScreen = Get.arguments;

      if (previousScreen != null && previousScreen is String) {
        Get.offAllNamed(previousScreen);
      } else {
        Get.offAllNamed(Routes.home);
      }
    } catch (ex) {
      errorMessage = ex.toString();
      // errorMessage = "Failed to login as guest.";
    }
  }

  Future<void> linkAnonymousAccountToEmail(
    String name,
    UserType userType,
    String email,
    String password,
  ) async {
    try {
      errorMessage = "";
      final user = await _authRepository.linkAnonymousAccountToEmail(
        name,
        userType,
        email,
        password,
      );
      this.user.value = user;
      Get.offAllNamed(Routes.home);
    } catch (ex) {
      errorMessage = ex.toString();
      // errorMessage = "Failed to create account.";
    }
  }

  Future<void> logout() async {
    try {
      errorMessage = "";
      await _authRepository.signOut();
      user.value = null;
    } on FirebaseAuthException catch (ex) {
      errorMessage = ex.message;
    } catch (ex) {
      errorMessage = "Failed to logout.";
    }
  }

  Future<void> signUp(
    String name,
    UserType userType,
    String email,
    String password,
  ) async {
    try {
      errorMessage = "";
      await _authRepository.signUp(name, userType, email, password);
      errorMessage = null;
    } on FirebaseAuthException catch (ex) {
      if (ex.code == 'PASSWORD_DOES_NOT_MEET_REQUIREMENTS') {
        errorMessage = "Incorrect email or/and password.";
      } else if (ex.code == 'email-already-in-use') {
        errorMessage = "An account for the email already exists.";
      } else {
        errorMessage = ex.message;
      }
    } catch (ex) {
      errorMessage = ex.toString();
    }
  }

  Future<void> delete(String email) async {
    try {
      errorMessage = "";
      await _authRepository.deleteAccount(email);
    } on FirebaseAuthException catch (ex) {
      if (ex.code == 'wrong-password') {
        errorMessage = "Incorrect password.";
      }
      errorMessage = ex.toString();
      rethrow;
    } catch (ex) {
      errorMessage = "Failed to delete account.";
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? password,
    String? profileUrl,
  }) async {
    try {
      errorMessage = "";
      await _authRepository.updateProfile(name, email, password, profileUrl);

      if (firebaseUser.value != null && user.value != null) {
        user.value = user.value!.copyWith(
          name: name,
          email: email,
          profileUrl: profileUrl,
        );
        return;
      }
      errorMessage = "You are not logged in. Please re-login and try again.";
    } catch (ex) {
      if (ex.toString() == "") {
        errorMessage = "Failed to update profile.";
      }
      errorMessage = ex.toString();
    }
  }
}
