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
