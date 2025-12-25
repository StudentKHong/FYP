import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';

class FilterPopUp<T extends FilterableEntity> extends StatefulWidget {
  final Controller<T> controller;
  final ComponentType forComponentType;
  const FilterPopUp({
    super.key,
    required this.controller,
    required this.forComponentType,
  });

  @override
  State<FilterPopUp<T>> createState() => _FilterPopUpState<T>();
}

class _FilterPopUpState<T extends FilterableEntity>
    extends State<FilterPopUp<T>> {
  final LabelController _labelController = Get.find<LabelController>();
  late final Controller<T> _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;
    _labelController.getNoteLabels();
    _labelController.getTaskLabels();

    // // Get NoteController or TaskController
    // if (T == Note) {
    //   _noteTaskController = Get.find<NoteController>();
    // } else if (T == Task) {
    //   _noteTaskController = Get.find<TaskController>();
    // }

    // Fetch labels.
    // _getLabels();
  }

  // Future<void> _getLabels() async {
  //   List<String> labels = [];
  //   if (T == Note) {
  //     await _countController.getNoteLabels();
  //     labels = _countController.noteLabels
  //         .map((label) => label['name'] as String)
  //         .toList();
  //   } else if (T == Task) {
  //     await _countController.getTaskLabels();
  //     labels = _countController.taskLabels
  //         .map((label) => label['name'] as String)
  //         .toList();
  //   }
  //   setState(() {
  //     _labels = labels;
  //   });
  // }

  List<FilterChip>? _getLabelFilterChips() {
    final currentFilter = _controller.currentFilter.value;

    final List<Label> labels = widget.forComponentType == ComponentType.note
        ? _labelController.noteLabels
        : _labelController.taskLabels;

    if (labels.isEmpty || currentFilter == null) {
      return null;
    }
    print("Building chips. LabelIds: ${currentFilter.labelNames}");

    return labels.map((option) {
      final labelId = option.id;
      final labelName = option.name;
      final isSelected = currentFilter.labelNames?.contains(labelId) ?? false;
      print("Label: $labelName, isSelected: $isSelected");

      return FilterChip(
        label: Text(labelName),
        selected: isSelected,
        selectedColor: Theme.of(context).colorScheme.primary.withAlpha(20),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        onSelected: (value) {
          print("Clicked $labelName, value: $value");
          if (labelId == null) return;

          final filter = _controller.currentFilter.value;
          if (filter == null) return;
          filter.labelNames ??= [];

          setState(() {
            if (value) {
              if (!filter.labelNames!.contains(labelId)) {
                _controller.currentFilter.value!.labelNames!.add(labelId);
              }
            } else {
              _controller.currentFilter.value!.labelNames!.remove(labelId);
            }
            print("After update. LabelIds: ${filter.labelNames}");
          });

          // setState(() {});
          // _controller.currentFilter.refresh();
        },
      );
    }).toList();
  }

  List<FilterChip>? _getStatusFilterChips() {
    final ComponentFilter<T>? filter = _controller.currentFilter.value;
    if (filter != null && filter is TaskFilter) {
      return Status.values.map((option) {
        final selectedStatus = option.name.toString();
        final isSelected =
            (filter as TaskFilter).status?.contains(selectedStatus) ?? false;

        return FilterChip(
          label: Text(selectedStatus),
          selectedColor: Theme.of(context).colorScheme.primary.withAlpha(20),
          checkmarkColor: Theme.of(context).colorScheme.primary,
          selected: isSelected,
          onSelected: (value) {
            (filter as TaskFilter).status ??= [];
            setState(() {
              if (value) {
                (filter as TaskFilter).status?.add(selectedStatus);
              } else {
                (filter as TaskFilter).status?.remove(selectedStatus);
              }
            });

            // setState(() {});
            // _controller.currentFilter.refresh();
          },
        );
      }).toList();
    }
    return null;
  }

  Future<void> _dateTimePicker(bool isDateCreated) async {
    // Assumes date time picker is for date created and date modified only.
    final today = DateTime.now();
    final selectedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 100, today.month, today.day),
      lastDate: DateTime(today.year + 100, today.month, today.day),
    );
    if (selectedDateRange == null) return;
    final adjustedDateRange = DateTimeRange(
      start: selectedDateRange.start,
      end: selectedDateRange.end.add(
        Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
      ),
    );
    setState(() {
      if (isDateCreated) {
        _controller.currentFilter.value?.dateCreated = adjustedDateRange;
      } else {
        _controller.currentFilter.value?.dateModified = adjustedDateRange;
      }
    });
  }

  String _dateInText(bool isDateCreated) {
    final filters = _controller.currentFilter.value;
    if (isDateCreated) {
      if (filters == null || filters.dateCreated == null) {
        return "";
      } else {
        return "${filters.dateCreated!.start.day}/${filters.dateCreated!.start.month}/${filters.dateCreated!.start.year} - ${filters.dateCreated!.end.day}/${filters.dateCreated!.end.month}/${filters.dateCreated!.end.year}";
      }
    } else {
      if (filters == null || filters.dateModified == null) {
        return "";
      }
      return "${filters.dateModified!.start.day}/${filters.dateModified!.start.month}/${filters.dateModified!.start.year} - ${filters.dateModified!.end.day}/${filters.dateModified!.end.month}/${filters.dateModified!.end.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_getLabelFilterChips() != null) ...[
              // Labels filter with FilterChips to select multiple labels.
              Text('Labels', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 5),
              Wrap(spacing: 10, children: _getLabelFilterChips()!),
              const SizedBox(height: 10),
            ],

            // Date created filters with DateRangePicker
            Text('Date Created', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 5),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              trailing: Icon(Icons.calendar_month),
              title: Obx(() => Text(_dateInText(true))),
              onTap: () => _dateTimePicker(true),
            ),
            const SizedBox(height: 10),

            // Date modified filters with DateRangePicker
            Text(
              'Date Modified',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 5),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              trailing: Icon(Icons.calendar_month),
              title: Text(_dateInText(false)),
              onTap: () => _dateTimePicker(false),
            ),
            const SizedBox(height: 10),

            // Status filter with DropDownButton.
            // Only for task.
            if (widget.forComponentType == ComponentType.task) ...[
              Text('Status', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 5),
              Wrap(spacing: 10, children: _getStatusFilterChips()!),
              const SizedBox(height: 10),
            ],

            // Button to apply filters.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.currentFilter.value != null) {
                    if (!_controller.currentFilter.value!.isEmpty) {
                      _controller.filter();
                    }
                  }
                  Navigator.pop(context);
                },
                child: Text('Apply'),
              ),
            ),

            // Button to revert filters.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.grey.shade400),
                ),
                onPressed: () {
                  _controller.resetFilter();

                  Navigator.pop(context);
                },
                child: Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
