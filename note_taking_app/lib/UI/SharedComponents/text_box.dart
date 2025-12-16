import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final IconData? leadingIcon;
  final String? title;
  final bool withBorder;
  final int? maxLength;
  final int? maxLines;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isReadOnly;
  final String? hintText;
  final bool isPassword;
  final bool isTextHidden;
  final bool? isEditing;
  final VoidCallback? onEditToggle;
  final VoidCallback? onToggleVisibility;
  final bool isColumnLayout;

  const CustomTextField({
    super.key,
    this.leadingIcon,
    this.title,
    this.withBorder = true,
    this.maxLength,
    this.maxLines,
    this.controller,
    this.keyboardType,
    this.isReadOnly = false,
    this.hintText,
    this.isPassword = false,
    this.isTextHidden = false,
    this.isEditing,
    this.onEditToggle,
    this.onToggleVisibility,
    this.isColumnLayout = true,
  });

  Widget _getTitleWidget(BuildContext context) {
    return Text(
      title!,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium,
    );
  }

  Widget _getTextField(BuildContext context) {
    return TextField(
      obscureText: isTextHidden,
      controller: controller,
      onEditingComplete: () => FocusScope.of(context).nextFocus(),
      onSubmitted: (value) => FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        prefixIcon: leadingIcon != null ? Icon(leadingIcon) : null,
        hintText: hintText,
        enabledBorder: withBorder
            ? isReadOnly
                  ? OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    )
                  : OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    )
            : null,
        focusedErrorBorder: withBorder
            ? OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 5),
              )
            : null,
        border: withBorder ? OutlineInputBorder() : null,
        suffixIcon: () {
          // Show icon to inidicate text field is read only.
          if (isReadOnly) {
            return Icon(Icons.lock);
          }

          // Show visibility icon to indicate visibility of the contents in the text field.
          if (isPassword) {
            return IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                isTextHidden ? Icons.visibility_off : Icons.visibility,
              ),
            );
          }

          // Show edit and save icon.
          if (onEditToggle != null) {
            return IconButton(
              onPressed: onEditToggle,
              icon: Icon((isEditing ?? false) ? Icons.check : Icons.edit),
            );
          }
          return null;
        }(),
      ),
      maxLength: maxLength,
      maxLines: maxLines,
      readOnly: isReadOnly || (isEditing != null ? !isEditing!: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    if (title != null) {
      children.add(_getTitleWidget(context));
      children.add(const SizedBox(height: 8));
    }
    children.add(_getTextField(context));

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: children.length == 1
          ? children.first
          : isColumnLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
    );
  }
}
