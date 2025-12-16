import 'package:flutter/material.dart';

Future<void> buildConfirmationMessage({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  required String buttonText1,
  required Color colorForButton1,
  required String buttonText2,
  required Color colorForButton2,
  required Future<void> Function() onTapOption1,
  Future<void> Function()? onTapOption2,
}) async {
  final bool response = await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content != null
          ? Text(content)
          : contentWidget ?? const SizedBox.shrink(),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(colorForButton1),
          ),
          child: Text(buttonText1),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(colorForButton2),
          ),
          child: Text(buttonText2),
        ),
      ],
    ),
  );
  if (response) {
    await onTapOption1();
  }
  else if (!response && onTapOption2 != null) {
    await onTapOption2();
  }
}
