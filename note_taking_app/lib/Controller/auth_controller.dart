import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/user_model.dart';
import 'package:note_taking_app/Model/Repository/auth_repository.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';

class AuthenticationController {
  final AuthenticationRepository _authRepository =
      Get.find<AuthenticationRepository>();
  User? _user;
  String? errorMessage;

  AuthenticationController();

  User? get user {
    return _user;
  }

  void checkAuthentication() {
    if (user == null) {
      final previousScreen = Get.currentRoute;
      Get.offAllNamed(Routes.login, arguments: previousScreen);
      throw Exception("Please login again to continue.");
    }
  }

  Future<void> login(String email, String password) async {
    try {
      errorMessage = "";
      // Login user through Firebase Authentication.
      User? user = await _authRepository.login(email, password);
      _user = user;

      // Navigate to the correct screen after successfull login.
      final previousScreen = Get.arguments;

      if (previousScreen != null && previousScreen is String) {
        Get.offAllNamed(previousScreen);
      } else {
        Get.offAllNamed(Routes.home);
      }
    } on firebase_auth.FirebaseAuthException catch (ex) {
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
      User? user = await _authRepository.loginAnonymously();
      _user = user;

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
      _user = user;
      Get.offAllNamed(Routes.home);
    } catch (ex) {
      errorMessage = ex.toString();
      // errorMessage = "Failed to create account.";
    }
  }

  Future<void> logout() async {
    try {
      errorMessage = "";
      _authRepository.signOut();
      _user = null;
    } on firebase_auth.FirebaseAuthException catch (ex) {
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
    } on firebase_auth.FirebaseAuthException catch (ex) {
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
    } on firebase_auth.FirebaseAuthException catch (ex) {
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
      _user = user;
    } catch (ex) {
      if (ex.toString() == "") {
        errorMessage = "Failed to update profile.";
      }
      errorMessage = ex.toString();
    }
  }
}
