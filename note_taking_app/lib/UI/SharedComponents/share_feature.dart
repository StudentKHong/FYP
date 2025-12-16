import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/class_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/role_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Controller/team_controller.dart';
import 'package:note_taking_app/Model/Models/group_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/note_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class ShareFeature {
  static shareInApp(BuildContext context, {List<Note>? notes, List<Task>? tasks}) async {
    if ((notes?.isEmpty ?? true) && (tasks?.isEmpty ?? true)) return;

    final RoleController roleController = Get.find<RoleController>();
    final bool isClass = roleController.hasPermission(PermissionType.viewClass);
    final String groupType = isClass ? 'class' : 'team';

    // Gather groups where users are going to share the note to.
    final List<Group> groups = await Get.to(
      ListScreen<Group>(
        title: 'Select ${isClass ? "classes" : "teams"} to proceed',
        pageType: isClass ? ListScreenType.classes : ListScreenType.teams,
        initialSelectionMode: SelectionMode.other,
        controller: isClass
            ? Get.find<ClassController>()
            : Get.find<TeamController>(),
      ),
    );

    bool hasError = false;
    for (final group in groups) {
      final groupId = group.id;
      if (groupId == null) continue;

      try {
        if (notes != null && notes.isNotEmpty) {
          final controller = Get.find<NoteController>();
          await controller.shareMultiple(notes, groupId, groupType);
          if (controller.errorMessage.value.isNotEmpty) {
            hasError = true;
          }
        }
        if (tasks != null && tasks.isNotEmpty) {
          final controller = Get.find<TaskController>();
          await controller.shareMultiple(tasks, groupId, groupType);
          if (controller.errorMessage.value.isNotEmpty) {
            hasError = true;
          }
        }
      } catch (ex) {
        hasError = true;
      }
    }

    if (hasError) {
      CustomDialog.showInfo("Info", "Successfully share to group(s). (some failed)");
    } else {
      CustomDialog.showSuccess("Success", "Successfully share to group(s).");
    }
  }

  static shareOutsideApp({
    required BuildContext context,
    required String shareTitle,
    String? shareDescription,
    required TextEditingController titleController,
    QuillController? quillController,
    TextEditingController? descriptionController,
  }) async {
    try {
      String data = "";
      if (quillController != null) {
        final delta = quillController.document.toDelta();
        final converter = QuillDeltaToHtmlConverter(
          delta.toJson(),
          ConverterOptions.forEmail(),
        );
        data = converter.convert();
      } else if (descriptionController != null) {
        data = descriptionController.text;
      }

      // Build HTML widgets.
      final key = GlobalKey();
      final html = """<h1>${titleController.text}</h1> $data""";

      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return Material(
            color: Colors.transparent,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20)],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    minHeight: MediaQuery.of(context).size.height * 0.8
                  ),
                  child: SingleChildScrollView(
                    child: HtmlWidget(
                      html,
                      textStyle: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      await Future.delayed(Duration(seconds: 1));

      // Convert HTML page into image data.
      final objectBoundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await objectBoundary.toImage(pixelRatio: 3.0);
      final imageInByte = await image.toByteData(format: ImageByteFormat.png);
      final byteData = imageInByte!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imageFile = File(
        "${directory.path}/note_${DateTime.now().millisecondsSinceEpoch}.png",
      );
      await imageFile.writeAsBytes(byteData);

      Navigator.of(context).pop();

      await Future.delayed(Duration(milliseconds: 300));

      // Initiate share page.
      await SharePlus.instance.share(
        ShareParams(
          title: shareTitle,
          text: shareDescription,
          files: [XFile(imageFile.path)],
        ),
      );
    } catch (ex) {
      CustomDialog.showError("Error", ex.toString());
    }
  }
}
