import 'package:flutter/material.dart';
import 'package:popover/popover.dart';

class Info {
  final String text;
  final int? maxLines;

  Info({required this.text, this.maxLines});
}

class CustomInfoButton extends StatelessWidget {
  final Color color;
  final List<Info> infoDetails;

  const CustomInfoButton({super.key, this.color = Colors.white, required this.infoDetails});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: color,
      onPressed: () {
        showPopover(
          context: context,
          bodyBuilder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...infoDetails.map((item) {
                      return Text(
                        item.text,
                        maxLines: item.maxLines ?? 1,
                        overflow: item.maxLines != null
                            ? TextOverflow.ellipsis
                            : null,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
          direction: PopoverDirection.bottom,
          arrowHeight: 8,
          arrowWidth: 5,
          arrowDyOffset: 3,
        );
      },
      icon: Icon(Icons.info_outline),
    );
  }
}
