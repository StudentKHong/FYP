import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Models/class_model.dart';
import 'package:note_taking_app/Model/Models/group_model.dart';
import 'package:note_taking_app/Model/Models/team_model.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/confirmation_message.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';

class ClassTeamDetailsScreen extends StatefulWidget {
  final Group groupObject;
  const ClassTeamDetailsScreen({super.key, required this.groupObject});

  @override
  State<ClassTeamDetailsScreen> createState() => _ClassTeamDetailsScreenState();
}

class _ClassTeamDetailsScreenState extends State<ClassTeamDetailsScreen> {
  final ClassController classController = Get.find<ClassController>();
  final TeamController teamController = Get.find<TeamController>();
  final RoleController roleController = Get.find<RoleController>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool isEditable = false;

  late Group _groupObject;

  @override
  void initState() {
    super.initState();
    _groupObject = widget.groupObject;
    _titleController.text = _groupObject.name;
    _descriptionController.text = _groupObject.description ?? "";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupType = _groupObject.runtimeType.toString();

    return Scaffold(
      appBar: CustomAppBar(
        titleText: !isEditable ? _groupObject.name : null,
        titleWidget: isEditable
            ? TextField(
                style: TextStyle(color: Colors.black),
                controller: _titleController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  hintText: "$groupType Name",
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 3),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              )
            : null,
      ),
      endDrawer: const HamburgerMenu(),
      body:
          roleController.hasPermission(PermissionType.viewClass) ||
              roleController.hasPermission(PermissionType.viewCreateTeam)
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$groupType Description:',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (roleController.hasPermission(
                            PermissionType.createClass,
                          ))
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isEditable = !isEditable;
                                });
                              },
                              icon: Icon(
                                !isEditable ? Icons.edit : Icons.remove_red_eye,
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        onPressed: () async {
                          await buildConfirmationMessage(
                            context: context,
                            title: 'Leave $groupType Confirmation',
                            content:
                                'Are you sure you want to leave ${groupType.toLowerCase()}.',
                            buttonDetails: [
                              ButtonDetails(
                                text: 'Yes',
                                buttonColor: Colors.green,
                                onTapOption: () async {
                                  Get.back();
                                  await classController.leave(
                                    widget.groupObject.id!,
                                  );
                                  if (widget.groupObject.id != null) {
                                    await classController.leave(
                                      widget.groupObject.id!,
                                    );
                                  }

                                  if (classController
                                      .errorMessage
                                      .value
                                      .isNotEmpty) {
                                    CustomDialog.showError(
                                      "Error",
                                      classController.errorMessage.value,
                                    );
                                    return;
                                  }
                                  CustomDialog.showSuccess(
                                    "Success",
                                    "Successfully leave ${groupType.toLowerCase()}.",
                                  );
                                },
                              ),
                              ButtonDetails(
                                text: 'No',
                                buttonColor: Colors.red,
                              ),
                            ],
                          );
                        },
                        icon: Icon(Icons.exit_to_app, color: Colors.red),
                      ),
                    ],
                  ),
                  isEditable
                      ? CustomTextField(
                          controller: _descriptionController,
                          hintText: "Description",
                          maxLength: 500,
                          maxLines: 5,
                          isEditing: isEditable,
                        )
                      : Container(
                          padding: EdgeInsets.all(10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Text(
                            _descriptionController.text.isEmpty
                                ? 'No desrciption'
                                : _descriptionController.text,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: "$groupType Code: "),
                            TextSpan(
                              text: widget.groupObject.code.toString(),
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      IconButton(
                        onPressed: () {
                          if (_groupObject.code == null) return;
                          Clipboard.setData(
                            ClipboardData(text: _groupObject.code!),
                          );
                          CustomDialog.showSuccess(
                            "Copied",
                            "Code copied to clipboard!",
                          );
                        },
                        icon: Icon(
                          Icons.copy,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isEditable)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Group updatedGroup;
                          if (_groupObject is Class) {
                            final currentClass = _groupObject as Class;
                            final classToUpdate = currentClass.copyWith(
                              name: _titleController.text.trim(),
                              description: _descriptionController.text.trim(),
                            );
                            classController.edit([classToUpdate]);
                            updatedGroup = classToUpdate;
                          } else if (_groupObject is Team) {
                            final currentTeam = _groupObject as Team;
                            final teamToUpdate = currentTeam.copyWith(
                              name: _titleController.text.trim(),
                              description: _descriptionController.text.trim(),
                            );
                            teamController.edit([teamToUpdate]);
                            updatedGroup = teamToUpdate;
                          } else {
                            CustomDialog.showError("Error", "Unknown action.");
                            return;
                          }

                          final errorMessage =
                              classController.errorMessage.value.isEmpty
                              ? teamController.errorMessage.value
                              : classController.errorMessage.value;
                          if (errorMessage.isNotEmpty) {
                            CustomDialog.showError("Error", errorMessage);
                            return;
                          }
                          CustomDialog.showSuccess(
                            "Success",
                            "Successfully update ${groupType.toLowerCase()} details.",
                          );
                          setState(() {
                            isEditable = false;
                            _groupObject = updatedGroup;
                          });
                        },
                        child: Text(
                          "Save",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                ],
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
