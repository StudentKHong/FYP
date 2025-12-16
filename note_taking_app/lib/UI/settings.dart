import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/Controller/setting_controller.dart';
import 'package:note_taking_app/Model/Models/setting_model.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/drop_down_button.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/toggle_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingController settingController = Get.find<SettingController>();
  final reminderSettings = NotificationController.options.keys.toList();
  // late String selectedReminder;

  @override
  void initState() {
    super.initState();

    _fetchData();
    ever(settingController.errorMessage, (String message) {
      if (message.isNotEmpty) {
        CustomDialog.showError("Error", settingController.errorMessage.value);
      }
    });
    // selectedReminder = settingController.getReminderOption();
  }

  Future<void> _fetchData() async {
    await settingController.get();
  }

  Widget _buildSettingCard(
    BuildContext context,
    String title,
    List<Widget> contentWidgets,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(),
            ...contentWidgets,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleText: 'Settings'),
      endDrawer: const HamburgerMenu(),
      body: Obx(() {
        final settings = settingController.currentSettings.value;
        if (settings == null) {
          settingController.currentSettings.value = Setting(
            id: UniqueKey().toString(),
            darkMode: false,
            notificationsEnabled: false,
            reminderOffset: 0,
            offsetFrom: 'start',
            autoLabelingEnabled: false,
          );
        }

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: _buildSettingCard(context, 'Appearance', [
                CustomSwitch(
                  title: "Dark Mode",
                  isTitleLeading: true,
                  isToggled: settingController.currentSettings.value!.darkMode,
                  onChanged: (value) {
                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (settingController.currentSettings.value == null) {
                        return;
                      }
                      await settingController.edit(darkMode: value);
                    });
                  },
                  layout: LayoutMode.listTile,
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _buildSettingCard(context, 'Notifications', [
                CustomSwitch(
                  title: "Push Notification",
                  infoDescription:
                      'To enable the application to send notifications.',
                  isTitleLeading: true,
                  isToggled: settingController
                      .currentSettings
                      .value!
                      .notificationsEnabled,
                  onChanged: (value) {
                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (settingController.currentSettings.value == null) {
                        return;
                      }
                      await settingController.edit(notificationsEnabled: value);
                    });
                  },
                  layout: LayoutMode.listTile,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomDropDownBox(
                    title: 'Reminder',
                    items: reminderSettings,
                    selectedValue: settingController.getReminderOption(),
                    onChanged: (value) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        settingController.setSelectedReminder(value);
                      });
                    },
                    isColumn: false,
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _buildSettingCard(context, 'Data and Security', [
                CustomSwitch(
                  title: 'Auto Generate Labels',
                  infoDescription: 'To enable label autogeneration as default.',
                  isTitleLeading: true,
                  isToggled: settingController
                      .currentSettings
                      .value!
                      .autoLabelingEnabled,
                  onChanged: (value) {
                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (settingController.currentSettings.value == null) {
                        return;
                      }
                      await settingController.edit(autoLabelingEnabled: value);
                    });
                  },
                  layout: LayoutMode.listTile,
                ),
              ]),
            ),
          ],
        );
      }),
    );
  }
}
