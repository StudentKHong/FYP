// ==================================================
// Program Name   : attachment.dart
// Purpose        : UI component for displaying attachments
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/attachment_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/SharedComponents/loading_state.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';
import 'package:note_taking_app/UI/list_screen.dart';

class AttachmentScreen {
  static Future<Object?> displayAttachments({
    required BuildContext context,
    FilterableEntity? entity,
    required AttachmentController attachmentController,
  }) async {
    // Fetch data if base entity is not null.
    if (entity != null && entity.id != null) {
      try {
        attachmentController.getList();
        if (attachmentController.errorMessage.value.isNotEmpty) {
          CustomDialog.showError(
            "Error",
            attachmentController.errorMessage.value,
          );
          return null;
        }
      } catch (ex) {
        CustomDialog.showError("Error", "Failed: ${ex.toString()}");
        return null;
      }
    }

    if (!context.mounted) {
      CustomDialog.showError(
        "Error",
        "Failed to open panel. Please try again.",
      );
      return const SizedBox.shrink();
    }

    // Display attachment screen.
    final Future<Object?> dialog = showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: 'Attachment Panel',
      context: context,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        SelectionMode selectionMode = SelectionMode.none;
        final List<String> selectedAttachments = [];

        return Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              margin: EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(color: Colors.white),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: Icon(Icons.last_page),
                              color: Colors.black,
                            ),
                            if (selectedAttachments.isNotEmpty)
                              IconButton(
                                onPressed: () async {
                                  debugPrint("🗑️ Delete button pressed");
                                  debugPrint(
                                    "Selected attachments: $selectedAttachments",
                                  );

                                  if (selectedAttachments.isEmpty) {
                                    debugPrint(
                                      "⚠️ No attachments selected, aborting delete",
                                    );
                                    return;
                                  }
                                  await attachmentController.delete(
                                    selectedAttachments,
                                  );
                                  if (attachmentController
                                      .errorMessage
                                      .value
                                      .isNotEmpty) {
                                    CustomDialog.showError(
                                      "Error",
                                      attachmentController.errorMessage.value,
                                    );
                                  } else {
                                    CustomDialog.showSuccess(
                                      "Success",
                                      "Successfully delete attachments.",
                                    );
                                    setState(() {
                                      selectedAttachments.clear();
                                    });
                                  }
                                },
                                icon: Icon(Icons.delete),
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Obx(() {
                          if (attachmentController.isLoading.value) {
                            return const LoadingShimmer();
                          }

                          final listToShow =
                              (entity == null || entity.id == null)
                              ? attachmentController.temporaryList
                              : attachmentController.resolvedAttachments;

                          return Column(
                            children: [
                              listToShow.isEmpty
                                  ? Expanded(
                                      child: EmptyState(
                                        icon: Icons.attachment_outlined,
                                        message: "No attachments yet.",
                                        actionText: "Create an attachment.",
                                        action: () {
                                          Navigator.of(context).pop();
                                          Get.toNamed(
                                            Routes.addAttachment,
                                            arguments: {
                                              "controller":
                                                  attachmentController,
                                              "entity": entity,
                                            },
                                          );
                                        },
                                      ),
                                    )
                                  : Expanded(
                                      child: ListView.builder(
                                        padding: EdgeInsets.all(10),
                                        physics: ScrollPhysics(),
                                        itemCount: listToShow.length,
                                        itemBuilder: (context, index) {
                                          final resolvedAttachments =
                                              listToShow[index];
                                          final isSelected =
                                              resolvedAttachments
                                                      .attachment
                                                      .id !=
                                                  null
                                              ? selectedAttachments.contains(
                                                  resolvedAttachments
                                                      .attachment
                                                      .id,
                                                )
                                              : false;

                                          return Stack(
                                            children: [
                                              CustomExtendedCard(
                                                title: resolvedAttachments
                                                    .attachmentComponent
                                                    .name,
                                                content: [
                                                  resolvedAttachments
                                                          .attachmentComponent
                                                          .description ??
                                                      '',
                                                  resolvedAttachments
                                                              .attachmentComponent
                                                              .createdAt !=
                                                          null
                                                      ? DateFormat.yMd().format(
                                                          resolvedAttachments
                                                              .attachmentComponent
                                                              .createdAt!,
                                                        )
                                                      : '',
                                                ],
                                                otherDetails: [
                                                  resolvedAttachments
                                                                  .attachmentComponent
                                                                  .label !=
                                                              null &&
                                                          resolvedAttachments
                                                                  .attachmentComponent
                                                                  .label!
                                                                  .id !=
                                                              null
                                                      ? resolvedAttachments
                                                            .attachmentComponent
                                                            .label!
                                                            .name
                                                      : '',
                                                ],
                                                onTap:
                                                    selectionMode !=
                                                        SelectionMode.none
                                                    ? () {
                                                        setState(() {
                                                          if (isSelected) {
                                                            selectedAttachments
                                                                .remove(
                                                                  resolvedAttachments
                                                                      .attachment
                                                                      .id,
                                                                );
                                                            if (selectedAttachments
                                                                .isEmpty) {
                                                              selectionMode =
                                                                  SelectionMode
                                                                      .none;
                                                            }
                                                          } else {
                                                            if (resolvedAttachments
                                                                    .attachment
                                                                    .id ==
                                                                null) {
                                                              return;
                                                            }
                                                            selectedAttachments.add(
                                                              resolvedAttachments
                                                                  .attachment
                                                                  .id!,
                                                            );
                                                          }
                                                        });
                                                      }
                                                    : () {
                                                        if (resolvedAttachments
                                                                .attachmentComponent
                                                            is Note) {
                                                          final note =
                                                              resolvedAttachments
                                                                      .attachmentComponent
                                                                  as Note;
                                                          Get.to(
                                                            NoteDetailScreen(
                                                              mode: Mode.edit,
                                                              note: note,
                                                              initialLabel:
                                                                  note.label,
                                                              hideAttachmentButton:
                                                                  true,
                                                            ),
                                                            preventDuplicates:
                                                                false,
                                                          );
                                                          attachmentController
                                                              .getList();
                                                        } else if (resolvedAttachments
                                                                .attachmentComponent
                                                            is Task) {
                                                          final task =
                                                              resolvedAttachments
                                                                      .attachmentComponent
                                                                  as Task;
                                                          Get.to(
                                                            TaskDetailScreen(
                                                              mode: Mode.edit,
                                                              task: task,
                                                              initialLabel:
                                                                  task.label,
                                                            ),
                                                            preventDuplicates:
                                                                false,
                                                          );
                                                          attachmentController
                                                              .getList();
                                                        }
                                                      },
                                                onLongPress:
                                                    selectionMode ==
                                                        SelectionMode.none
                                                    ? () {
                                                        if (resolvedAttachments
                                                                .attachment
                                                                .id ==
                                                            null) {
                                                          return;
                                                        }
                                                        setState(() {
                                                          selectionMode =
                                                              SelectionMode
                                                                  .regular;
                                                          selectedAttachments.add(
                                                            resolvedAttachments
                                                                .attachment
                                                                .id!,
                                                          );
                                                        });
                                                      }
                                                    : null,
                                              ),
                                              if (selectionMode !=
                                                  SelectionMode.none)
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Checkbox(
                                                    value: isSelected,
                                                    onChanged: (_) {
                                                      setState(() {
                                                        if (isSelected) {
                                                          selectedAttachments
                                                              .remove(
                                                                resolvedAttachments
                                                                    .attachment
                                                                    .id,
                                                              );
                                                          if (selectedAttachments
                                                              .isEmpty) {
                                                            selectionMode ==
                                                                SelectionMode
                                                                    .none;
                                                          }
                                                        } else {
                                                          if (resolvedAttachments
                                                                  .attachment
                                                                  .id !=
                                                              null) {
                                                            selectedAttachments.add(
                                                              resolvedAttachments
                                                                  .attachment
                                                                  .id!,
                                                            );
                                                          }
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Get.toNamed(
                                        Routes.addAttachment,
                                        arguments: {
                                          "controller": attachmentController,
                                          "entity": entity,
                                        },
                                      );
                                    },
                                    child: Text('Add'),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
    return dialog;

    // return dialog.then((result) {
    //   Get.delete<AttachmentController>(tag: componentId);
    //   return result;
    // });
  }
}
