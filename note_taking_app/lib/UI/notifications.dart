import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/notification_controller.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/extended_card.dart';
import 'package:note_taking_app/UI/SharedComponents/info_button.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();

    return Scaffold(
      appBar: CustomAppBar(
        titleText: "Notifications",
        actions: [
          CustomInfoButton(
            infoDetails: [
              Info(
                text:
                    "View all notifications. Notifications can be selected to view more details.",
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
      endDrawer: const HamburgerMenu(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(color: Colors.black),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notificationController.list.length,
                itemBuilder: (context, index) {
                  final notifications = notificationController.list;
                  final notification = notifications[index];

                  return CustomExtendedCard(
                    title: notification.title,
                    content: [notification.description],
                    iconButtons: [
                      !notification.isRead
                          ? IconButton(
                              onPressed: () async {
                                if (notification.id != null) {
                                  await notificationController.markReadStatus(
                                    notification.id!,
                                    true,
                                  );
                                }
                              },
                              icon: Icon(Icons.mark_email_unread_outlined),
                            )
                          : IconButton(
                              onPressed: () async {
                                if (notification.id != null) {
                                  await notificationController.markReadStatus(
                                    notification.id!,
                                    false,
                                  );
                                }
                              },
                              icon: Icon(Icons.mark_email_read),
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
