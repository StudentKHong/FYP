import 'package:note_taking_app/Model/Models/notification_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class NotificationRepository extends UserRepository {
  NotificationRepository()
    : super(
        collectionBuilder: (uid) =>
            Repository.baseDocument(uid).collection('notifications'),
        fromFirestore: (document) => AppNotification.fromFirestore(document),
      );

  Future<void> updateReadStatus(AppNotification notification) async {
    collection.doc(notification.id).setOfflineSafe({
      "isRead": notification.isRead,
    });
  }
}
