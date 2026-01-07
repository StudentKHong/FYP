// ==================================================
// Program Name   : conectivity_service.dart
// Purpose        : Monitors device internet connectivity status
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService extends GetxService{
  var isOnline = false.obs;
  Stream<bool> get connectionStream => isOnline.stream;

  @override
  void onInit() {
    super.onInit();
    InternetConnection().onStatusChange.listen((status) {
      isOnline.value = status == InternetStatus.connected;
    });
  }

  Future<bool> checkConnection() async {
    isOnline.value = await InternetConnection().hasInternetAccess;
    return isOnline.value;
  }
}