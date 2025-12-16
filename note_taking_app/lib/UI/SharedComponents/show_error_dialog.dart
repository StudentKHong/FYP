import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CustomDialog {
  static void showError(String title, String message) {
    Toastification().show(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
      description: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: Duration(seconds: 3),
      alignment: Alignment.topCenter
    );
  }

  static void showSuccess(String title, String message) {
    Toastification().show(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
      description: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: Duration(seconds: 3),
      alignment: Alignment.topCenter
    );
  }
  
  static void showInfo(String title, String message) {
    Toastification().show(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
      description: Text(message),
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: Duration(seconds: 3),
      alignment: Alignment.topCenter
    );
  }
}
