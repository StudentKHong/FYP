import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/note_task.dart';

// Assuming this page is only for Note and Task.
class CreateLabelScreen<T extends BaseEntity> extends StatefulWidget {
  final ComponentType forComponentType;
  final Controller<T> controller;
  const CreateLabelScreen({
    super.key,
    required this.forComponentType,
    required this.controller,
  });

  @override
  State<CreateLabelScreen> createState() => _CreateLabelScreenState<T>();
}

class _CreateLabelScreenState<T extends BaseEntity>
    extends State<CreateLabelScreen<T>> {
  final labelController = Get.find<LabelController>();
  final TextEditingController textEditingController = TextEditingController();
  Label? createdLabel;

  @override
  Widget build(BuildContext context) {
    final isForNotes = widget.forComponentType == ComponentType.note;

    bool verifyLabel() {
      if (textEditingController.text.trim().isEmpty) {
        CustomDialog.showError("Error", "Please enter a label.");
        return false;
      }
      return true;
    }

    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'Create Label',
        subtitle: 'For ${widget.forComponentType.name}',
      ),
      endDrawer: const HamburgerMenu(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextField(
                maxLength: 30,
                maxLines: 1,
                controller: textEditingController,
                hintText: "Enter a label...",
                isReadOnly: createdLabel != null,
              ),
              const SizedBox(height: 15),
              if (createdLabel == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!verifyLabel()) return;

                      Label label = Label(
                        id: UniqueKey().toString(),
                        name: textEditingController.text.trim(),
                        type: widget.forComponentType,
                        count: 0,
                      );

                      final newLabel = await labelController.create(label);
                      setState(() {
                        createdLabel = newLabel;
                        if (newLabel != null) {
                          textEditingController.text = newLabel.name;
                        }
                      });

                      if (labelController.errorMessage.value.isNotEmpty) {
                        CustomDialog.showError(
                          "Error",
                          labelController.errorMessage.value,
                        );
                      } else {
                        CustomDialog.showSuccess(
                          "Success",
                          "Successfully create label.",
                        );
                      }
                    },
                    child: Text("Create"),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final label = createdLabel!.copyWith(
                        id: createdLabel!.id,
                      );

                      final selectedItems = await Get.to(
                        ListScreen(
                          title: isForNotes ? 'Select Notes' : 'Select Tasks',
                          description: 'To assign with label: ${label.name}',
                          pageType: isForNotes
                              ? ListScreenType.notes
                              : ListScreenType.tasks,
                          initialSelectionMode: SelectionMode.other,
                          controller: isForNotes
                              ? widget.controller as Controller<Note>
                              : widget.controller as Controller<Task>,
                        ),
                      );
                      if (selectedItems != null) {
                        final selectedItemIds =
                            (selectedItems as List<BaseEntity>)
                                .map((item) => item.id)
                                .whereType<String>()
                                .toList();
                        if (isForNotes) {
                          if (label.id != null) {
                            await (widget.controller as NoteController)
                                .setLabelToNotes(label.id!, selectedItemIds);
                          }
                        } else {
                          if (label.id != null) {
                            await (widget.controller as TaskController)
                                .setLabelToTasks(label.id!, selectedItemIds);
                          }
                        }
                        if (widget.controller.errorMessage.value.isNotEmpty) {
                          CustomDialog.showError(
                            "Error",
                            widget.controller.errorMessage.value,
                          );
                        } else {
                          CustomDialog.showSuccess(
                            "Success",
                            "Successfully assign label to item(s).",
                          );
                        }
                      } else {
                        CustomDialog.showInfo(
                          "Info",
                          "No items to assign with label.",
                        );
                      }
                    },
                    child: Text("Add Existing ${isForNotes ? 'Notes': 'Tasks'}"),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      print("Created Label: $createdLabel");
                      // if (!verifyLabel()) return;

                      // final createdLabel = await labelController.create(
                      //   Label(
                      //     id: UniqueKey().toString(),
                      //     name: textEditingController.text,
                      //     type: widget.forComponentType,
                      //     count: 0,
                      //   ),
                      // );
                      // if (labelController.errorMessage.value.isNotEmpty) {
                      //   CustomDialog.showError(
                      //     "Error",
                      //     labelController.errorMessage.value,
                      //   );
                      // } else {
                      //   CustomDialog.showSuccess(
                      //     "Success",
                      //     "Successfully create label.",
                      //   );
                      // }

                      Get.to(
                        NoteDetailScreen(
                          mode: Mode.create,
                          initialLabel: createdLabel,
                          isLabelReadOnly: true,
                        ),
                      );
                    },
                    child: Text("Add a New ${isForNotes ? 'Note': 'Task'}"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
