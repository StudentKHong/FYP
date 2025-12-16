import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropDownBox extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selectedValue;
  final ValueChanged onChanged;
  final bool isColumn;

  const CustomDropDownBox({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.isColumn = true,
  });

  List<Widget> _buildContent(BuildContext context) {
    return [
      Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
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
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.blue, width: 2),
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
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
          : Row(children: [Expanded(child: content[0]), const SizedBox(width: 10), Expanded(child: content[1])]),
    );
  }
}
