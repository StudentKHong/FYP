import 'package:flutter/material.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
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
  final String? contentToSuggestLabel;
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
    this.contentToSuggestLabel,
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
  bool generateLabelEnabled = false;

  @override
  void initState() {
    super.initState();

    selectedLabel = widget.initialLabel;
    print("INITIAL SWITCH STATE: ${widget.initialSwitchState}");
    // textController = TextEditingController(text: selectedLabel?.name);
    _loadLabels();
  }

  @override
  void didUpdateWidget(covariant CustomLabelEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSwitchState != widget.initialSwitchState) {
      setState(() {
        generateLabelEnabled = widget.initialSwitchState;
      });

      if (generateLabelEnabled) {
        _loadSuggested();
      }
    }
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
    if (widget.initialSwitchState &&
        widget.labelController.suggestedLabels.isEmpty &&
        widget.contentToSuggestLabel != null) {
      await widget.labelController.generateLabel(
        widget.type,
        widget.contentToSuggestLabel!,
      );
    }
  }

  Widget _buildBottomSheet({
    required List<Label> existing,
    required List<Label> suggested,
    required VoidCallback onSearch,
    required void Function(void Function()) modalSetState,
  }) {
    final query = _searchController.text.toLowerCase();
    final filteredExisting = existing
        .where((label) => label.name.toLowerCase().contains(query))
        .toList();

    final filteredSuggestion = suggested
        .where(
          (label) =>
              label.name.toLowerCase().contains(query) &&
              !existing.any((existing) => existing.name == label.name),
        )
        .toList();

    return DraggableScrollableSheet(
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
                _buildGenerateLabelSwitch(modalSetState: modalSetState),
              Divider(),
              CustomSearchBar(
                searchController: _searchController,
                onSearch: (_) => onSearch(),
              ),
              _buildCreateLabelOption(existing: existing, suggested: suggested),
              const SizedBox(height: 10),
              ..._buildSection(
                title: "Existing Labels",
                list: filteredExisting,
                chipAvatar: Icon(Icons.label, color: Colors.black),
                chipColor: Colors.green.shade300,
              ),
              const SizedBox(height: 10),
              ..._buildSection(
                title: "Suggested Labels",
                list: filteredSuggestion,
                chipAvatar: Icon(Icons.auto_awesome, color: Colors.black),
                chipColor: Colors.blue.shade300,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateLabelOption({
    required List<Label> existing,
    required List<Label> suggested,
  }) {
    return Builder(
      builder: (context) {
        final keyword = _searchController.text.trim();
        if (keyword.isEmpty) return SizedBox.shrink();

        final lowerKeyword = keyword.toLowerCase();
        final matchExisting = existing.any(
          (label) => label.name.toLowerCase().trim() == lowerKeyword,
        );
        final matchSuggested = suggested.any(
          (label) => label.name.toLowerCase().trim() == lowerKeyword,
        );

        if (!matchExisting && !matchSuggested) {
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
                  count: 0,
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
  }) {
    return [
      if (list.isNotEmpty)
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
      const SizedBox(height: 5),
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

  Widget _buildGenerateLabelSwitch({
    required void Function(void Function()) modalSetState,
  }) {
    // final labelController = widget.labelController;
    // final contentForLabelGeneration = widget.contentToSuggestLabel ?? "";

    return CustomSwitch(
      title: 'Generate Label',
      infoDescription:
          "Generate label using Artificial Intelligence (AI). Do not enable this if note contains personal information.",
      isTitleLeading: true,
      switchSize: Scale.medium,
      isToggled: generateLabelEnabled,
      onChanged: (value) async {
        // Update UI to display the suggested label.
        modalSetState(() {
          generateLabelEnabled = value;
          widget.onToggled.call(value);
        });
      },
      layout: LayoutMode.listTile,
    );
  }

  Future<void> _openLabelEditor() async {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final labelController = widget.labelController;
          final existingLabels = widget.type == ComponentType.note
              ? labelController.noteLabels
              : labelController.taskLabels;
          final newSuggestions = labelController.suggestedLabels;
          return _buildBottomSheet(
            existing: existingLabels,
            suggested: newSuggestions,
            onSearch: () => setState(() {}),
            modalSetState: setState,
          );
        },
      ),
    );

    await widget.onEditorOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Label', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10),
        ListTile(
          tileColor: Colors.grey,
          leading: Icon(Icons.label_outline),
          title: Text(
            selectedLabel?.name ?? "(None)",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: widget.isReadOnly ? Icon(Icons.lock) : Icon(Icons.edit),
          onTap: () => widget.isReadOnly ? null : _openLabelEditor(),
        ),
      ],
    );
  }
}
