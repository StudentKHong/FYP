// ==================================================
// Program Name   : home.dart
// Purpose        : Main home screen UI with note/task overview
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 7 January 2026
// ==================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/UI/Navigation/named_routes.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/card.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/SharedComponents/loading_state.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';
import 'package:note_taking_app/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteController noteController = Get.find<NoteController>();
  final TaskController taskController = Get.find<TaskController>();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _loadData();
  }

  Future<void> _loadData() async {
    await noteController.getAll();
    await taskController.getAll();
  }

  Future<void> _requestNotificationPermission() async {
    final permissionGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (permissionGranted == null || !permissionGranted) {
      CustomDialog.showError(
        "Error",
        "Failed to receive permission for notification.",
      );
    }
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            Column(
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

                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Notes',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      Obx(() {
                        if (noteController.isLoading.value) {
                          return LoadingShimmer(itemCount: 3);
                        } else if (noteController.list.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'No recent notes found.',
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(color: Colors.red),
                            ),
                          );
                        } else {
                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: noteController.mostRecent.length,
                            itemBuilder: (context, index) {
                              final note = noteController.mostRecent[index];

                              return CustomExtendedCard(
                                title: note.title,
                                content: [
                                  if (note.searchableContent != null)
                                    note.searchableContent!,
                                  DateFormat.yMd().format(note.createdAt),
                                ],
                                otherDetails: [note.label?.name ?? ''],
                                onTap: () {
                                  Get.to(
                                    NoteDetailScreen(
                                      mode: Mode.edit,
                                      note: note,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }
                      }),

                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'Recent Tasks',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),

                      Obx(() {
                        if (taskController.isLoading.value) {
                          return LoadingShimmer(itemCount: 3);
                        } else if (taskController.list.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'No recent tasks found.',
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(color: Colors.red),
                            ),
                          );
                        } else {
                          return ListView.builder(
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
                                  Get.to(
                                    TaskDetailScreen(
                                      mode: Mode.edit,
                                      task: task,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
