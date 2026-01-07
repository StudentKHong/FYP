// ==================================================
// Program Name   : search.dart
// Purpose        : Search input and utility widget used across lists
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 23 December 2025
// ==================================================

import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final void Function(String keyword) onSearch;
  const CustomSearchBar({
    super.key,
    required this.searchController,
    required this.onSearch,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      backgroundColor: WidgetStatePropertyAll(Colors.white),
      elevation: WidgetStatePropertyAll(2),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Colors.grey,
        ),
      ),
      controller: widget.searchController,
      leading: Icon(Icons.search),
      hintText: 'Enter a keyword...',
      onChanged: (value) {
        widget.onSearch(value);
      },
      onSubmitted: widget.onSearch,
    );
  }
}
