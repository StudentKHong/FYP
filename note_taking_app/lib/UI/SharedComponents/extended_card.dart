import 'package:flutter/material.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

class CustomExtendedCard extends StatelessWidget {
  final String? title; // Title (left-aligned after icon)
  final Status? status;
  final List<String>? content; // Content (left-aligned, below title)
  final List<IconButton>? iconButtons; // Icon Buttons (right-top-aligned)
  final List<String>? otherDetails; // Other details (right-bottom-aligned)
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CustomExtendedCard({
    super.key,
    this.title,
    this.status,
    this.content,
    this.iconButtons,
    this.otherDetails,
    this.onTap,
    this.onLongPress
  });

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.pending:
        return Colors.grey.shade300;
      case Status.inProgress:
        return Colors.yellow;
      case Status.completed:
        return Colors.green.shade300;
      default:
        return Colors.blue.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Card(
        color: Colors.grey.shade400,
        shape: RoundedRectangleBorder(
          side: BorderSide(),
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left-aligned widgets. (Title + content)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title!,
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (status != null)
                              Container(
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status!.name,
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(color: Colors.black),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (content != null)
                        ...content!.map(
                          (item) => Text(
                            item,
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(color: Colors.grey.shade800),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                // Right-aligned widgets (Icon Buttons + Other Details)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (iconButtons != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: iconButtons!.map((button) {
                          return SizedBox(width: 30, height: 30, child: button);
                        }).toList(),
                      ),
                    if (otherDetails != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: otherDetails!
                            .map(
                              (item) => Text(
                                item,
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(color: Colors.grey.shade800),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
