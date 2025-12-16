import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/attachment_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';

class AttachmentScreen {
  static Future<Object?> displayAttachments({
    required BuildContext context,
    FilterableEntity? entity,
    required AttachmentController attachmentController,
  }) async {
    // Initialize controller.
    // final componentId = entity?.id ?? "temp_${UniqueKey()}";
    // print("Attachment Controller's Tag to create (In Attachment): $componentId");
    // AttachmentController attachmentController = Get.find<AttachmentController>(
    //   tag: componentId,
    // );

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
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.last_page),
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      final listToShow = (entity == null || entity.id == null)
                          ? attachmentController.temporaryList
                          : attachmentController.attachmentComponents;
                      return Column(
                        children: [
                          listToShow.isEmpty
                              ? Expanded(
                                  child: Center(
                                    child: Text(
                                      'No attachments found.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(color: Colors.red),
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(10),
                                    physics: ScrollPhysics(),
                                    itemCount: listToShow.length,
                                    itemBuilder: (context, index) {
                                      final attachment = listToShow[index];
                                      return CustomExtendedCard(
                                        title: attachment.name,
                                        content: [attachment.description ?? ''],
                                        otherDetails: [
                                          attachment.label != null &&
                                                  attachment.label!.id != null
                                              ? attachment.label!.id!
                                              : '',
                                          attachment.createdAt != null
                                              ? DateFormat.yMd().format(
                                                  attachment.createdAt!,
                                                )
                                              : '',
                                        ],
                                        onTap: () {
                                          if (attachment is Note) {
                                            Get.to(
                                              NoteDetailScreen(
                                                mode: Mode.edit,
                                                note: attachment,
                                                initialLabel: attachment.label,
                                                hideAttachmentButton: true,
                                              ),
                                              preventDuplicates: false,
                                            );
                                            attachmentController.getList();
                                          } else if (attachment is Task) {
                                            Get.to(
                                              TaskDetailScreen(
                                                mode: Mode.edit,
                                                task: attachment,
                                                initialLabel: attachment.label,
                                              ),
                                              preventDuplicates: false,
                                            );
                                            attachmentController.getList();
                                          }
                                        },
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
                                child: Text(
                                  'Add',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
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
