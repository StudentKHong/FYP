// ==================================================
// Program Name   : show_error_dialog.dart
// Purpose        : Utility to show error dialogs across the app
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

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
