// ==================================================
// Program Name   : upload_image_service.dart
// Purpose        : Handles image upload queueing and replacement in notes
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 24 December 2025
// ==================================================

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
  final _deletionQueue = <Map<String, dynamic>>[].obs;
  final _deletionQueueFileName = 'pending_image_deletions.json';
  var hasError = false.obs;
  final NoteController noteController = Get.find<NoteController>();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadQueue();
    await _loadDeletionQueue();
    _listenToConnectionChanges();
    await attemptUpload();
    await processDeletionQueue();
  }

  Future<void> queueImageDeletion(String imageUrl) async {
    if (!imageUrl.startsWith('http') && !imageUrl.startsWith('gs://')) {
      try {
        await File(imageUrl).delete();
      } catch (ex) {
        throw Exception("Failed to delete local file: $ex");
      }
      return;
    }

    final entry = {
      "url": imageUrl,
      "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
    };
    _deletionQueue.add(entry);
    await _saveDeletionQueue();
  }

  Future<void> _saveDeletionQueue() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_deletionQueueFileName');
      await file.writeAsString(jsonEncode(_deletionQueue));
    } catch (ex) {
      throw Exception("Failed to save deletion queue: $ex");
    }
  }

  // Load queue from local file.
  Future<void> _loadDeletionQueue() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_deletionQueueFileName');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List list = jsonDecode(jsonString);
        _deletionQueue.assignAll(
          list.map((item) => Map<String, dynamic>.from(item)),
        );
      }
    } catch (ex) {
      CustomDialog.showError("Error", ex.toString());
      CustomDialog.showError("Error", "Failed to load deletion queue.");
    }
  }

  Future<void> processDeletionQueue() async {
    if (!connectivityService.isOnline.value) return;

    for (int i = _deletionQueue.length - 1; i >= 0; i--) {
      final entry = _deletionQueue[i];
      final url = entry["url"] as String?;
      if (url == null) continue;

      try {
        final documentReference = FirebaseStorage.instance.refFromURL(url);
        await documentReference.delete();
        _deletionQueue.removeAt(i);
      } catch (ex) {
        throw Exception("Failed to process deletion: $ex");
      }
    }
    await _saveDeletionQueue();
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
      if (!connectivityService.isOnline.value) return;
      if (_queue.isNotEmpty && connectivityService.isOnline.value) {
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
                  .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
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
    final user = authController.user.value;
    if (user == null) return;

    final documentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .get();
    if (!documentSnapshot.exists) return;

    final note = Note.fromFirestore(documentSnapshot);

    // Extract data from delta.
    if (note.content == null || note.content!.isEmpty) return;
    
    final currentDeltaJson = jsonDecode(note.content!);
    final currentDelta = Delta.fromJson(currentDeltaJson);

    await deleteImages(
      note: note,
      oldContentJson: initialContentJson,
      currentContentJson: jsonEncode(currentDelta.toJson()),
    );

    // Replace image path with download url.
    bool hasChanged = false;
    final newOperations = <Operation>[];
    for (final operation in currentDelta.operations) {
      if (operation.isInsert && operation.data is Map) {
        final map = operation.data as Map;
        
        if (map.containsKey('custom')) {
          try {
            final customData = jsonDecode(map['custom']);
          if (customData is Map && customData.containsKey('image')) {
            final imageJson = customData['image'];
            final imageData = jsonDecode(imageJson);
            
            if (imageData is Map && imageData['source'] == currentPath) {
              // Update the source to the download URL
              imageData['source'] = downloadUrl;
              customData['image'] = jsonEncode(imageData);
              map['custom'] = jsonEncode(customData);
              newOperations.add(Operation.insert(map));
              hasChanged = true;
            } else {
              newOperations.add(operation);
            }
          } else {
            newOperations.add(operation);
          }
        } catch (_) {
          newOperations.add(operation);
        }
      }
      // Handle standard image embed
      else if (map.containsKey('image')) {
        final imageData = map['image'];
        if (imageData == currentPath) {
          map['image'] = downloadUrl;
          newOperations.add(Operation.insert(map));
          hasChanged = true;
        } else {
          newOperations.add(operation);
        }
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
      if (data is Map && data.containsKey('custom')) {
        try {
          final customJson = jsonDecode(data['custom']);
          if (customJson is Map && customJson.containsKey('image')) {
            final imageJson = customJson['image'];
            final imageData = jsonDecode(imageJson);
            if (imageData is Map && imageData.containsKey('source')) {
              images.add(imageData['source']);
            }
          }
        } catch (_) {}
      }

      if (data is Map && data.containsKey('image')) {
        final imageData = data['image'];
        if (imageData is String) {
          images.add(imageData);
        } else if (imageData is Map && imageData.containsKey('source')) {
          images.add(imageData['source']);
        }
      }
    }
    return images;
  }

  Future<void> deleteImages({
    required Note note,
    String? oldContentJson,
    required String currentContentJson,
  }) async {
    final source = oldContentJson ?? note.content;
    if (source == null || source.isEmpty) return;

    final oldDeltaJson = jsonDecode(source);
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
      if (imageUrl.startsWith('http') || imageUrl.startsWith('gs://')) {
        await queueImageDeletion(imageUrl);
      } else {
        try {
          await File(imageUrl).delete();
        } catch (_) {}
      }
    }
  }

  void _listenToConnectionChanges() {
    connectivityService.connectionStream.listen((isOnline) async {
      if (isOnline) {
        await attemptUpload();
        await processDeletionQueue();
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
