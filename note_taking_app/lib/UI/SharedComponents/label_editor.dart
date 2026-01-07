// ==================================================
// Program Name   : label_editor.dart
// Purpose        : Inline editor widget for adding/removing labels
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 24 December 2025
// ==================================================

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/UI/SharedComponents/loading_state.dart';
import 'package:note_taking_app/UI/SharedComponents/search.dart';
import 'package:note_taking_app/UI/SharedComponents/toggle_button.dart';

class CustomLabelEditor extends StatefulWidget {
  final Label? initialLabel;
  final ComponentType type;
  final LabelController labelController;
  final ValueChanged<Label>? onTagsChanged;
  final bool isReadOnly;

  // Parameters for auto-generation labels.
  final bool withGenerateLabelSwitch;
  final bool initialSwitchState;
  final ValueChanged<bool> onToggled;
  final QuillController? contentController;
  final TextEditingController? textContentController;
  // final String? contentToSuggestLabel;
  final Future<void> Function()? onEditorOpened;

  const CustomLabelEditor({
    super.key,
    this.initialLabel,
    required this.type,
    required this.labelController,
    this.onTagsChanged,
    this.isReadOnly = false,
    required this.withGenerateLabelSwitch,
    this.initialSwitchState = false,
    required this.onToggled,
    this.contentController,
    this.textContentController,
    // this.contentToSuggestLabel,
    this.onEditorOpened,
  });

  @override
  State<CustomLabelEditor> createState() => _CustomLabelEditorState();
}

class _CustomLabelEditorState extends State<CustomLabelEditor> {
  // late TextEditingController textController;
  final TextEditingController _searchController = TextEditingController();
  late Label? selectedLabel;
  // bool isProgrammaticallyChanged = false;
  late RxBool generateLabelEnabled;

  @override
  void initState() {
    super.initState();

    selectedLabel = widget.initialLabel;
    generateLabelEnabled = (widget.initialSwitchState).obs;
    print("INITIAL SWITCH STATE: ${widget.initialSwitchState}");
    // textController = TextEditingController(text: selectedLabel?.name);
    _loadLabels();
  }

