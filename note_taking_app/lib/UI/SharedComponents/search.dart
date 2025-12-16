import 'dart:async';

import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final void Function(String keyword) onSearch;
  const CustomSearchBar({super.key, required this.searchController, required this.onSearch});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  Timer? _debounce;
  
  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: widget.searchController,
      leading: Icon(Icons.search),
      hintText: 'Enter a keyword...',
      onChanged: (value) {
        if (_debounce?.isActive ?? false) {
          _debounce!.cancel();
        }

        _debounce = Timer(Duration(milliseconds: 500), () {
          widget.onSearch(value);
        });
      },
      onSubmitted: widget.onSearch
    );
  }
}
