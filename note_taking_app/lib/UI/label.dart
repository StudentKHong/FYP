// ==================================================
// Program Name   : label.dart
// Purpose        : UI for displaying and selecting labels
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:note_taking_app/Controller/base_controller.dart';
// import 'package:note_taking_app/Controller/note_controller.dart';
// import 'package:note_taking_app/Controller/task_controller.dart';
// import 'package:note_taking_app/Model/Models/entity_model.dart';
// import 'package:note_taking_app/Model/Models/label_model.dart';
// import 'package:note_taking_app/Model/Models/note_model.dart';
// import 'package:note_taking_app/Model/Models/task_model.dart';
// import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
// import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
// import 'package:note_taking_app/UI/SharedComponents/search.dart';
// import 'package:note_taking_app/UI/create_note.dart';

// class LabelScreen<T extends BaseEntity> extends StatefulWidget {
//   final Label label;
//   final Controller<T> controller;
//   const LabelScreen({super.key, required this.label, required this.controller});

//   @override
//   State<LabelScreen> createState() => _LabelScreenState<T>();
// }

// class _LabelScreenState<T extends BaseEntity> extends State<LabelScreen<T>> {
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.label.id != null) {
//       if (T is Note) {
//         (widget.controller as NoteController).getByLabel(widget.label.id!);
//       } else if (T is Task) {
//         (widget.controller as TaskController).getByLabel(widget.label.id!);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(titleText: widget.label.name),
//       endDrawer: const HamburgerMenu(),
//       body: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Column(
//           children: [
//             CustomSearchBar(
//               searchController: _searchController,
//               onSearch: (value) => widget.controller.search(value),
//             ),
//             const SizedBox(height: 5),
//             Expanded(
//               child: Obx(
//                 () => ListView.builder(
//                   itemCount: widget.controller.filteredList.length,
//                   itemBuilder: (context, index) {
//                     final item = widget.controller.filteredList[index];
//                     final isFilterable = item is FilterableEntity;
//                     String dateCreated = '';
//                     if (isFilterable &&
//                         (item as FilterableEntity).dateCreated != null) {
//                       dateCreated = DateFormat.yMd().format(item.dateCreated!);
//                     }
//                     final labelName =
//                         isFilterable && (item as FilterableEntity).label != null
//                         ? item.label!.name
//                         : '';

//                     return CustomExtendedCard(
//                       title: item.name,
//                       status: item is Task ? item.status : null,
//                       content: [item.description ?? '', dateCreated],
//                       otherDetails: [labelName],
//                       onTap: () => Get.to(CreateEditNoteScreen(mode: mode)),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
