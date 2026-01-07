// ==================================================
// Program Name   : attachment_controller.dart
// Purpose        : Manages attachment state and upload/commit operations
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 26 December 2025
// ==================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Model/Models/attachment_model.dart';
import 'package:note_taking_app/Model/Repository/attachment_repository.dart';

class AttachmentController extends Controller<Attachment> {
  late final AttachmentRepository _attachmentRepository;

  var temporaryList = <ResolvedAttachment>[].obs;
  var resolvedAttachments = <ResolvedAttachment>[].obs;

  StreamSubscription<List<ResolvedAttachment>>? _attachmentSubscription;

  AttachmentController({required String componentId})
    : super(
        repository: Get.put(AttachmentRepository(componentId: componentId)),
      ) {
    _attachmentRepository = super.repository as AttachmentRepository;
  }

  @override
  void onClose() {
    _attachmentSubscription?.cancel();
    super.onClose();
  }

  @override
  void getAll() {
    return;
  }

  void getList() {
    isLoading.value = true;
    errorMessage.value = "";
    _attachmentSubscription?.cancel();
    _attachmentSubscription = _attachmentRepository.getList().listen(
      (data) {
        resolvedAttachments.assignAll(data);
        isLoading.value = false;
      },
      onError: (ex) {
        errorMessage.value = ex.toString();
        isLoading.value = false;
      },
    );
  }

  void createTemporary(List<ResolvedAttachment> resolvedAttachments) {
    temporaryList.assignAll(resolvedAttachments);
    totalCount.value += 1;
  }

  Future<void> commitTemporaryAttachments(String componentId) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final attachments = temporaryList
          .where((component) => component.attachmentComponent.id != null)
          .map((component) {
            // final attachmentType =
            //     component.runtimeType.toString().toLowerCase() == "note"
            //     ? ComponentType.note
            //     : ComponentType.task;
            return Attachment(
              id: UniqueKey().toString(),
              attachmentType: component.attachment.attachmentType,
              attachmentId: component.attachmentComponent.id!,
            );
          })
          .toList();

      final tempRepository = AttachmentRepository(componentId: componentId);
      await tempRepository.createMultiple(attachments);
      getList();

      temporaryList.clear();
    } catch (ex) {
      errorMessage.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createMultiple(List<Attachment> attachments) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      await _attachmentRepository.createMultiple(attachments);
      getList();
    } catch (ex) {
      errorMessage.value = "Failed to create attachments.";
    } finally {
      isLoading.value = false;
    }
  }

  @override
  ComponentFilter<Attachment>? createFilter() {
    return null;
  }
}
