// ==================================================
// Program Name   : login_details.dart
// Purpose        : Stores login-related details for users
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

// Details to be displayed during login.
import 'package:flutter/widgets.dart';

class FormDetails {
  final IconData leadingIcon;
  final String title;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool isPassword;
  bool isTextHidden;

  FormDetails({
    required this.leadingIcon,
    required this.title,
    required this.controller,
    this.keyboardType,
    this.hintText,
    this.isPassword = false,
    this.isTextHidden = false
  });
}
