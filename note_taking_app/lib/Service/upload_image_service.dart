import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Service/conectivity_service.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class UploadImageService extends GetxService {
  final _queue = <Map<String, dynamic>>[].obs;
  final _queueFileName = 'pending_image_uploads.json';
  var hasError = false.obs;
  final NoteController noteController = Get.find<NoteController>();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadQueue();
    _listenToConnectionChanges();
    await attemptUpload();
  }

  Future<void> queueUpload({
    required String localPath,
    required String noteId,
    required String currentContentJson,
  }) async {
    final entry = {
      "localPath": localPath,
      "noteId": noteId,
      "contentJson": currentContentJson,
      "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
    };
    _queue.add(entry);
    await _saveQueue();
  }

  Future<void> attemptUpload() async {
    for (int i = 0; i < 3; i++) {
      if (_queue.isNotEmpty && connectivityService.isOnline.value) {
        // Check if connected to Internet.
        if (!connectivityService.isOnline.value) return;

        final dataToUpload = List<Map<String, dynamic>>.from(_queue);

        // Retrieve data from queue.
        for (final data in dataToUpload) {
          final localPath = data["localPath"];
          final noteId = data["noteId"];
          final contentJson = data["contentJson"];

          if (localPath != null && noteId != null && contentJson != null) {
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
                initialContentJson: contentJson,
              );
              _queue.remove(data);
              await _saveQueue();
            } catch (ex) {
              hasError.value = true;
              CustomDialog.showError("Error", ex.toString());
            }
          }
        }
        if (_queue.isNotEmpty) {
          await Future.delayed(Duration(seconds: 5));
        }
      }
    }
  }

  Future<void> _replaceImageWithUrl({
    required String noteId,
    required String currentPath,
    required String downloadUrl,
    required String initialContentJson,
  }) async {
    // Retrieve note to update its image.
    final authController = Get.find<AuthenticationController>();
    final documentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(authController.user!.uid)
        .collection('notes')
        .doc(noteId)
        .get();
    if (!documentSnapshot.exists) return;

    final note = Note.fromFirestore(documentSnapshot);

    // Extract data from delta.
    final currentDeltaJson = jsonDecode(note.content!);
    final currentDelta = Delta.fromJson(currentDeltaJson);

    await deleteImages(note: note, currentContentJson: note.content!);

    // Replace image path with download url.
    bool hasChanged = false;
    final newOperations = <Operation>[];
    for (final operation in currentDelta.operations) {
      if (operation.isInsert && operation.data is Map) {
        if ((operation.data as Map)["image"] == currentPath) {
          (operation.data as Map)["image"] = downloadUrl;
          newOperations.add(Operation.insert(operation.data));
          hasChanged = true;
        } else {
          newOperations.add(operation);
        }
      } else {
        newOperations.add(operation);
      }
    }

    // Update image data of the note in the Firebase Firestore.
    if (hasChanged) {
      final newDelta = Delta.fromOperations(newOperations);
      final newContent = jsonEncode(newDelta.toJson());
      await noteController.edit([note.copyWith(content: newContent)]);
    }
  }

  List<String> _extractImagesFromDelta(Delta delta) {
    final images = <String>[];
    for (var operation in delta.toList()) {
      final data = operation.data;
      if (data is Map && data.containsKey('image')) images.add(data['image']);
    }
    return images;
  }

  Future<void> deleteImages({
    required Note note,
    String? oldContentJson,
    required String currentContentJson,
  }) async {
    final oldDeltaJson = jsonDecode(oldContentJson ?? note.content ?? "");
    final oldDelta = Delta.fromJson(oldDeltaJson);
    final oldImages = _extractImagesFromDelta(oldDelta);

    final currentDeltaJson = jsonDecode(currentContentJson);
    final currentDelta = Delta.fromJson(currentDeltaJson);
    final currentImages = _extractImagesFromDelta(currentDelta);

    // Delete images that user removed from the content.
    final imagesToDelete = oldImages.where(
      (image) => !currentImages.contains(image),
    );
    for (final imageUrl in imagesToDelete) {
      try {
        final storageReference = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageReference.delete();
      } catch (_) {}
    }
  }

  void _listenToConnectionChanges() {
    connectivityService.connectionStream.listen((isOnline) async {
      if (isOnline) {
        await attemptUpload();
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
        _queue.assignAll(list.map((item) => Map<String, dynamic>.from(item)));
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
