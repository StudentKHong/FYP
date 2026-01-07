// ==================================================
// Program Name   : drop_down_button.dart
// Purpose        : Custom drop-down button component used in forms
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 23 December 2025
// ==================================================

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropDownBox extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<String> items;
  final String selectedValue;
  final ValueChanged? onChanged;
  final bool isColumn;

  const CustomDropDownBox({
    super.key,
    required this.title,
    this.titleColor = Colors.black,
    required this.items,
    required this.selectedValue,
    this.onChanged,
    this.isColumn = true,
  });

  List<Widget> _buildContent(BuildContext context) {
    return [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(color: titleColor),
      ),
      DropdownButton2(
        isExpanded: true,
        value: selectedValue,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.visible,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        disabledHint: Text(
          selectedValue,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: Colors.grey.shade400),
        ),
        buttonStyleData: ButtonStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.blue, width: 2),
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          width: 150
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: isColumn
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            )
          : Row(
              children: [
                Expanded(child: content[0]),
                const SizedBox(width: 10),
                Expanded(child: content[1]),
              ],
            ),
    );
  }
}
