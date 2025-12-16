import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Models/group_model.dart';
import 'package:note_taking_app/Model/Models/team_model.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';

enum CreateGroupScreenType { cClass, tTeam }

class CreateGroupScreen extends StatelessWidget {
  final CreateGroupScreenType pageType;
  const CreateGroupScreen({super.key, required this.pageType});

  bool _verifyInputs(String groupName) {
    if (groupName.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AuthenticationController authController =
        Get.find<AuthenticationController>();
    final RoleController roleController = Get.find<RoleController>();
    final ClassController classController = Get.find<ClassController>();
    final TeamController teamController = Get.find<TeamController>();
    final TextEditingController groupNameController = TextEditingController();
    final TextEditingController groupLeadController = TextEditingController(
      text:
          "${authController.user?.name ?? "Unspecified Name"} (${authController.user?.uid})",
    );
    final TextEditingController descriptionController = TextEditingController();

    final bool isClass = pageType == CreateGroupScreenType.cClass;
    final String title = isClass ? "Create Class" : "Create Team";
    final String hintText = isClass ? "Class Name" : "Team Name";

    return Scaffold(
      appBar: CustomAppBar(titleText: title),
      endDrawer: const HamburgerMenu(),
      body:
          roleController.hasPermission(PermissionType.createClass) ||
              roleController.hasPermission(PermissionType.viewCreateTeam)
          ? SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: groupNameController,
                      leadingIcon: Icons.people,
                      hintText: hintText,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: groupLeadController,
                      leadingIcon: Icons.person,
                      isReadOnly: true,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: descriptionController,
                      hintText: "Description",
                      maxLength: 500,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Group? groupData;

                          if (!_verifyInputs(groupNameController.text)) {
                            CustomDialog.showError(
                              "Error",
                              "$hintText cannot be empty.",
                            );
                            return;
                          }
                          if (isClass) {
                            // Create class.
                            final classToCreate = Class(
                              id: UniqueKey().toString(),
                              code: UniqueKey().toString(),
                              name: groupNameController.text.trim(),
                              description: descriptionController.text.trim(),
                              createdBy: authController.user?.uid,
                              createdAt: DateTime.now(),
                              total: 1,
                              totalStudents: 0,
                              totalTeachers: 1,
                            );
                            final createdClass = await classController.create(
                              classToCreate,
                            );
                            groupData = createdClass;
                            final errorMessage =
                                classController.errorMessage.value;
                            if (errorMessage != "") {
                              CustomDialog.showError("Error", errorMessage);
                              classController.errorMessage.value = "";
                              return;
                            }
                          } else {
                            // Create team.
                            final teamToCreate = Team(
                              id: UniqueKey().toString(),
                              code: UniqueKey().toString(),
                              name: groupNameController.text.trim(),
                              description: descriptionController.text.trim(),
                              createdBy: authController.user?.uid,
                              createdAt: DateTime.now(),
                              total: 1,
                            );
                            final createdTeam = await teamController.create(
                              teamToCreate,
                            );
                            groupData = createdTeam;
                            final errorMessage =
                                classController.errorMessage.value;
                            if (errorMessage != "") {
                              CustomDialog.showError("Error", errorMessage);
                              teamController.errorMessage.value = "";
                              return;
                            }
                          }

                          Get.off(
                            CodeScreen(
                              groupLeadName:
                                  authController.user?.name ??
                                  "Unspecified Name",
                              groupObject: groupData,
                            ),
                          );
                        },
                        child: Text('Create'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Text(
                "Unauthorized access",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(color: Colors.red),
              ),
            ),
    );
  }
}

class CodeScreen extends StatelessWidget {
  final String groupLeadName;
  final Group? groupObject;
  const CodeScreen({
    super.key,
    required this.groupLeadName,
    required this.groupObject,
  });

  @override
  Widget build(BuildContext context) {
    final groupType = groupObject is Class
        ? 'Class'
        : groupObject is Team
        ? 'Team'
        : 'Group';

    final groupLead = groupObject is Class
        ? 'Teacher'
        : groupObject is Team
        ? 'Team Lead'
        : 'Group Lead';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (groupObject != null) {
        CustomDialog.showSuccess("Success", "Successfully added a new class.");
      } else {
        CustomDialog.showError("Error", "Failed to obtain created class data.");
      }
    });
    return Scaffold(
      appBar: CustomAppBar(titleText: "Create $groupType"),
      endDrawer: HamburgerMenu(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('Code', style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(groupObject?.code ?? ""),
                    ),
                    IconButton(
                      onPressed: () {
                        if (groupObject == null || groupObject?.code == null) {
                          CustomDialog.showError("Error", "Nothing to copy.");
                          return;
                        }
                        Clipboard.setData(
                          ClipboardData(text: groupObject!.code!),
                        );
                        CustomDialog.showSuccess(
                          "Copied",
                          "Code copied to clipboard!",
                        );
                      },
                      icon: Icon(Icons.copy),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '$groupType Name: ${groupObject?.name}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 5),
            Text(
              '$groupLead Name: $groupLeadName',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 5),
            Text(
              'Description: ${groupObject?.description}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
