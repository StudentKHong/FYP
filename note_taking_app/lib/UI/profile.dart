// ==================================================
// Program Name   : profile.dart
// Purpose        : Profile screen UI
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/confirmation_message.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthenticationController authController =
      Get.find<AuthenticationController>();
  final double profilePicRadius = 70.0;
  String? profileUrl;
  bool buttonsVisible = false;
  bool isNameEditable = false;
  bool isEmailEditable = false;
  bool isPasswordEditable = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = authController.user.value?.name ?? "";
    emailController.text = authController.user.value?.email ?? "";
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Widget _buildProfilePicture() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            setState(() {
              buttonsVisible = !buttonsVisible;
            });
          },
          child: SizedBox(
            width: profilePicRadius * 2,
            height: profilePicRadius * 2,
            child: CircleAvatar(
              backgroundImage: authController.user.value?.profileUrl != null
                  ? NetworkImage(authController.user.value!.profileUrl!)
                  : AssetImage('assets/profile_pic.jpg'),
            ),
          ),
        ),
        if (buttonsVisible) _buildProfilePictureButtons(),
      ],
    );
  }

  void _uploadImage(ImageSource source) async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? photo = await imagePicker.pickImage(source: source);
    try {
      if (photo != null) {
        final file = File(photo.path);
        final storageReference = FirebaseStorage.instance
            .ref()
            .child("profile_image")
            .child("${DateTime.now().millisecondsSinceEpoch}.jpg");
        await storageReference.putFile(file);

        // Get download url.
        final downloadUrl = await storageReference.getDownloadURL();
        await authController.updateProfile(profileUrl: downloadUrl);
      }
    } catch (ex) {
      CustomDialog.showError("Error", "Failed to update profile picture.");
    }
  }

  Widget _buildProfilePictureButtons() {
    return Container(
      width: profilePicRadius * 2,
      height: profilePicRadius * 2,
      decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () async {
              _uploadImage(ImageSource.camera);
            },
            icon: Icon(Icons.camera_alt, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              _uploadImage(ImageSource.gallery);
            },
            icon: Icon(Icons.photo, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    bool isCurrentHidden = true;
    bool isNewHidden = true;
    bool isConfirmHidden = true;

    bool validateInput() {
      if (newPasswordController.text != confirmPasswordController.text) {
        CustomDialog.showError(
          "Error",
          "New password and confirm password do not match.",
        );
        return false;
      }
      return true;
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Change Password"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    CustomTextField(
                      leadingIcon: Icons.password,
                      controller: currentPasswordController,
                      hintText: "Current Password",
                      isPassword: true,
                      isTextHidden: isCurrentHidden,
                      onToggleVisibility: () {
                        setState(() {
                          isCurrentHidden = !isCurrentHidden;
                        });
                      },
                      maxLines: 1,
                    ),
                    CustomTextField(
                      leadingIcon: Icons.password,
                      controller: newPasswordController,
                      hintText: "New Password",
                      isPassword: true,
                      isTextHidden: isNewHidden,
                      onToggleVisibility: () {
                        setState(() {
                          isNewHidden = !isNewHidden;
                        });
                      },
                      maxLines: 1,
                    ),
                    CustomTextField(
                      leadingIcon: Icons.password,
                      controller: confirmPasswordController,
                      hintText: "Confirm New Password",
                      isPassword: true,
                      isTextHidden: isConfirmHidden,
                      onToggleVisibility: () {
                        setState(() {
                          isConfirmHidden = !isConfirmHidden;
                        });
                      },
                      maxLines: 1,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!validateInput()) return;
                          await authController.updateProfile(
                            email: emailController.text.trim(),
                            password: confirmPasswordController.text.trim(),
                          );
                          if (authController.errorMessage != null &&
                              authController.errorMessage!.isNotEmpty) {
                            CustomDialog.showError(
                              "Error",
                              authController.errorMessage!,
                            );
                            return;
                          }
                          Get.back();
                          CustomDialog.showSuccess(
                            "Success",
                            "Successfully update password.",
                          );
                        },
                        child: Text(
                          "Save",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: Text(
                          "Cancel",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _buildReauthenticatePopUp() {
    final TextEditingController emailConfirmationController =
        TextEditingController();

    buildConfirmationMessage(
      context: context,
      title: 'Enter your credentials to delete account.',
      contentWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: emailConfirmationController,
            leadingIcon: Icons.email,
            hintText: 'Email',
            maxLines: 1,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      buttonDetails: [
        ButtonDetails(
          text: "Delete",
          buttonColor: Colors.red,
          onTapOption: () async {
            final currentEmail = emailController.text.trim();
            final confirmationEmail = emailConfirmationController.text.trim();
            if (currentEmail != confirmationEmail) {
              CustomDialog.showError(
                "Error",
                "Email does not match the current email.",
              );
              return;
            }

            await authController.delete(currentEmail);
            if (authController.errorMessage != null &&
                authController.errorMessage!.isNotEmpty) {
              CustomDialog.showError("Error", authController.errorMessage!);
              return;
            }
            Get.offAllNamed(Routes.login);
            CustomDialog.showSuccess("Success", "Successfully delete account.");
          },
        ),
        ButtonDetails(text: "Cancel", buttonColor: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleText: 'Profile'),
      endDrawer: const HamburgerMenu(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildProfilePicture(),
              CustomTextField(
                controller: nameController,
                title: 'Name',
                isEditing: isNameEditable,
                onEditToggle: () async {
                  if (isNameEditable) {
                    await authController.updateProfile(
                      name: nameController.text.trim(),
                    );
                  }
                  setState(() {
                    isNameEditable = !isNameEditable;
                  });
                },
                leadingIcon: Icons.person,
                hintText: "Name",
                maxLines: 1,
              ),
              CustomTextField(
                title: 'Email',
                controller: emailController,
                leadingIcon: Icons.email,
                isEditing: isEmailEditable,
                onEditToggle: () async {
                  if (isEmailEditable) {
                    await authController.updateProfile(
                      email: emailController.text.trim(),
                    );
                  }
                  setState(() {
                    isEmailEditable = !isEmailEditable;
                  });
                },
                hintText: "Email",
                maxLines: 1,
              ),
              CustomTextField(
                title: 'Password',
                leadingIcon: Icons.password,
                isEditing: isPasswordEditable,
                onEditToggle: () {
                  _showChangePasswordDialog();
                },
                hintText: "Password",
                maxLines: 1,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await authController.logout();
                    if (authController.errorMessage != null &&
                        authController.errorMessage!.isNotEmpty) {
                      CustomDialog.showError(
                        "Error",
                        authController.errorMessage!,
                      );
                      return;
                    }
                    Get.offAllNamed(Routes.login, arguments: null);
                    CustomDialog.showSuccess("Success", "Successfully logout.");
                  },
                  child: Text(
                    'Log Out',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                  ),
                  onPressed: () {
                    _buildReauthenticatePopUp();
                  },
                  child: Text(
                    'Delete Account',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
