import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

class SortOption {
  final SortType sortType;
  final String name;
  bool isAscending;

  SortOption({
    required this.sortType,
    required this.name,
    required this.isAscending,
  });
}

class SortPopUp<T extends BaseEntity> extends StatefulWidget {
  final Controller<T> controller;
  const SortPopUp({super.key, required this.controller});

  @override
  State<SortPopUp> createState() => _SortPopUpState();
}

class _SortPopUpState<T extends BaseEntity> extends State<SortPopUp<T>> {
  late List<SortOption> sortOptions;

  @override
  void initState() {
    super.initState();

    sortOptions = _getSortOptions();
    if (widget.controller.currentSort.value == null) {
      widget.controller.currentSort.value = ComponentSort<T>();
    }
  }

  List<SortOption> _getSortOptions() {
    return SortType.values.map((sortType) {
      switch (sortType) {
        case SortType.name:
          return SortOption(
            sortType: sortType,
            name: 'Name',
            isAscending: true,
          );
        case SortType.dateCreated:
          return SortOption(
            sortType: sortType,
            name: 'Date Created',
            isAscending: false,
          );
      }
    }).toList();
  }

  Widget _buildOptionWidget(SortOption sortOption) {
    return Obx(() {
      final currentSort = widget.controller.currentSort.value;
      final defaultValue = sortOption.isAscending;
      bool? isAscending;
      switch (sortOption.sortType) {
        case SortType.name:
          isAscending = currentSort?.name;
          break;
        case SortType.dateCreated:
          isAscending = currentSort?.dateCreated;
          break;
      }

      return ListTile(
        title: Text(
          sortOption.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: Icon(
          isAscending ?? defaultValue ? Icons.arrow_upward : Icons.arrow_downward,
        ),
        onTap: () {
          setState(() {
            sortOption.isAscending = !sortOption.isAscending;
            final currentSort = widget.controller.currentSort.value!;

            currentSort.name = null;
            currentSort.dateCreated = null;

            // Update current sort.
            switch (sortOption.sortType) {
              case SortType.name:
                currentSort.name = sortOption.isAscending;
                break;
              case SortType.dateCreated:
                currentSort.dateCreated = sortOption.isAscending;
                break;
            }

            widget.controller.sort();
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort By',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...sortOptions.map((sortOption) => _buildOptionWidget(sortOption)),
          ],
        ),
      ),
    );
  }
}
