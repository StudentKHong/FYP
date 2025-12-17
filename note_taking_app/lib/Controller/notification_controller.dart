import 'dart:async';

import 'package:get/get.dart';
import 'package:note_taking_app/Model/Models/notification_model.dart';
import 'package:note_taking_app/Model/Repository/notification_repository.dart';

class NotificationController {
  var list = <AppNotification>[].obs;
  var totalCount = 0.obs;
  var errorMessage = "".obs;
  final NotificationRepository _notificationRepository =
      Get.find<NotificationRepository>();

  StreamSubscription<List<AppNotification>>? _getAllSubscription;
  StreamSubscription<int>? _getCountSubscription;

  static const Map<String, Duration?> options = {
    'None': null,
    '5 min before start': Duration(minutes: 5),
    '15 min before start': Duration(minutes: 15),
    '30 min before start': Duration(minutes: 30),
    '5 min before end': Duration(minutes: 5),
    '15 min before end': Duration(minutes: 15),
    '30 min before end': Duration(minutes: 30),
  };

  Future<void> getAll() async {
    errorMessage.value = "";
    _getAllSubscription?.cancel();
    _getAllSubscription = _notificationRepository
        .watchAll()
        .cast<List<AppNotification>>()
        .listen((data) {
          list.assignAll(data);
        }, onError: (ex) => errorMessage.value = ex.toString());
  }

  Future<void> markReadStatus(String notificationId, bool isRead) async {
    final index = list.indexWhere(
      (notification) => notification.id == notificationId,
    );

    if (index != -1) {
      final currentNotification = list[index];

      final updatedNotification = currentNotification.copyWith(isRead: isRead);
      list[index] = updatedNotification;
      list.refresh();

      try {
        errorMessage.value = "";
        await _notificationRepository.updateReadStatus(currentNotification);
      } catch (ex) {
        errorMessage.value = "Something went wrong.";
      }
    }
  }

  void getAllCount() {
    errorMessage.value = "";
    _getCountSubscription?.cancel();
    _getCountSubscription = _notificationRepository.watchAllCount().listen((
      data,
    ) {
      totalCount.value = data;
    }, onError: (ex) => errorMessage.value = ex.toString());
  }

  Future<AppNotification?> create(AppNotification appNotification) async {
    final createdNotification = await _notificationRepository.create(appNotification) as AppNotification;
    list.refresh();
    return createdNotification;
  }
}
