import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/Controller/setting_controller.dart';
import 'package:note_taking_app/Controller/task_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/notification_model.dart';
import 'package:note_taking_app/Model/Models/task_model.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/info_button.dart';
import 'package:note_taking_app/UI/SharedComponents/label_editor.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';
import 'package:note_taking_app/UI/create_note.dart';
import 'package:note_taking_app/main.dart';
import 'package:signature/signature.dart';

class TaskDetailScreen extends StatefulWidget {
  final Mode mode;
  final String? title;
  final String? description;
  final String? groupId;
  final String? groupType;
  final Widget? additionalDetails;
  final Task? task;
  final Label? initialLabel;
  final bool isLabelReadOnly;

  const TaskDetailScreen({
    super.key,
    required this.mode,
    this.title,
    this.description,
    this.groupId,
    this.groupType,
    this.additionalDetails,
    this.task,
    this.initialLabel,
    this.isLabelReadOnly = false,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final String title;
  final options = NotificationController.options;
  bool toggleEnabled = false;
  bool notificationsEnabled = true;
  bool hasChanged = false;
  String lastGeneratedContent = '';
  bool hasGeneratedLabels = false;

  late Task? original;
  Task? task;
  String? initialReminder;
  DateTime? startDateTime;
  DateTime? endDateTime;
  Status? status;
  Label? selectedLabel;
  String? selectedReminder;
  DateTime? reminderDateTime;

  final NotificationController notificationController =
      Get.find<NotificationController>();
  final TaskController taskController = Get.find<TaskController>();
  final SettingController settingController = Get.find<SettingController>();
  final LabelController labelController = Get.find<LabelController>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  // late QuillController contentController;
  final SignatureController drawingController = SignatureController();

  @override
  void initState() {
    super.initState();

    // Clear suggested labels.
    labelController.suggestedLabels.value = [];

    // Set default values.
    original = widget.task?.copyWith();
    task = original?.copyWith();

    task ??= Task(
      id: UniqueKey().toString(),
      createdAt: DateTime.now(),
      viewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: Status.unknown,
      isPinned: false,
      isArchived: false,
    );

    // Load labels.
    _loadLabels();

    // Load the initial state of the auto generate label toggle button.
    // Load initial selected reminder option.
    _loadCurrentSettings();

    // Assign page title based on mode.
    if (widget.title != null) {
      title = widget.title!;
      return;
    }
    switch (widget.mode) {
      case Mode.view:
        title = "Task Detail";
        break;
      case Mode.create || Mode.createShared:
        title = "Create Task";
        break;
      case Mode.edit || Mode.editShared:
        title = "Edit Task";
        break;
    }

    titleController.text = task?.name ?? '';
    descriptionController.text = task?.description ?? '';

    lastGeneratedContent = descriptionController.text.trim();
    hasGeneratedLabels = false;

    selectedLabel = widget.initialLabel ?? task?.label;

    startDateTime = task?.startDateTime;
    endDateTime = task?.endDateTime;
    reminderDateTime = task?.reminderDateTime;

    status = task?.status ?? Status.unknown;

    _listenToContentChanges();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    drawingController.dispose();
    super.dispose();
  }

  void _updateHasChanged() {
    final currentTitle = titleController.text;
    final currentContent = descriptionController.text;

    hasChanged =
        currentTitle != (original?.title ?? "") ||
        currentContent != (original?.description ?? "") ||
        startDateTime != original?.startDateTime ||
        endDateTime != original?.endDateTime ||
        status != (original?.status ?? Status.unknown) ||
        selectedLabel != original?.label ||
        selectedReminder != initialReminder;
  }

  // Add listener to controllers.
  void _listenToContentChanges() {
    titleController.addListener(_updateHasChanged);
    descriptionController.addListener(_updateHasChanged);
  }

  void _loadCurrentSettings() async {
    if (widget.mode == Mode.edit) {
      initialReminder = _getInitialReminderOption(
        reminder: task?.reminderDateTime,
      );
      selectedReminder = _getInitialReminderOption(
        reminder: task?.reminderDateTime,
      );
      return;
    }

    await settingController.get();
    final settings = settingController.currentSettings.value;

    if (settings != null) {
      setState(() {
        toggleEnabled = settings.autoLabelingEnabled;
        notificationsEnabled = settings.notificationsEnabled;
        initialReminder = _getInitialReminderOption(
          reminderFrom: settings.offsetFrom,
          reminderOffset: settings.reminderOffset,
        );
        selectedReminder = _getInitialReminderOption(
          reminderFrom: settings.offsetFrom,
          reminderOffset: settings.reminderOffset,
        );
      });
    }
  }

  void _loadLabels() async {
    if (task != null && task!.label != null && task!.label!.id != null) {
      // Load existing label.
      labelController.getTaskLabels();

      // Load suggested labels.
      await labelController.generateLabel(
        ComponentType.task,
        task!.description ?? '',
      );
    }
  }

  Future<void> _generateLabels() async {
    if (!toggleEnabled) return;

    final currentContent = descriptionController.text.trim();
    final isSuggestedEmpty = labelController.suggestedLabels.isEmpty;
    final hasContentChanged = currentContent != lastGeneratedContent;

    final shouldGenerate = isSuggestedEmpty || hasContentChanged;

    if (shouldGenerate) {
      await labelController.generateLabel(ComponentType.note, currentContent);

      if (labelController.errorMessage.value.isEmpty) {
        lastGeneratedContent = currentContent;
        hasGeneratedLabels = true;
      }
    }
  }

  Future<DateTime?> _pickDateTime() async {
    final currentDateTime = DateTime.now();
    final tempDate = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: currentDateTime,
      lastDate: DateTime(
        currentDateTime.year + 10,
        currentDateTime.month,
        currentDateTime.day,
      ),
    );
    if (tempDate != null && mounted) {
      final tempTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (tempTime != null) {
        DateTime dateTime = DateTime(
          tempDate.year,
          tempDate.month,
          tempDate.day,
          tempTime.hour,
          tempTime.minute,
        );
        return dateTime;
      }
      return null;
    }
    return null;
  }

  String? _getInitialReminderOption({
    DateTime? reminder,
    String? reminderFrom,
    int? reminderOffset,
  }) {
    if (reminder == null) {
      return 'None';
    }

    if (reminderFrom != null && reminderOffset != null) {
      return options.keys.firstWhere(
        (key) =>
            key.contains(reminderFrom) &&
            key.contains(reminderOffset.toString()),
        orElse: () => 'None',
      );
    }

    final start = task?.startDateTime;
    final end = task?.endDateTime;

    for (var entry in options.entries) {
      final optionText = entry.key;
      final optionDuration = entry.value;

      if (optionText.contains('start') &&
          start != null &&
          optionDuration != null) {
        final calculatedReminderTime = start.subtract(optionDuration);
        if (calculatedReminderTime.isAtSameMomentAs(reminder)) {
          return optionText;
        }
      } else if (optionText.contains('end') &&
          end != null &&
          optionDuration != null) {
        final calculatedReminderTime = end.subtract(optionDuration);
        if (calculatedReminderTime.isAtSameMomentAs(reminder)) {
          return optionText;
        }
      }
    }
    return 'None';
  }

  List<DropdownMenuItem<String>> _getReminderOptions() {
    return options.entries
        .map(
          (option) =>
              DropdownMenuItem(value: option.key, child: Text(option.key)),
        )
        .toList();
  }

  List<DropdownMenuItem<Status>> _getStatusOptions() {
    return Status.values
        .map(
          (option) => DropdownMenuItem(value: option, child: Text(option.name)),
        )
        .toList();
  }

  void _recalculateReminderDateTime(String? selectedReminder) {
    final duration = options[selectedReminder.toString()];
    if (duration != null) {
      if (selectedReminder != null &&
          startDateTime != null &&
          selectedReminder.toString().contains('start')) {
        reminderDateTime = startDateTime!.subtract(duration);
      } else if (selectedReminder != null &&
          endDateTime != null &&
          selectedReminder.toString().contains('end')) {
        reminderDateTime = endDateTime!.subtract(duration);
      }
    } else {
      reminderDateTime = null;
    }
  }

  TZDateTime? convertToTZ(DateTime? dateTime) {
    if (dateTime == null) return null;
    final Location location = local;
    // final location = getLocation(DateTime.now().timeZoneName);
    return TZDateTime.from(dateTime, location);
  }

  Future<void> _scheduleReminder(Task task) async {
    if (reminderDateTime == null) {
      await flutterLocalNotificationsPlugin.cancel(task.id.hashCode);
      return;
    }
    final TZDateTime? scheduleDate = convertToTZ(reminderDateTime);

    if (scheduleDate == null || scheduleDate.isBefore(DateTime.now())) {
      return;
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminder',
      showWhen: true,
    );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    String title = 'Task Reminder: ${task.name}';

    String description = 'Your task "${task.title}" is upcoming!';
    if (task.reminderDateTime != null) {
      final isBeforeStart =
          task.startDateTime != null &&
          task.reminderDateTime!.isBefore(task.startDateTime!);
      final isBeforeEnd =
          task.endDateTime != null &&
          task.reminderDateTime!.isBefore(task.endDateTime!);

      if (isBeforeStart) {
        final difference = task.startDateTime!.difference(
          task.reminderDateTime!,
        );
        description = '${difference.inMinutes} minute(s) before start';
      } else if (isBeforeEnd) {
        final difference = task.endDateTime!.difference(task.reminderDateTime!);
        description = '${difference.inMinutes} minute(s) before end';
      }
    }

    final notificationToCreate = AppNotification(
      id: UniqueKey().toString(),
      title: title,
      description: description,
      referenceId: task.id,
      referenceType: "task",
      createdAt: DateTime.now(),
      notifiedAt: scheduleDate,
      isRead: false,
    );

    final notification = await notificationController.create(
      notificationToCreate,
    );

    if (notification != null) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notification.id.hashCode,
        title,
        description,
        scheduleDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: task.id,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (hasChanged && widget.mode != Mode.view) {
          final bool isForShared = widget.mode == Mode.createShared;
          if (widget.mode == Mode.create || widget.mode == Mode.createShared) {
            task = Task(
              id: UniqueKey().toString(),
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              startDateTime: startDateTime,
              endDateTime: endDateTime,
              reminderDateTime: reminderDateTime,
              status: status ?? Status.unknown,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              viewedAt: isForShared ? null : DateTime.now(),
              isPinned: false,
              isArchived: isForShared ? null : false,
              label: isForShared ? null : selectedLabel,
              labelName: isForShared ? selectedLabel?.name : null,
            );

            if (task != null) {
              if (widget.mode == Mode.create) {
                final createdTask = await taskController.create(task!);
                task = createdTask;

                await _scheduleReminder(createdTask!);
              } else if (widget.mode == Mode.createShared &&
                  widget.groupId != null &&
                  widget.groupType != null) {
                await taskController.shareMultiple(
                  [task!],
                  widget.groupId!,
                  widget.groupType!,
                );
              }
            }

            if (taskController.errorMessage.value.isNotEmpty) {
              CustomDialog.showError(
                "Error",
                taskController.errorMessage.value,
              );
              return;
            }
            CustomDialog.showSuccess("Success", "Successfully create task.");
            Get.back(result: task);
            return;
          } else {
            task = task!.copyWith(
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              startDateTime: startDateTime,
              endDateTime: endDateTime,
              reminderDateTime: reminderDateTime,
              status: status,
              label: isForShared ? null : selectedLabel,
              labelName: isForShared ? selectedLabel?.name : null,
              isViewed: isForShared ? false : true,
              isUpdated: true,
              replaceReminder: true,
            );

            if (widget.mode == Mode.edit) {
              taskController.edit([task!]);
              await _scheduleReminder(task!);
            } else if (widget.mode == Mode.editShared &&
                widget.groupId != null &&
                widget.groupType != null) {
              await taskController.editShared(
                task!,
                widget.groupId!,
                widget.groupType!,
              );
            }
            if (taskController.errorMessage.value.isNotEmpty) {
              CustomDialog.showError(
                "Error",
                taskController.errorMessage.value,
              );
              return;
            }
            CustomDialog.showSuccess("Success", "Successfully edit task.");
            Get.back(result: task);
            return;
          }
        }
        Get.back();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          titleText: title,
          actions:
              (task != null &&
                  (widget.mode == Mode.edit || widget.mode == Mode.editShared))
              ? AdditionalOptions.buildDefaultOptions(
                  context: context,
                  controller: taskController,
                  descriptionController: descriptionController,
                  titleController: titleController,
                  tasks: [task!],
                  isForShared: widget.mode == Mode.editShared,
                  onUpdate: (updatedTasks) {
                    final list = updatedTasks
                        .map((item) => item as Task)
                        .toList();
                    if (list.length == 1) {
                      setState(() {
                        task = list.first;
                      });
                    }
                  },
                )
              : [],
          replaceDefaultActions: false,
        ),
        endDrawer: const HamburgerMenu(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.additionalDetails != null) ...[
                  widget.additionalDetails!,
                  const SizedBox(height: 10),
                ],
                // Text field for title.
                CustomTextField(
                  withBorder: false,
                  maxLength: 50,
                  controller: titleController,
                  hintText: "Title",
                  isReadOnly: widget.mode == Mode.view,
                ),
                const SizedBox(height: 10),

                // Label and autogenerate label button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Set label editor as read only if is view mode.
                    // Display predefined label name.
                    Expanded(
                      child: CustomLabelEditor(
                        type: ComponentType.task,
                        labelController: labelController,
                        initialLabel: widget.initialLabel ?? widget.task?.label,
                        isReadOnly:
                            widget.isLabelReadOnly || widget.mode == Mode.view,
                        onTagsChanged: (value) {
                          if (!widget.isLabelReadOnly &&
                              widget.mode != Mode.view) {
                            setState(() {
                              selectedLabel = value;
                              _updateHasChanged();
                            });
                          }
                        },
                        withGenerateLabelSwitch: widget.mode != Mode.view
                            ? true
                            : false,
                        contentToSuggestLabel: descriptionController.text,
                        initialSwitchState: toggleEnabled,
                        onToggled: (value) => setState(() {
                          toggleEnabled = value;
                        }),
                        onEditorOpened: _generateLabels,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Expected start datetime and end datetime of the task.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.play_arrow),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: startDateTime != null
                                ? Text(
                                    DateFormat(
                                      'MMM d, yyyy HH:mm',
                                    ).format(startDateTime!),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  )
                                : Text(
                                    'Start Date',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Colors.grey),
                                  ),
                          ),
                        ),
                        widget.mode == Mode.view
                            ? Icon(Icons.lock)
                            : IconButton(
                                onPressed: () async {
                                  DateTime? dateTime = await _pickDateTime();
                                  if (dateTime != null) {
                                    setState(() {
                                      startDateTime = dateTime;
                                      _updateHasChanged();
                                      _recalculateReminderDateTime(
                                        selectedReminder,
                                      );
                                    });
                                  }
                                },
                                icon: Icon(Icons.calendar_month),
                              ),
                      ],
                    ),

                    Center(child: Text('-')),

                    Row(
                      children: [
                        Icon(Icons.stop),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: endDateTime != null
                                ? Text(
                                    DateFormat(
                                      'MMM d, yyyy HH:mm',
                                    ).format(endDateTime!),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  )
                                : Text(
                                    'End Date',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Colors.grey),
                                  ),
                          ),
                        ),
                        widget.mode == Mode.view
                            ? Icon(Icons.lock)
                            : IconButton(
                                onPressed: () async {
                                  DateTime? dateTime = await _pickDateTime();
                                  if (dateTime != null) {
                                    setState(() {
                                      endDateTime = dateTime;
                                      _updateHasChanged();
                                      _recalculateReminderDateTime(
                                        selectedReminder,
                                      );
                                    });
                                  }
                                },
                                icon: Icon(Icons.calendar_month),
                              ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Select reminder.
                // Hide this if is view mode.
                if (widget.mode != Mode.view &&
                    widget.mode != Mode.editShared &&
                    widget.mode != Mode.createShared)
                  Row(
                    children: [
                      Icon(Icons.notifications),
                      Text(
                        'Reminder:',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: notificationsEnabled
                              ? null
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: selectedReminder ?? 'None',
                        items: _getReminderOptions(),
                        onChanged: notificationsEnabled
                            ? (value) {
                                if (value == null) return;
                                setState(() {
                                  selectedReminder = value;
                                  hasChanged = true;
                                  _recalculateReminderDateTime(
                                    selectedReminder,
                                  );
                                });
                              }
                            : null,
                        disabledHint: notificationsEnabled
                            ? null
                            : Text(
                                selectedReminder ?? 'None',
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(color: Colors.grey.shade400),
                              ),
                      ),
                      if (!notificationsEnabled)
                        CustomInfoButton(
                          color: Colors.red,
                          infoDetails: [
                            Info(
                              text:
                                  "You have disabled push notifications. Please enabled it in Settings.",
                              maxLines: 2,
                            ),
                          ],
                        ),
                    ],
                  ),

                // Select status.
                Row(
                  children: [
                    Icon(Icons.abc),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Status:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<Status>(
                      value: status,
                      items: _getStatusOptions(),
                      onChanged: widget.mode == Mode.view
                          ? null
                          : (value) {
                              setState(() {
                                status = value;
                                hasChanged = true;
                              });
                            },
                      icon: widget.mode == Mode.view
                          ? Icon(
                              Icons.lock,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Text area for task description.
                CustomTextField(
                  withBorder: false,
                  maxLength: 500,
                  controller: descriptionController,
                  hintText: "Description",
                  isReadOnly: widget.mode == Mode.view,
                ),

                const SizedBox(height: 20),

                // To export task to Google Calendar.
                // Hide this if is view mode.
                if (widget.mode != Mode.view)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final deviceCalendarPlugin = DeviceCalendarPlugin();
                        var permission = await deviceCalendarPlugin
                            .hasPermissions();
                        if (permission.isSuccess && permission.data != true) {
                          await deviceCalendarPlugin.requestPermissions();
                        }

                        final calendarsResult = await deviceCalendarPlugin
                            .retrieveCalendars();
                        if (calendarsResult.data == null ||
                            calendarsResult.data!.isEmpty) {
                          CustomDialog.showError(
                            "Error",
                            "Failed to connect with local calendar.",
                          );
                          return;
                        }
                        final calendar = calendarsResult.data!.firstWhere(
                          (calendar) => calendar.isReadOnly == false,
                          orElse: () => calendarsResult.data!.first,
                        );

                        final event = Event(
                          calendar.id,
                          title: task!.title,
                          start: convertToTZ(startDateTime),
                          end: convertToTZ(endDateTime),
                        );

                        final result = await deviceCalendarPlugin
                            .createOrUpdateEvent(event);
                        if (result != null &&
                            result.isSuccess &&
                            result.data != null) {
                          CustomDialog.showSuccess(
                            "Success",
                            "Successfully add task to calendar.",
                          );
                        } else {
                          CustomDialog.showError(
                            "Error",
                            "Failed to add task to calendar.",
                          );
                        }
                      }, // TODO: Call Google Calendar API.
                      child: Text(
                        'Add to Local Calendar',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
