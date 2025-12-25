import 'package:flutter/material.dart';

class ButtonDetails {
  final String? text;
  final Color buttonColor;
  final Future<void> Function()? onTapOption;

  ButtonDetails({
    required this.text,
    required this.buttonColor,
    this.onTapOption,
  });
}

Future<void> buildConfirmationMessage({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  List<ButtonDetails>? buttonDetails,
  // String? buttonText1,
  // Color? colorForButton1,
  // String? buttonText2,
  // Color? colorForButton2,
  // required Future<void> Function() onTapOption1,
  // Future<void> Function()? onTapOption2,
}) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content != null
          ? Text(content)
          : contentWidget ?? const SizedBox.shrink(),
      actions: buttonDetails?.map((detail) {
        if (detail.text == null) return SizedBox.shrink();
        return TextButton(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(detail.buttonColor)),
          onPressed: () async {
            Navigator.pop(context);
            if (detail.onTapOption != null) {
              await detail.onTapOption!();
            }
          },
          child: Text(detail.text!, style: TextStyle(color: Theme.of(context).colorScheme.surface),),
        );
      }).toList(),
      // if (buttonText1 != null && colorForButton1 != null)
      //   TextButton(
      //     onPressed: () => Navigator.pop(context, true),
      //     style: ButtonStyle(
      //       backgroundColor: WidgetStateProperty.all(colorForButton1),
      //     ),
      //     child: Text(buttonText1),
      //   ),
      // if (buttonText2 != null && colorForButton2 != null)
      //   TextButton(
      //     onPressed: () => Navigator.pop(context, false),
      //     style: ButtonStyle(
      //       backgroundColor: WidgetStateProperty.all(colorForButton2),
      //     ),
      //     child: Text(buttonText2),
      //   ),
    ),
  );
  // if (response) {
  //   await onTapOption1();
  // } else if (!response && onTapOption2 != null) {
  //   await onTapOption2();
  // }
}
