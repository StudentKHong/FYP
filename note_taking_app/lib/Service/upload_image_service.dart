import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Service/conectivity_service.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class UploadImageService extends GetxService {
  final _queue = <Map<String, String>>[].obs;
  final _queueFileName = 'pending_image_uploads.json';
  final NoteController noteController = Get.find<NoteController>();
  final ConnectivityService connectivityService = Get.find<ConnectivityService>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadQueue();
    _listenToConnectionChanges();
    await _attemptUpload();
  }

  Future<void> queueUpload({
    required String localPath,
    required String noteId,
  }) async {
    final entry = {
      "localPath": localPath,
      "noteId": noteId,
      "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
    };
    _queue.add(entry);
  }

  Future<void> _attemptUpload() async {
    // Check if connected to Internet.
    if (!connectivityService.isOnline.value) return;

    final dataToUpload = List<Map<String, String>>.from(_queue);

    // Retrieve data from queue.
    for (final data in dataToUpload) {
      final localPath = data["localPath"];
      final noteId = data["noteId"];

      if (localPath != null && noteId != null) {
        final file = File(localPath);
        if (!await file.exists()) {
          _queue.remove(data);
          continue;
        }
        
        // Upload image to Firebase Storage.
        // Remove data from queue if successful.
        try {
          final fileName = basename(localPath);
          final storageReference = FirebaseStorage.instance
              .ref()
              .child('note_images')
              .child('${DateTime.now().millisecondsSinceEpoch}_$fileName}');
          await storageReference.putFile(file);
          final downloadUrl = await storageReference.getDownloadURL();

          await _replaceImageWithUrl(
            noteId: noteId,
            currentPath: localPath,
            downloadUrl: downloadUrl,
          );
          _queue.remove(data);
          await _saveQueue();
        } catch (ex) {
          CustomDialog.showError("Error", "Failed to upload image.");
        }
      }
    }
  }

  Future<void> _replaceImageWithUrl({
    required String noteId,
    required String currentPath,
    required String downloadUrl,
  }) async {
    // Retrieve note to update its image.
    noteController.getById(noteId);
    if (noteController.content.value?.id != noteId) {
      return;
    }
    final note = noteController.content.value!;

    // Extract data from delta.
    final deltaJson = jsonDecode(note.content!);
    final delta = Delta.fromJson(deltaJson);

    bool hasChanged = false;
    for (final operation in delta.operations) {
      if (operation.isInsert &&
          operation.data is Map &&
          (operation.data as Map)["image"] == currentPath) {
        (operation.data as Map)["image"] = downloadUrl;
        hasChanged = true;
      }
    }

    // Update image data of the note in the Firebase Firestore.
    if (hasChanged) {
      final newContent = jsonEncode(delta.toJson());
      await noteController.edit([note.copyWith(content: newContent)]);
    }
  }

  void _listenToConnectionChanges() {
    connectivityService.connectionStream.listen((isOnline) async {
      if (isOnline) {
        await _attemptUpload();
      }
    });
  }

  // Load queue from local file.
  Future<void> _loadQueue() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_queueFileName');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List list = jsonDecode(jsonString);
        _queue.assignAll(list.map((item) => Map<String, String>.from(item)));
      }
    } catch (ex) {
      CustomDialog.showError("Error", "Failed to load queue.");
    }
  }

  // Save queue to local file.
  Future<void> _saveQueue() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_queueFileName');
      await file.writeAsString(jsonEncode(_queue));
    } catch (ex) {
      CustomDialog.showError("Error", "Failed to temporary save changes.");
    }
  }
}
