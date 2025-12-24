import 'dart:async';

import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Model/Models/notification_model.dart';
import 'package:note_taking_app/Model/Repository/notification_repository.dart';

class NotificationController extends GetxController {
  var list = <AppNotification>[].obs;
  var totalCount = 0.obs;
  var errorMessage = "".obs;
  var isLoading = false.obs;

  final NotificationRepository _notificationRepository =
      Get.find<NotificationRepository>();

  StreamSubscription<List<AppNotification>>? _getAllSubscription;
  StreamSubscription<int>? _getCountSubscription;

  @override
  void onInit() {
    super.onInit();

    final AuthenticationController authController =
        Get.find<AuthenticationController>();
    ever(authController.user, (user) {
      _getAllSubscription?.cancel();
      _getCountSubscription?.cancel();

      if (user != null) {
        getAll();
        getAllCount();
      } else {
        list.clear();
      }
    });
  }

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
    isLoading.value = true;
    errorMessage.value = "";
    _getAllSubscription?.cancel();
    _getAllSubscription = _notificationRepository
        .watchAll()
        .cast<List<AppNotification>>()
        .listen(
          (data) {
            list.assignAll(data);
            isLoading.value = false;
          },
          onError: (ex) {
            errorMessage.value = ex.toString();
            isLoading.value = false;
          },
        );
  }

  Future<void> markReadStatus(String notificationId, bool isRead) async {
    final index = list.indexWhere(
      (notification) => notification.id == notificationId,
    );

    if (index != -1) {
      final currentNotification = list[index];

      final updatedNotification = currentNotification.copyWith(isRead: isRead);
      list[index] = updatedNotification;

      try {
        errorMessage.value = "";
        await _notificationRepository.updateReadStatus(updatedNotification);
      } catch (ex) {
        errorMessage.value = "Something went wrong.";
      }
    }
  }

  void getAllCount() {
    isLoading.value = true;
    errorMessage.value = "";
    _getCountSubscription?.cancel();
    _getCountSubscription = _notificationRepository.watchAllCount().listen(
      (data) {
        totalCount.value = data;
        isLoading.value = false;
      },
      onError: (ex) {
        errorMessage.value = ex.toString();
        isLoading.value = false;
      },
    );
  }

  Future<AppNotification?> create(AppNotification appNotification) async {
    final createdNotification =
        await _notificationRepository.create(appNotification)
            as AppNotification;
    list.refresh();
    return createdNotification;
  }
}
