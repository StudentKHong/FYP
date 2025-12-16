import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/Model/Models/team_model.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/info_button.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';

class ShareToGroupScreen extends StatefulWidget {
  final BaseEntity group;
  const ShareToGroupScreen({super.key, required this.group});

  @override
  State<ShareToGroupScreen> createState() => _ShareToGroupScreenState();
}

class _ShareToGroupScreenState extends State<ShareToGroupScreen> {
  final NoteController noteController = Get.find<NoteController>();
  final TaskController taskController = Get.find<TaskController>();
  ComponentType selectedType = ComponentType.note;

  @override
  void initState() {
    super.initState();
  }

  Widget _getAdditionalDetails() {
    final name = widget.group.name;
    final description = widget.group.description;
    final dateCreated = widget.group.dateCreated;

    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Shared to: $name',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 5),
          CustomInfoButton(
            infoDetails: [
              Info(text: name ?? "Unknown", maxLines: 1),
              Info(text: description ?? "Unknown", maxLines: 1),
              Info(
                text: dateCreated != null
                    ? "\n${DateFormat.yMd().format(dateCreated)}"
                    : '',
                maxLines: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Controller getCurrentController() {
  //   // final String groupId = widget.group.id ?? '';
  //   // final String groupType = widget.group is Class ? 'class' : 'team';
  //   if (selectedType == ComponentType.note) {
  //     return Get.find<NoteController>();
  //   } else {
  //     return Get.find<TaskController>();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (widget.group is Team || widget.group is Team) {
      final group = widget.group;

      final String groupId = widget.group.id ?? '';
      final String groupType = group.runtimeType.toString();

      return Scaffold(
        appBar: CustomAppBar(titleText: 'Share To $groupType'),
        endDrawer: const HamburgerMenu(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getAdditionalDetails(),
            const SizedBox(height: 15),

            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Type:', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(width: 5),
                  AnimatedToggleSwitch.size(
                    current: selectedType,
                    values: [ComponentType.note, ComponentType.task],
                    indicatorAnimationType: AnimationType.onSelected,
                    style: ToggleStyle(
                      indicatorColor: Theme.of(context).primaryColor,
                    ),
                    iconBuilder: (value) {
                      final isSelected = value == selectedType;
                      return Text(
                        value.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
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
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedType == ComponentType.note) {
                  final Note note =
                      Get.to(
                            NoteDetailScreen(
                              mode: Mode.create,
                              additionalDetails: _getAdditionalDetails(),
                            ),
                          )
                          as Note;
                  await noteController.shareMultiple(
                    [note],
                    groupId,
                    groupType,
                  );
                } else {
                  final Task task =
                      Get.to(
                            TaskDetailScreen(
                              mode: Mode.create,
                              additionalDetails: _getAdditionalDetails(),
                            ),
                          )
                          as Task;
                  await taskController.shareMultiple(
                    [task],
                    groupId,
                    groupType,
                  );
                }
              },
              child: Text("Create New"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (selectedType == ComponentType.note) {
                  final List<Note> selectedNotes =
                      Get.toNamed(Routes.selectNote) as List<Note>;
                  await noteController.shareMultiple(
                    selectedNotes,
                    groupId,
                    groupType,
                  );
                } else {
                  final List<Task> selectedTasks =
                      Get.toNamed(Routes.selectTask) as List<Task>;
                  await taskController.shareMultiple(
                    selectedTasks,
                    groupId,
                    groupType,
                  );
                }
              },
              child: Text("Select From Existing"),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(titleText: "Share"),
      endDrawer: const HamburgerMenu(),
      body: Center(
        child: Text(
          'Nothing to share here.',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
