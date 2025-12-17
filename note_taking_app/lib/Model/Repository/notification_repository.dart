import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  String? get orderByField => "notifiedAt";

  @override
  Stream<List<AppNotification>> watchAll() {
    Query query = collection;

    query = query.where('notifiedAt', isLessThanOrEqualTo: DateTime.now());
    if (orderByField != null) {
      query = query.orderBy(orderByField!, descending: true);
    }

    return query
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) =>
              snapshot.docs.map(AppNotification.fromFirestore).toList(),
        );
  }

  @override
  Stream<int> watchAllCount() {
    return collection
        .where('notifiedAt', isLessThanOrEqualTo: DateTime.now())
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> updateReadStatus(AppNotification notification) async {
    collection.doc(notification.id).setOfflineSafe({
      "isRead": notification.isRead,
    });
  }
}
