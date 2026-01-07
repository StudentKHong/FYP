// ==================================================
// Program Name   : card.dart
// Purpose        : Reusable card widget for lists and previews
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 16 December 2025
// ==================================================

import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const CustomCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(),
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          child: Column(
            children: [
              Icon(icon, color: Colors.black,),
              const SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}