import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Model/Models/setting_model.dart';
import 'package:note_taking_app/Model/Repository/crud_repository.dart';
import 'package:note_taking_app/Service/offline_first_service.dart';

class SettingRepository {
  final AuthenticationController _authController =
      Get.find<AuthenticationController>();

  CollectionReference get collection {
    final uid = _authController.user.value?.uid;

    if (uid == null || uid.isEmpty) {
      throw Exception('Please login again to continue.');
    }
    return Repository.baseDocument(uid).collection('settings');
  }

  Future<Setting> get() async {
    final querySnapshot = await collection.get();
    final data = querySnapshot.docs.first;
    return Setting.fromFirestore(data);
  }

  Future<Setting> create(Setting setting) async {
    Map<String, dynamic> data = setting.toMap();
    data.remove('id');
    final documentReference = await collection.addOfflineSafe(data);
    final createdEntity = await documentReference.get();
    return Setting.fromFirestore(createdEntity);
  }

  Future<void> delete(String settingId) async {
    await collection.doc(settingId).delete();
  }

  Future<Setting> edit(Setting setting) async {
    final dataToUpdate = setting.toMap();
    final documentReference = collection.doc(dataToUpdate['id']);
    dataToUpdate.remove('id');
    documentReference.setOfflineSafe(dataToUpdate);
    final documentSnapshot = await documentReference.get();
    final updatedSetting = Setting.fromFirestore(documentSnapshot);

    return updatedSetting;
  }
}
