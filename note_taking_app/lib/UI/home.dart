import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/card.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteController noteController = Get.find<NoteController>();
  final TaskController taskController = Get.find<TaskController>();

  @override
  void initState(){
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await noteController.getAll();
    await taskController.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: CircleAvatar(
          minRadius: 20,
          maxRadius: 30,
          child: Icon(Icons.book),
        ),
        titleText: 'Notes App',
      ),
      endDrawer: const HamburgerMenu(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 30) / 2,
                    child: CustomCard(
                      icon: Icons.note,
                      label: 'Notes',
                      onTap: () => Get.toNamed(Routes.notes),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 30) / 2,
                    child: CustomCard(
                      icon: Icons.task_alt,
                      label: 'Tasks',
                      onTap: () => Get.toNamed(Routes.tasks),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 30) / 2,
                    child: CustomCard(
                      icon: Icons.add_outlined,
                      label: 'Add Note',
                      onTap: () => Get.toNamed(Routes.createNote),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 30) / 2,
                    child: CustomCard(
                      icon: Icons.add_outlined,
                      label: 'Add Task',
                      onTap: () => Get.toNamed(Routes.createTask),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Obx(() {
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Notes',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      if (noteController.list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'No recent notes found.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.copyWith(color: Colors.red),
                          ),
                        )
                      else
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: noteController.mostRecent.length,
                          itemBuilder: (context, index) {
                            final note = noteController.mostRecent[index];

                            return CustomExtendedCard(
                              title: note.title,
                              content: [
                                if (note.searchableContent != null) note.searchableContent!,
                                DateFormat.yMd().format(note.createdAt),
                              ],
                              otherDetails: [note.label?.name ?? ''],
                              onTap: () {
                                Get.to(NoteDetailScreen(mode: Mode.edit, note: note, ));
                              },
                            );
                          },
                        ),
              
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'Recent Tasks',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),

                      if (taskController.list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'No recent tasks found.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.copyWith(color: Colors.red),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: taskController.mostRecent.length,
                          itemBuilder: (context, index) {
                            final task = taskController.mostRecent[index];

                            return CustomExtendedCard(
                              title: task.title,
                              content: [
                                task.description ?? '',
                                DateFormat.yMd().format(task.createdAt),
                              ],
                              otherDetails: [task.label?.name ?? ''],
                              onTap: () {
                                Get.to(TaskDetailScreen(mode: Mode.edit, task: task, ));
                              },
                            );
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
