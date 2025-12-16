import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/Model/Models/setting_model.dart';
import 'package:note_taking_app/Model/Repository/setting_repository.dart';

class SettingController extends GetxController {
  final SettingRepository settingRepository = Get.find<SettingRepository>();

  var errorMessage = "".obs;
  var isLoading = false.obs;
  var currentSettings = Rx<Setting?>(null);
  Timer? _debounce;

  Future<void> get() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final currentSetting = await settingRepository.get();
      currentSettings.value = currentSetting;
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(Setting setting) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final createdSetting = await settingRepository.create(setting);
      currentSettings.value = createdSetting;
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> edit({
    bool? darkMode,
    bool? notificationsEnabled,
    int? reminderOffset,
    String? offsetFrom,
    bool? autoLabelingEnabled,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      if (currentSettings.value == null) return;
      currentSettings.value = currentSettings.value!.copyWith(
        darkMode: darkMode,
        notificationsEnabled: notificationsEnabled,
        reminderOffset: reminderOffset,
        offsetFrom: offsetFrom,
        autoLabelingEnabled: autoLabelingEnabled,
      );

      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), () async {
        final updatedSetting = await settingRepository.edit(
          currentSettings.value!,
        );
        currentSettings.value = updatedSetting;

        if (darkMode != null) {
          Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
        }
      });
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> delete(String settingId) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      await settingRepository.delete(settingId);
      currentSettings.value = null;
    } catch (ex) {
      errorMessage.value = "Something went wrong.";
    } finally {
      isLoading.value = false;
    }
  }

  String getReminderOption() {
    if (currentSettings.value == null) return 'None';
    final offset = currentSettings.value!.reminderOffset;
    final offsetFrom = currentSettings.value!.offsetFrom;

    if (offset == 0 || offsetFrom.toLowerCase() == 'none') {
      return 'None';
    }

    final String reminderOption =
        '$offset min before ${offsetFrom.toLowerCase()}';
    if (NotificationController.options.containsKey(reminderOption)) {
      return reminderOption;
    } else {
      return 'None';
    }
  }

  void setSelectedReminder(String reminder) {
    if (currentSettings.value == null) return;

    final offset = NotificationController.options[reminder];
    if (offset == null) {
      currentSettings.value = currentSettings.value!.copyWith(
        reminderOffset: 0,
        offsetFrom: 'none',
      );
    } else {
      final isStart = reminder.contains('start');
      final isEnd = reminder.contains('end');
      String offsetFrom = 'none';

      if (isStart) {
        offsetFrom = 'start';
      } else if (isEnd) {
        offsetFrom = 'end';
      }

      try {
        isLoading.value = true;
        errorMessage.value = "";
        edit(reminderOffset: offset.inMinutes, offsetFrom: offsetFrom);
      } catch (ex) {
        errorMessage.value = "Something went wrong.";
      } finally {
        isLoading.value = false;
      }
    }
  }
}