  @override
  void didUpdateWidget(covariant CustomLabelEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if (oldWidget.initialSwitchState != widget.initialSwitchState) {
    //   setState(() {
    //     generateLabelEnabled = widget.initialSwitchState;
    //   });

    //   if (generateLabelEnabled) {
    //     _loadSuggested();
    //   }
    // }
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

  Future<void> _loadSuggested() async {
    final content =
        widget.contentController?.document.toPlainText().trim() ??
        widget.textContentController?.text ??
        "";
    final suggestedList = widget.labelController.suggestedLabels;
    print("--- [DEBUG] _loadSuggested check ---");
    print("1. generateLabelEnabled: $generateLabelEnabled");
    print(
      "2. suggestedLabels.isEmpty: ${suggestedList.isEmpty} (Current count: ${suggestedList.length})",
    );
    print("3. content.isNotEmpty: ${content.isNotEmpty}");

    if (generateLabelEnabled.value && content.isNotEmpty) {
      await widget.labelController.generateLabel(widget.type, content);
    }
  }

  Widget _buildBottomSheet({
    required VoidCallback onSearch,
    required void Function(void Function()) modalSetState,
  }) {
    final labelController = widget.labelController;

    final newSuggestions = labelController.suggestedLabels;

    final content =
        widget.contentController?.document.toPlainText().trim() ??
        widget.textContentController?.text ??
        "";

    // final filteredSuggestion = query.isEmpty
    //     ? newSuggestions
    //     : newSuggestions
    //           .where(
    //             (label) =>
    //                 label.name.toLowerCase().contains(query) &&
    //                 !existingLabels.any(
    //                   (existing) => existing.name == label.name,
    //                 ),
    //           )
    //           .toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 0.5,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.withGenerateLabelSwitch)
                  Obx(
                    () => CustomSwitch(
                      title: 'Generate Label',
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      infoDescription:
                          "Generate label using Artificial Intelligence (AI). Do not enable this if note contains personal information.",
                      isTitleLeading: true,
                      switchSize: Scale.medium,
                      isToggled: generateLabelEnabled.value,
                      onChanged: (value) async {
                        // Update UI to display the suggested label.
                        generateLabelEnabled.value = value;
                        widget.onToggled.call(value);

                        if (value) {
                          await _loadSuggested();
                        }
                      },
                      layout: LayoutMode.listTile,
                    ),
                  ),
                Divider(),
                CustomSearchBar(
                  searchController: _searchController,
                  onSearch: (_) => onSearch(),
                ),
                Obx(() {
                  final existingLabels = widget.type == ComponentType.note
                      ? labelController.noteLabels
                      : labelController.taskLabels;
                  final query = _searchController.text.toLowerCase();
                  final filteredExisting = existingLabels
                      .where(
                        (label) => label.name.toLowerCase().contains(query),
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreateLabelOption(
                        existing: existingLabels,
                        suggested: newSuggestions,
                      ),
                      const SizedBox(height: 10),
                      ..._buildSection(
                        title: "Existing Labels",
                        list: filteredExisting,
                        chipAvatar: Icon(Icons.label, color: Colors.black),
                        chipColor: Colors.green.shade300,
                        isLoading: false,
                      ),
                      const SizedBox(height: 10),
                      if (generateLabelEnabled.value && content.isNotEmpty)
                        ..._buildSection(
                          title: "Suggested Labels",
                          list: labelController.suggestedLabels,
                          chipAvatar: Icon(
                            Icons.auto_awesome,
                            color: Colors.black,
                          ),
                          chipColor: Colors.blue.shade300,
                          isLoading: labelController.isLoading.value,
                        ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateLabelOption({
    required List<Label> existing,
    required List<Label> suggested,
  }) {
    return Builder(
      builder: (context) {
        final keyword = _searchController.text.trim();
        print("Search keyword: $keyword");
        if (keyword.isEmpty) return SizedBox.shrink();

        final lowerKeyword = keyword.toLowerCase();
        final matchExisting = existing.any(
          (label) => label.name.toLowerCase().trim() == lowerKeyword,
        );

        final matchSuggested = suggested.any(
          (label) => label.name.toLowerCase().trim() == lowerKeyword,
        );
        print(
          "Match existing: $matchExisting, Match suggested: $matchSuggested",
        );

        if (!matchExisting && !matchSuggested) {
          print("Triggered 'Create New Label'...");
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(Icons.add),
              title: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(text: "Create new label: "),
                    TextSpan(
                      text: keyword,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              onTap: () {
                final label = Label(
                  id: UniqueKey().toString(),
                  name: keyword,
                  type: widget.type,
                  count: 1,
                );
                setState(() {
                  selectedLabel = label;
                });
                widget.onTagsChanged?.call(label);
                Navigator.pop(context);
              },
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  List<Widget> _buildSection({
    required String title,
    required List<Label> list,
    required Widget chipAvatar,
    required Color chipColor,
    required bool isLoading,
  }) {
    return [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      if (isLoading)
        LoadingIndicator(color: Theme.of(context).colorScheme.primary)
      else
        Wrap(
          children: list
              .map(
                (label) => ActionChip(
                  avatar: chipAvatar,
                  label: Text(
                    label.name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(color: Colors.black),
                  ),
                  backgroundColor: chipColor,
                  onPressed: () {
                    setState(() {
                      selectedLabel = label;
                    });
                    widget.onTagsChanged?.call(label);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
    ];
  }

  // Widget _buildGenerateLabelSwitch({
  //   required void Function(void Function()) modalSetState,
  // }) {
  //   // final labelController = widget.labelController;
  //   // final contentForLabelGeneration = widget.contentToSuggestLabel ?? "";

  //   return CustomSwitch(
  //     title: 'Generate Label',
  //     textColor: Theme.of(context).colorScheme.onPrimary,
  //     infoDescription:
  //         "Generate label using Artificial Intelligence (AI). Do not enable this if note contains personal information.",
  //     isTitleLeading: true,
  //     switchSize: Scale.medium,
  //     isToggled: generateLabelEnabled.value,
  //     onChanged: (value) async {
  //       // Update UI to display the suggested label.
  //       generateLabelEnabled.value = value;
  //       widget.onToggled.call(value);

  //       if (value) {
  //         await _loadSuggested();
  //       }
  //     },
  //     layout: LayoutMode.listTile,
  //   );
  // }

  Future<void> _openLabelEditor() async {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return _buildBottomSheet(
              onSearch: () => modalSetState(() {}),
              modalSetState: modalSetState,
            );
          },
        );
      },
    );

    await widget.onEditorOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.grey,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(Icons.label_outline, color: Colors.black),
        title: Text(
          (selectedLabel?.name.isNotEmpty ?? false)
              ? selectedLabel!.name
              : "(None)",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: widget.isReadOnly
            ? Icon(Icons.lock, color: Colors.black)
            : Icon(Icons.edit, color: Colors.black),
        onTap: () => widget.isReadOnly ? null : _openLabelEditor(),
      ),
    );
  }
}
