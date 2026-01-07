// ==================================================
// Program Name   : auth_controller.dart
// Purpose        : Handles authentication state and user session logic
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================

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
  late Rx<User?> firebaseUser;
  final Rx<AppUser?> user = Rx<AppUser?>(null);
  String? errorMessage;

  var isInitialized = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());

    if (firebaseUser.value != null) {
      _loadUserData();
    }

    FirebaseAuth.instance.authStateChanges().listen((user) {
      firebaseUser.value = user;
      if (user != null) {
        _onLogin();
      } else {
        this.user.value = null;
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authRepository.getUserData();
      if (userData != null) {
        user.value = userData;
      }
      _onLogin();
      isInitialized.value = true;
    } catch (ex) {
      errorMessage = "Unable to get user data.";
    }
  }

  void _registeredController<T>(T Function() creator) {
    if (Get.isRegistered<T>()) {
      Get.find<T>();
    } else {
      Get.lazyPut(creator, fenix: true);
    }
  }

  void _onLogin() {
    _registeredController(() => ThemeController());
    _registeredController(() => NoteController());
    _registeredController(() => TaskController());
    _registeredController(() => ClassController());
    _registeredController(() => TeamController());
    _registeredController(() => LabelController());
    _registeredController(() => SettingController());
    _registeredController(() => NotificationController());
    _registeredController(() => CountController());
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
      isLoading.value = true;
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginAnonymously() async {
    try {
      isLoading.value = true;
      errorMessage = "";
      AppUser? user = await _authRepository.loginAnonymously();
      this.user.value = user;

      // Navigate to the correct screen after successfull login.
      final previousScreen = Get.arguments;

      if (previousScreen != null && previousScreen is String) {
        await Future.delayed(Duration(milliseconds: 500));
        Get.offAllNamed(previousScreen);
      } else {
        await Future.delayed(Duration(seconds: 2));
        Get.offAllNamed(Routes.home);
      }
    } catch (ex) {
      errorMessage = ex.toString();
      // errorMessage = "Failed to login as guest.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> linkAnonymousAccountToEmail(
    String name,
    UserType userType,
    String email,
    String password,
  ) async {
    try {
      isLoading.value = true;
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      errorMessage = "";
      await _authRepository.signOut();
      user.value = null;
    } on FirebaseAuthException catch (ex) {
      errorMessage = ex.message;
    } catch (ex) {
      errorMessage = "Failed to logout.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(
    String name,
    UserType userType,
    String email,
    String password,
  ) async {
    try {
      isLoading.value = true;
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> delete(String email) async {
    try {
      isLoading.value = true;
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? password,
    String? profileUrl,
  }) async {
    try {
      isLoading.value = true;
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
    } finally {
      isLoading.value = false;
    }
  }
}
