import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';

class CustomLabelEditor extends StatefulWidget {
  final Label? initialLabel;
  final ComponentType? type;
  final LabelController labelController;
  final ValueChanged<Label>? onTagsChanged;
  final bool isReadOnly;
  const CustomLabelEditor({
    super.key,
    this.initialLabel,
    this.type,
    required this.labelController,
    this.onTagsChanged,
    this.isReadOnly = false,
  });

  @override
  State<CustomLabelEditor> createState() => _CustomLabelEditorState();
}

class _CustomLabelEditorState extends State<CustomLabelEditor> {
  late TextEditingController textController;
  late Label? selectedLabel;
  bool isProgrammaticallyChanged = false;

  @override
  void initState() {
    super.initState();

    print("Initial label: ${widget.initialLabel}");
    selectedLabel = widget.initialLabel;
    print("Selected label: $selectedLabel");
    textController = TextEditingController(text: selectedLabel?.name);
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    if (widget.type == ComponentType.note) {
      widget.labelController.getNoteLabels();
    } else if (widget.type == ComponentType.task) {
      widget.labelController.getTaskLabels();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display static text field when is read only.
    if (widget.isReadOnly) {
      return TextField(
        controller: textController,
        readOnly: widget.isReadOnly,
        decoration: InputDecoration(
          labelText: "Label",
          border: const OutlineInputBorder(),
          suffixIcon: widget.isReadOnly ? Icon(Icons.lock) : null
        ),
      );
    }

    // Gather label lists.
    final labelController = widget.labelController;
    final existingLabels = widget.type == ComponentType.note
        ? labelController.noteLabels
        : labelController.taskLabels;

    final newSuggestions = labelController.suggestedLabels;

    // Display label editor if is not read only.
    return SizedBox(
      width: double.infinity,
      child: TypeAheadField<Label>(
        controller: textController,
        builder: (context, controller, focusNode) {
          if (selectedLabel != null && controller.text.isEmpty) {
            controller.text = selectedLabel!.name;
          }

          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: "Label",
              border: const OutlineInputBorder(),
            ),
          );
        },
        emptyBuilder: (context) {
          final labelName = textController.text.trim();

          final existingLabels =
              (widget.type == ComponentType.note
                      ? labelController.noteLabels
                      : labelController.taskLabels)
                  .toList();
          final newSuggestions = labelController.suggestedLabels.toList();

          final allLabels = [...existingLabels, ...newSuggestions];
          final isExisting = allLabels.any(
            (label) =>
                label.name.toLowerCase().contains(labelName.toLowerCase()),
          );
          // print(labelName.isEmpty);
          if (labelName.isEmpty || isExisting) {
            return const SizedBox.shrink();
          }

          final tempLabel = Label(
            id: UniqueKey().toString(),
            name: labelName,
            type: widget.type,
            count: 0,
          );
          return ListTile(
            leading: const Icon(Icons.new_label_outlined),
            title: Text("Create ${tempLabel.name}"),
            tileColor: Colors.yellow,
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              final newLabel = await labelController.create(tempLabel);
              if (labelController.errorMessage.value.isNotEmpty) {
                CustomDialog.showError(
                  "Error",
                  labelController.errorMessage.value,
                );
                return;
              }
              setState(() {
                selectedLabel = newLabel;
                textController.text = newLabel!.name;
              });

              widget.onTagsChanged?.call(newLabel!);
            },
          );
        },
        itemBuilder: (context, value) {
          final newSuggestions = labelController.suggestedLabels;

          bool isNewSuggestion =
              newSuggestions.toList().any(
                (label) => label.name == value.name,
              ) &&
              !existingLabels.toList().any((label) => label.name == value.name);

          Color labelColor = isNewSuggestion ? Colors.blue : Colors.green;
          Icon icon = isNewSuggestion
              ? const Icon(Icons.new_label_outlined)
              : const Icon(Icons.label);

          return ListTile(
            tileColor: labelColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            leading: icon,
            title: Text(
              isNewSuggestion ? "AI Suggestion: ${value.name}" : value.name,
            ),
          );
        },
        onSelected: (suggestion) async {
          isProgrammaticallyChanged = true;
          textController.text = suggestion.name;
          isProgrammaticallyChanged = false;

          setState(() {
            selectedLabel = existingLabels.toList().firstWhere(
              (label) => label.name == suggestion.name,
              orElse: () => suggestion,
            );
          });

          if (!existingLabels.toList().any(
            (label) => label.name == suggestion.name,
          )) {
            selectedLabel = await labelController.create(suggestion);
          } else {
            selectedLabel = suggestion;
          }
          widget.onTagsChanged?.call(selectedLabel!);

          if (mounted) {
            Future.delayed(Duration(milliseconds: 10), () {
              if (mounted) FocusScope.of(context).unfocus();
            });
          }
        },
        suggestionsCallback: (suggestion) {
          if (suggestion.isEmpty) {
            return [];
          }
          final lowerSuggestion = suggestion.toLowerCase();

          final existingMatches = existingLabels
              .toList()
              .where(
                (label) => label.name.toLowerCase().contains(lowerSuggestion),
              )
              .toList();

          final aiMatches = newSuggestions
              .where(
                (label) =>
                    label.name.toLowerCase().contains(lowerSuggestion) &&
                    !existingMatches.any(
                      (existing) =>
                          existing.name.toLowerCase() ==
                          label.name.toLowerCase(),
                    ),
              )
              .toList();

          return [...existingMatches, ...aiMatches];
        },
      ),
    );

    // return Opacity(
    //   opacity: widget.isReadOnly ? 0.6 : 1.0,
    //   child: IgnorePointer(
    //     ignoring: widget.isReadOnly,
    //     child: Autocomplete<String>(
    //       optionsBuilder: (textEditingValue) {
    //         if (textEditingValue.text.isEmpty) {
    //           return existingLabelNames;
    //         }
    //         return existingLabelNames.where(
    //           (option) => option.toLowerCase().contains(
    //             textEditingValue.text.toLowerCase(),
    //           ),
    //         );
    //       },
    //       // TODO: Introduce AI labels if enabled.
    //       onSelected: (value) {
    //         // Set the current label to the latest selected label.
    //         if (!widget.isReadOnly) {
    //           final label = widget.newSuggestions.firstWhere(
    //             (label) => label.name == value,
    //             orElse: () => Label(
    //               id: UniqueKey().toString(),
    //               name: value,
    //               type: widget.type,
    //               count: 0,
    //             ),
    //           );
    //           setState(() {
    //             selectedLabel = label;
    //           });
    //           widget.onTagsChanged?.call(label);
    //         }
    //       },
    //       fieldViewBuilder:
    //           (context, textEditingController, focusNode, onFieldSubmitted) {
    //             if (!focusNode.hasFocus && selectedLabel != null) {
    //               textEditingController.text = selectedLabel!.name;
    //             }

    //             return TextField(
    //               controller: textEditingController,
    //               focusNode: focusNode,
    //               onSubmitted: (_) => onFieldSubmitted,
    //               decoration: InputDecoration(
    //                 labelText: "Label",
    //                 border: OutlineInputBorder(),
    //                 suffixIcon: IconButton(
    //                   icon: Icon(focusNode.hasFocus ? Icons.arrow_drop_up : Icons.arrow_drop_down),
    //                   onPressed: () {
    //                     if (focusNode.hasFocus) {
    //                       focusNode.unfocus();
    //                     } else {
    //                       textEditingController.clear();
    //                       focusNode.requestFocus();
    //                     }
    //                   },
    //                 ),
    //               ),
    //             );
    //           },
    //       optionsViewBuilder: (context, onSelected, options) {
    //         return Material(
    //           child: SizedBox(
    //             height: 100,
    //             child: ListView.builder(
    //               itemCount: options.length,
    //               itemBuilder: (context, index) {
    //                 final option = options.elementAt(index);
    //                 return ListTile(
    //                   onTap: () => onSelected(option),
    //                   title: Text(option),
    //                 );
    //               },
    //             ),
    //           ),
    //         );
    //       },
    //     ),
    //   ),
    // );
  }
}
