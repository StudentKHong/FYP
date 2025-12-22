import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/SharedComponents/loading_state.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/UI/create_task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskController taskController = Get.find<TaskController>();
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadTaskForDate(selectedDate);
  }

  void _loadTaskForDate(DateTime date) {
    final dateRange = DateTimeRange(
      start: DateTime(date.year, date.month, date.day),
      end: DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
    taskController.setFilter(TaskFilter(taskPeriod: dateRange));
    taskController.filter(taskPeriod: dateRange);
  }

  String _formatDateTime(Task task) {
    final start = task.startDateTime;
    final end = task.endDateTime;

    String startFormatted;
    if (start == null) {
      startFormatted = "--:--";
    } else {
      startFormatted = DateFormat('MMM d, h:mm a').format(start);
    }

    String endFormatted;
    if (end == null) {
      endFormatted = "--:--";
    } else {
      endFormatted = DateFormat('MMM d, h:mm a').format(end);
    }
    return "$startFormatted -> $endFormatted";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleText: 'Calendar'),
      endDrawer: const HamburgerMenu(),
      body: RefreshIndicator(
        onRefresh: () async => _loadTaskForDate(selectedDate),
        child: Column(
          children: [
            CalendarDatePicker(
              initialDate: DateTime.now(),
              currentDate: selectedDate,
              firstDate: DateTime(DateTime.now().year - 10),
              lastDate: DateTime(DateTime.now().year + 10, 12, 31),
              onDateChanged: (newDate) {
                setState(() {
                  selectedDate = newDate;
                });
                _loadTaskForDate(newDate);
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 1,
                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tasks',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Divider(),
                      Text(
                        'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Obx(() {
                          final tasks = taskController.filteredList;

                          if (taskController.isLoading.value && tasks.isEmpty) {
                            return LoadingShimmer(itemCount: 2,);
                          }

                          if (tasks.isEmpty) {
                            return EmptyState(
                              icon: Icons.task_outlined,
                              message: "No tasks on this day.",
                            );
                          }
                          return ListView.builder(
                            itemCount: taskController.filteredList.length,
                            itemBuilder: (context, index) {
                              final item = taskController.filteredList[index];
                              return CustomExtendedCard(
                                title: item.name,
                                status: item.status,
                                content: [
                                  item.description ?? '',
                                  _formatDateTime(item),
                                ],
                                onTap: () => Get.to(
                                  TaskDetailScreen(mode: Mode.edit, task: item),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
