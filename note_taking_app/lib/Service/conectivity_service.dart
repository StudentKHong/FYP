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