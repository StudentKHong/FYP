// ==================================================
// Program Name   : login.dart
// Purpose        : Login screen UI and form handling
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 24 December 2025
// ==================================================

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/setting_controller.dart';
import 'package:note_taking_app/Model/Models/login_details.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_theme.dart';
import 'package:note_taking_app/UI/SharedComponents/loading_state.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authController = Get.find<AuthenticationController>();
  final SettingController settingController = Get.find<SettingController>();
  final ThemeController themeController = Get.find<ThemeController>();

  final List<FormDetails> loginDetails = [
    FormDetails(
      leadingIcon: Icons.email_outlined,
      title: 'Email',
      controller: TextEditingController(),
      keyboardType: TextInputType.emailAddress,
    ),
    FormDetails(
      leadingIcon: Icons.password_outlined,
      title: 'Password',
      controller: TextEditingController(),
      keyboardType: TextInputType.visiblePassword,
      isPassword: true,
      isTextHidden: true,
    ),
  ];

  bool _validateInputs() {
    bool isValid = true;
    String? email = loginDetails
        .firstWhereOrNull((detail) => detail.title.toLowerCase() == 'email')
        ?.controller
        .text
        .trim();
    if (loginDetails.any((detail) => detail.controller.text.isEmpty)) {
      CustomDialog.showError(
        'Login Failed',
        'Email and password cannot be empty.',
      );
      isValid = false;
    }
    if (email != null && !EmailValidator.validate(email)) {
      CustomDialog.showError('Login Failed', 'Invalid email.');
      isValid = false;
    }
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
                Center(
                  child: Text(
                    "NoteTask",
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ...loginDetails.map((detail) {
                  return CustomTextField(
                    leadingIcon: detail.leadingIcon,
                    title: detail.title,
                    controller: detail.controller,
                    keyboardType: detail.keyboardType,
                    hintText: detail.hintText,
                    maxLines: 1,
                    isPassword: detail.isPassword,
                    isTextHidden: detail.isTextHidden,
                    onToggleVisibility: () {
                      setState(() {
                        detail.isTextHidden = !detail.isTextHidden;
                      });
                    },
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: authController.isLoading.value
                          ? null
                          : () async {
                              if (_validateInputs()) {
                                Map<String, String> loginData = {
                                  for (var detail in loginDetails)
                                    detail.title.toLowerCase(): detail
                                        .controller
                                        .text
                                        .trim(),
                                };

                                await authController.login(
                                  loginData['email']!,
                                  loginData['password']!,
                                );

                                if (authController.errorMessage != null &&
                                    authController.errorMessage!.isNotEmpty) {
                                  CustomDialog.showError(
                                    'Login Failed',
                                    authController.errorMessage!,
                                  );
                                } else {
                                  CustomDialog.showSuccess(
                                    'Success',
                                    'Successfully login.',
                                  );
                                  await settingController.get();
                                  if (settingController.currentSettings.value !=
                                      null) {
                                    themeController.updateTheme(
                                      settingController
                                          .currentSettings
                                          .value!
                                          .darkMode,
                                    );
                                  }
                                }
                              }
                            },
                      child: authController.isLoading.value
                          ? LoadingIndicator(
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          : Text(
                              'Login',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.toNamed(Routes.register),
                    child: Text(
                      'Register',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    await authController.loginAnonymously();

                    if (authController.errorMessage != null &&
                        authController.errorMessage!.isNotEmpty) {
                      CustomDialog.showError(
                        'Login Failed',
                        authController.errorMessage!,
                      );
                    } else {
                      CustomDialog.showSuccess(
                        'Success',
                        'Successfully login as Guest.',
                      );
                      await settingController.get();
                      if (settingController.currentSettings.value != null) {
                        themeController.updateTheme(
                          settingController.currentSettings.value!.darkMode,
                        );
                      }
                    }
                  },
                  child: Center(
                    child: Text(
                      'Or login as Guest',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
