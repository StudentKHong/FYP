import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/login_details.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/drop_down_button.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isForExistingAccount;
  const RegistrationScreen({super.key, this.isForExistingAccount = false});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final List<FormDetails> registrationDetails = [
    FormDetails(
      leadingIcon: Icons.person_2_outlined,
      title: 'Name',
      controller: TextEditingController(),
      keyboardType: TextInputType.name,
      hintText: 'Enter your name...',
    ),
    FormDetails(
      leadingIcon: Icons.email,
      title: 'Email',
      controller: TextEditingController(),
      keyboardType: TextInputType.emailAddress,
      hintText: 'Enter your email...',
    ),
    FormDetails(
      leadingIcon: Icons.password_outlined,
      title: 'Password',
      controller: TextEditingController(),
      keyboardType: TextInputType.visiblePassword,
      hintText: 'Enter your password...',
      isPassword: true,
      isTextHidden: true,
    ),
  ];
  final List<String> selectedItem = ['None'];

  bool _validateInputs() {
    bool isValid = true;
    String? email = registrationDetails
        .firstWhereOrNull((detail) => detail.title.toLowerCase() == 'email')
        ?.controller
        .text
        .trim();
    if (selectedItem.contains('None')) {
      CustomDialog.showError('Register Failed', 'Invalid role.');
      isValid = false;
    }
    if (registrationDetails.any((detail) => detail.controller.text.isEmpty)) {
      CustomDialog.showError(
        'Register Failed',
        'Email, password and name cannot be empty.',
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book),
                    const SizedBox(width: 10),
                    Text(
                      widget.isForExistingAccount
                          ? 'Upgrade Account'
                          : 'Create Account',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.isForExistingAccount) ...[
                  Text(
                    'Welcome back, Guest. To save your progress permanently, please register a true account by filling the form below.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                ],
                ...registrationDetails.map(
                  (detail) => detail.title.toLowerCase() == 'name'
                      ? CustomTextField(
                          leadingIcon: detail.leadingIcon,
                          title: detail.title,
                          controller: detail.controller,
                          keyboardType: detail.keyboardType,
                          hintText: detail.hintText,
                          maxLines: 1,
                        )
                      : SizedBox.shrink(),
                ),
                CustomDropDownBox(
                  title: 'Role',
                  items: ['None', 'Student', 'Teacher', 'Worker'],
                  selectedValue: selectedItem.first,
                  onChanged: (value) {
                    setState(() {
                      selectedItem.first = value;
                    });
                  },
                ),
                ...registrationDetails.map(
                  (detail) => detail.title.toLowerCase() != 'name'
                      ? CustomTextField(
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
                        )
                      : SizedBox.shrink(),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_validateInputs()) {
                        final authController =
                            Get.find<AuthenticationController>();
                        Map<String, String> registrationData = {
                          for (var detail in registrationDetails)
                            detail.title.toLowerCase(): detail.controller.text
                                .trim(),
                        };

                        // Create a new account or renew an existing account.
                        if (!widget.isForExistingAccount) {
                          await authController.signUp(
                            registrationData['name']!,
                            UserType.convertRoleToUserType(selectedItem.first)!,
                            registrationData['email']!,
                            registrationData['password']!,
                          );
                        } else {
                          await authController.linkAnonymousAccountToEmail(
                            registrationData['name']!,
                            UserType.convertRoleToUserType(selectedItem.first)!,
                            registrationData['email']!,
                            registrationData['password']!,
                          );
                        }

                        if (authController.errorMessage == null || authController.errorMessage!.isNotEmpty) {
                          CustomDialog.showError(
                            'Register Failed',
                            authController.errorMessage!,
                          );
                        } else {
                          CustomDialog.showSuccess(
                            'Success',
                            'Successfully registered. You may login now.',
                          );
                          Get.offAllNamed(Routes.login);
                        }
                      }
                    },
                    child: Text('Create'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.offAllNamed(Routes.login),
                    child: Text('Cancel'),
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
