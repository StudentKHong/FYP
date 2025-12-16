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
    // controllerTag = filterableEntity?.id ?? "temp_id";

    // if (!Get.isRegistered<AttachmentController>(tag: controllerTag)) {
    //   attachmentController = Get.put(
    //     AttachmentController(componentId: controllerTag),
    //     tag: controllerTag,
    //   );
    // } else {
    //   attachmentController = Get.find<AttachmentController>(
    //     tag: controllerTag,
    //   );
    // }
    // if (!Get.isRegistered<AttachmentRepository>(tag: controllerTag)) {
    //   Get.put(
    //     AttachmentRepository(componentId: controllerTag),
    //     tag: controllerTag,
    //   );
    // }
  }

  // @override
  // void dispose() {
  //   if (filterableEntity != null && filterableEntity!.id != null) {
  //     print(
  //       "Disposed Attachment Controller's Tag (In Add Attachment): $controllerTag",
  //     );
  //     Get.delete<AttachmentController>(tag: controllerTag);
  //     Get.delete<AttachmentRepository>(tag: controllerTag);
  //   }

  //   super.dispose();
  // }

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
                    style: ToggleStyle(indicatorColor: Colors.grey),
                    iconBuilder: (value) {
                      final isSelected = value == selectedType;
                      return Text(
                        value.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).textTheme.bodyMedium!.color
                              : Colors.grey,
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
                        await Get.to(NoteDetailScreen(mode: Mode.create, hideAttachmentButton: true,))
                            as AttachmentComponent?;
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

                    if (filterableEntity != null &&
                        filterableEntity?.id != null) {
                      await attachmentController.createMultiple([attachment]);
                    } else {
                      attachmentController.createTemporary([result]);
                    }
                    // if (attachmentController.errorMessage.value.isNotEmpty) {
                    //   CustomDialog.showError(
                    //     "Error",
                    //     attachmentController.errorMessage.value,
                    //   );
                    // } else {
                    //   CustomDialog.showSuccess(
                    //     "Success",
                    //     "Successfully create attachment"
                    //   );
                    // }
                  }
                },
                child: Text(
                  "Create New",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
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
                    final List<Attachment> attachments = selectedNotes
                        .map(
                          (note) => Attachment(
                            id: UniqueKey().toString(),
                            attachmentType: ComponentType.note,
                            attachmentId: note.id ?? "",
                          ),
                        )
                        .toList();
                    if (filterableEntity?.id == null) {
                      attachmentController.createTemporary(selectedNotes);
                    } else {
                      await attachmentController.createMultiple(attachments);
                    }
                  } else if (selectedType == ComponentType.task) {
                    final selectedTasks =
                        await Get.toNamed(Routes.selectTask) as List<Task>;
                    final List<Attachment> attachments = selectedTasks
                        .map(
                          (task) => Attachment(
                            id: UniqueKey().toString(),
                            attachmentType: ComponentType.task,
                            attachmentId: task.id ?? "",
                          ),
                        )
                        .toList();
                    if (filterableEntity?.id == null) {
                      attachmentController.createTemporary(selectedTasks);
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
                child: Text(
                  "Select From Existing",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
