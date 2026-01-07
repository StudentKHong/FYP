// ==================================================
// Program Name   : setting_model.dart
// Purpose        : Data model for application/user settings
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Setting {
  final String? id;
  final bool darkMode;
  final bool notificationsEnabled;
  final int reminderOffset;
  final String offsetFrom;
  final bool autoLabelingEnabled;

  Setting({
    required this.id,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.reminderOffset,
    required this.offsetFrom,
    required this.autoLabelingEnabled,
  });

  factory Setting.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return Setting(
      id: documentSnapshot.id,
      darkMode: data['darkMode'] as bool,
      notificationsEnabled: data['notificationsEnabled'] as bool,
      reminderOffset: data['reminderOffset'] as int,
      offsetFrom: data['offsetFrom'] as String,
      autoLabelingEnabled: data['autoLabelingEnabled'] as bool
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'reminderOffset': reminderOffset,
      'offsetFrom': offsetFrom,
      'autoLabelingEnabled': autoLabelingEnabled
    };
  }

  Setting copyWith({
    String? title,
    bool? darkMode,
    bool? notificationsEnabled,
    int? reminderOffset,
    String? offsetFrom,
    bool? autoLabelingEnabled,
  }) {
    return Setting(
      id: id,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderOffset: reminderOffset ?? this.reminderOffset,
      offsetFrom: offsetFrom ?? this.offsetFrom,
      autoLabelingEnabled: autoLabelingEnabled ?? this.autoLabelingEnabled
    );
  }
}
