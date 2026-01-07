// ==================================================
// Program Name   : add_attachment.dart
// Purpose        : UI to add attachments to notes or tasks
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/attachment_controller.dart';
import 'package:note_taking_app/Model/Models/attachment_model.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/info_button.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/create_note.dart';

class AddAttachmentScreen extends StatefulWidget {
  const AddAttachmentScreen({super.key});

  @override
  State<AddAttachmentScreen> createState() => _AddAttachmentScreenState();
}

class _AddAttachmentScreenState extends State<AddAttachmentScreen> {
  ComponentType selectedType = ComponentType.note;
  late final AttachmentController attachmentController;
  late final String controllerTag;
  late final FilterableEntity? filterableEntity;

  @override
  void initState() {
    super.initState();
    final data = Get.arguments as Map<String, dynamic>;
    filterableEntity = data['entity'] as FilterableEntity?;
    attachmentController = data['controller'] as AttachmentController;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleText: 'Add Attachment'),
      endDrawer: const HamburgerMenu(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            if (filterableEntity != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Attached To: ${filterableEntity!.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 5),
                  CustomInfoButton(
                    infoDetails: [
                      Info(
                        text: filterableEntity!.name ?? "Unknown",
                        maxLines: 1,
                      ),
                      Info(
                        text: filterableEntity!.description ?? "Unknown",
                        maxLines: 1,
                      ),
                      Info(
                        text: filterableEntity!.dateCreated != null
                            ? "\n${DateFormat.yMd().format(filterableEntity!.dateCreated!)}"
                            : '',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ],
              ),
            Row(
              children: [
                Text('Type:', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 5),
                SizedBox(
                  width: 200,
                  child: AnimatedToggleSwitch.size(
                    current: selectedType,
                    values: [ComponentType.note, ComponentType.task],
                    indicatorSize: Size.fromWidth(100),
                    indicatorAnimationType: AnimationType.onSelected,
                    style: ToggleStyle(
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    ),
                    iconBuilder: (value) {
                      final isSelected = value == selectedType;
                      return Text(
                        value.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).textTheme.bodyMedium!.color
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Obtain created note details.
                  AttachmentComponent? result;
                  if (selectedType == ComponentType.note) {
                    result =
                        await Get.to(
                              NoteDetailScreen(
                                mode: Mode.create,
                                hideAttachmentButton: true,
                              ),
                            );
                  } else {
                    result =
                        await Get.toNamed(Routes.createTask)
                            as AttachmentComponent?;
                  }

                  // Create temporary attachment list if base entity not identified.
                  // Otherwise, create attachments in Firebase Firestore.
                  if (result != null) {
                    final attachment = Attachment(
                      id: UniqueKey().toString(),
                      attachmentType: selectedType,
                      attachmentId: result.id!,
                    );
                    final resolvedAttachment = ResolvedAttachment(
                      attachment: attachment,
                      attachmentComponent: result,
                    );

                    if (filterableEntity != null &&
                        filterableEntity?.id != null) {
                      await attachmentController.createMultiple([attachment]);
                    } else {
                      attachmentController.createTemporary([resolvedAttachment]);
                    }
                  }
                },
                child: Text("Create New"),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Create attachments based on the selected component type and
                  // existence of base entity.
                  if (selectedType == ComponentType.note) {
                    final selectedNotes =
                        await Get.toNamed(Routes.selectNote) as List<Note>;

                    List<Attachment> attachments = [];
                    final List<ResolvedAttachment> resolvedAttachments =
                        selectedNotes.map((note) {
                          final attachment = Attachment(
                            id: UniqueKey().toString(),
                            attachmentType: ComponentType.note,
                            attachmentId: note.id ?? "",
                          );
                          attachments.add(attachment);
                          return ResolvedAttachment(
                            attachment: attachment,
                            attachmentComponent: note,
                          );
                        }).toList();
                    if (filterableEntity?.id == null) {
                      attachmentController.createTemporary(resolvedAttachments);
                    } else {
                      await attachmentController.createMultiple(attachments);
                    }
                  } else if (selectedType == ComponentType.task) {
                    final selectedTasks =
                        await Get.toNamed(Routes.selectTask) as List<Task>;
                    List<Attachment> attachments = [];
                    final List<ResolvedAttachment> resolvedAttachments =
                        selectedTasks.map((task) {
                          final attachment = Attachment(
                            id: UniqueKey().toString(),
                            attachmentType: ComponentType.task,
                            attachmentId: task.id ?? "",
                          );
                          attachments.add(attachment);
                          return ResolvedAttachment(
                            attachment: attachment,
                            attachmentComponent: task,
                          );
                        }).toList();
                    if (filterableEntity?.id == null) {
                      attachmentController.createTemporary(resolvedAttachments);
                    } else {
                      await attachmentController.createMultiple(attachments);
                    }
                  } else {
                    CustomDialog.showError(
                      "Error",
                      "Please select an attachment type.",
                    );
                  }
                },
                child: Text("Select From Existing"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
