// ==================================================
// Program Name   : toggle_button.dart
// Purpose        : Toggle button component used in various editors
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 23 December 2025
// ==================================================

import 'package:flutter/material.dart';
import 'package:note_taking_app/UI/SharedComponents/info_button.dart';

enum Scale { small, medium, big }

enum LayoutMode { listTile, row }

class CustomSwitch extends StatefulWidget {
  final String title;
  final String? infoDescription;
  final Color textColor;
  final bool isTitleLeading;
  final Scale switchSize;
  final bool isToggled;
  final ValueChanged<bool>? onChanged;
  final LayoutMode layout;

  const CustomSwitch({
    super.key,
    required this.title,
    this.infoDescription,
    this.textColor = Colors.black,
    required this.isTitleLeading,
    this.switchSize = Scale.medium,
    required this.isToggled,
    this.onChanged,
    this.layout = LayoutMode.row,
  });

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  final Map<Scale, double> size = {
    Scale.small: 0.5,
    Scale.medium: 1.0,
    Scale.big: 1.5,
  };

  Widget _buildSwitch() {
    return Transform.scale(
      scale: size[widget.switchSize],
      child: Switch(value: widget.isToggled, onChanged: widget.onChanged),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: widget.textColor),
        ),
        const SizedBox(width: 5),
        if (widget.infoDescription != null)
          CustomInfoButton(
            infoDetails: [Info(text: widget.infoDescription!, maxLines: 3)],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.layout == LayoutMode.row
        ? Row(
            children: [
              if (widget.isTitleLeading) ...[
                _buildTitle(),
                _buildSwitch(),
              ] else ...[
                _buildSwitch(),
                const SizedBox(width: 10),
                _buildTitle(),
              ],
            ],
          )
        : ListTile(
            leading: widget.isTitleLeading ? _buildTitle() : _buildSwitch(),
            title: !widget.isTitleLeading ? _buildTitle() : null,
            trailing: widget.isTitleLeading ? _buildSwitch() : null,
          );
  }
}
