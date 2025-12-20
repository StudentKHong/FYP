import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:note_taking_app/Controller/auth_controller.dart';
import 'package:note_taking_app/Controller/base_controller.dart';
import 'package:note_taking_app/Model/Models/attachment_model.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';
import 'package:note_taking_app/Model/Repository/attachment_repository.dart';

class AttachmentController extends Controller<Attachment> {
  late final AttachmentRepository _attachmentRepository;

  var temporaryList = <AttachmentComponent>[].obs;
  var attachmentComponents = <AttachmentComponent>[].obs;

  StreamSubscription<List<AttachmentComponent>>? _attachmentSubscription;

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
    errorMessage.value = "";
    _attachmentSubscription?.cancel();
    _attachmentSubscription = _attachmentRepository.getList().listen((data) {
      attachmentComponents.assignAll(data);
    }, onError: (ex) => errorMessage.value = ex.toString());
  }

  void createTemporary(List<AttachmentComponent> attachmentComponents) {
    temporaryList.assignAll(attachmentComponents);
    totalCount.value += 1;
  }

  Future<void> commitTemporaryAttachments(String componentId) async {
    try {
      errorMessage.value = "";
      final attachments = temporaryList
          .where((component) => component.id != null)
          .map((component) {
            final attachmentType =
                component.runtimeType.toString().toLowerCase() == "note"
                ? ComponentType.note
                : ComponentType.task;
            return Attachment(
              id: UniqueKey().toString(),
              attachmentType: attachmentType,
              attachmentId: component.id!,
            );
          })
          .toList();

      final tempRepository = AttachmentRepository(componentId: componentId);
      await tempRepository.createMultiple(attachments);
      getList();

      temporaryList.clear();
    } catch (ex) {
      errorMessage.value = ex.toString();
    }
  }

  Future<void> createMultiple(List<Attachment> attachments) async {
    try {
      errorMessage.value = "";
      await _attachmentRepository.createMultiple(attachments);
      getList();
    } catch (ex) {
      errorMessage.value = "Failed to create attachments.";
    }
  }

  @override
  ComponentFilter<Attachment>? createFilter() {
    return null;
  }
}
