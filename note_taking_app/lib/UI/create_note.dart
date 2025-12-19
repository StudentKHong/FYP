import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:note_taking_app/Controller/attachment_controller.dart';
import 'package:note_taking_app/Controller/label_controller.dart';
import 'package:note_taking_app/Controller/note_controller.dart';
import 'package:note_taking_app/Controller/setting_controller.dart';
import 'package:note_taking_app/Model/Models/entity_model.dart';
import 'package:note_taking_app/Model/Models/label_model.dart';
import 'package:note_taking_app/Model/Models/note_model.dart';
import 'package:note_taking_app/Service/conectivity_service.dart';
import 'package:note_taking_app/Service/upload_image_service.dart';
import 'package:note_taking_app/UI/SharedComponents/app_bar.dart';
import 'package:note_taking_app/UI/SharedComponents/label_editor.dart';
import 'package:note_taking_app/UI/SharedComponents/show_error_dialog.dart';
import 'package:note_taking_app/UI/SharedComponents/text_box.dart';
import 'package:note_taking_app/UI/attachment.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:note_taking_app/Model/Models/enumeration.dart';

enum Mode { view, create, createShared, edit, editShared }

class NoteDetailScreen extends StatefulWidget {
  final Mode mode;
  final String? title;
  final String? description;
  final String? groupId;
  final String? groupType;
  final Widget? additionalDetails;
  final Note? note;
  final Label? initialLabel;
  final bool isLabelReadOnly;
  final bool hideAttachmentButton;

  const NoteDetailScreen({
    super.key,
    required this.mode,
    this.title,
    this.description,
    this.groupId,
    this.groupType,
    this.additionalDetails,
    this.note,
    this.initialLabel,
    this.isLabelReadOnly = false,
    this.hideAttachmentButton = false,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final String title;
  final int maxLength = 2000;
  late ValueNotifier<int> numberOfCharacters;

  // Store and track the changes in the contents.
  Note? original;
  Note? note;
  Delta? previousDocumentDelta;
  Timer? deleteImagesDebounceTimer;
  Timer? generateLabelDebounceTimer;
  bool toggleEnabled = false;
  bool hasChanged = false;
  Label? selectedLabel;

  final TextEditingController titleController = TextEditingController();
  late QuillController contentController;
  final SignatureController drawingController = SignatureController();
  late FocusNode quillFocusNode;
  final ScrollController quillScrollController = ScrollController();

  late final NoteController noteController;
  late final String controllerTag;
  late AttachmentController attachmentController;
  final UploadImageService uploadImageService = Get.find<UploadImageService>();
  final LabelController labelController = Get.find<LabelController>();
  final SettingController settingController = Get.find<SettingController>();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();

    // Initilize note controller.
    if (widget.mode == Mode.createShared || widget.mode == Mode.editShared) {
      if (!Get.isRegistered<NoteController>(
        tag: 'group_${widget.groupId}_note',
      )) {
        noteController = Get.put(
          NoteController(),
          tag: 'group_${widget.groupId}_note',
        );
      } else {
        noteController = Get.find<NoteController>(
          tag: 'group_${widget.groupId}_note',
        );
      }
    } else {
      noteController = Get.find<NoteController>();
    }

    // Initialize attachment controller.
    controllerTag = widget.note?.id ?? "temp_id}";
    attachmentController = Get.put(
      AttachmentController(componentId: controllerTag),
      tag: controllerTag,
    );

    // Set notes.
    original = widget.note?.copyWith();
    note = original?.copyWith();

    // Set text field and quill controllers.
    titleController.text = original?.title ?? '';
    if (original?.content != null) {
      previousDocumentDelta = Delta.fromJson(jsonDecode(original!.content!));
    }
    quillFocusNode = FocusNode(canRequestFocus: widget.mode != Mode.view);

    // Load data.
    _loadAttachmentCount();
    contentController = QuillController(
      document: Document(),
      selection: TextSelection.collapsed(offset: 0),
      readOnly: widget.mode == Mode.view,
    );
    if (original != null && original!.content != null) {
      final deltaJson = jsonDecode(original!.content!);
      final delta = Delta.fromJson(deltaJson);

      contentController.document = Document.fromDelta(delta);
      contentController.updateSelection(
        TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );

      // _syncLocalImage(Delta.fromJson(deltaJson)).then((delta) {
      //   contentController.document = Document.fromDelta(delta);
      //   contentController.updateSelection(
      //     TextSelection.collapsed(offset: 0),
      //     ChangeSource.local,
      //   );
      //   _listenToContentChanges();
      // });
    }
    // else {
    //   _listenToContentChanges();
    // }
    numberOfCharacters = ValueNotifier(
      contentController.document.toPlainText().length,
    );

    _listenToContentChanges();

    // Load labels.
    selectedLabel = widget.initialLabel ?? widget.note?.label;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadLabels();
      if (selectedLabel != null &&
          !labelController.noteLabels.any(
            (label) => label.id == selectedLabel!.id,
          )) {
        labelController.noteLabels.insert(0, selectedLabel!);
      }
    });

    // Load the initial state of the auto generate label toggle button.
    _loadCurrentSettings();

    // Assign page title based on mode.
    if (widget.title != null) {
      title = widget.title!;
      return;
    }
    switch (widget.mode) {
      case Mode.view:
        title = "Note Detail";
        break;
      case Mode.create || Mode.createShared:
        title = "Create Note";
        break;
      case Mode.edit || Mode.editShared:
        title = "Edit Note";
        break;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    numberOfCharacters.dispose();
    drawingController.dispose();
    quillFocusNode.dispose();
    quillScrollController.dispose();
    ImageEmbedBuilder.cache.clear();
    generateLabelDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAttachmentCount() async {
    if (controllerTag == UniqueKey().toString()) {
      attachmentController.totalCount.value =
          attachmentController.temporaryList.length;
    } else {
      attachmentController.getAllCount();
    }
  }

  void updateHasChanged() {
    String originalTitle = original?.title ?? "";
    String originalContent = "";
    if (original != null && original!.content != null) {
      final deltaJson = jsonDecode(original!.content!);
      originalContent = Document.fromDelta(
        Delta.fromJson(deltaJson),
      ).toPlainText().trim();
    }
    String? originalLabel = original?.label?.name;

    final currentTitle = titleController.text;
    final currentContent = contentController.document.toPlainText().trim();
    final currentLabel = selectedLabel?.name;
    hasChanged =
        currentTitle != originalTitle ||
        currentContent != originalContent ||
        currentLabel != originalLabel;
  }

  // Add listener to controllers.
  void _listenToContentChanges() {
    titleController.addListener(updateHasChanged);

    contentController.addListener(() async {
      // Update number of characters.
      final content = contentController.document.toPlainText();
      numberOfCharacters.value = content.length;
      if (content.length > maxLength) {
        contentController.undo();
        numberOfCharacters.value = maxLength;

        CustomDialog.showError(
          "Maximum Length Exceeded",
          "The content has exceeded the maximum length of $maxLength characters.",
        );
      }

      updateHasChanged();

      deleteImagesDebounceTimer?.cancel();
      deleteImagesDebounceTimer = Timer(Duration(milliseconds: 1000), () async {
        final currentDelta = contentController.document.toDelta();

        if (note != null &&
            previousDocumentDelta != null &&
            previousDocumentDelta! != currentDelta) {
          await uploadImageService.deleteImages(
            note: note!,
            oldContentJson: jsonEncode(previousDocumentDelta),
            currentContentJson: jsonEncode(currentDelta),
          );
          previousDocumentDelta = currentDelta;
        }
      });

      // Update suggested labels if auto-generate is enabled.
      // if (toggleEnabled) {
      //   generateLabelDebounceTimer?.cancel();
      //   generateLabelDebounceTimer = Timer(
      //     const Duration(milliseconds: 500),
      //     () async {
      //       await labelController.generateLabel(
      //         ComponentType.note,
      //         contentController.document.toPlainText(),
      //       );
      //     },
      //   );
      // }
    });
  }

  void _loadCurrentSettings() async {
    await settingController.get();
    final settings = settingController.currentSettings.value;

    if (settings != null) {
      setState(() {
        toggleEnabled = settings.autoLabelingEnabled;
      });
    }
  }

  void _loadLabels() async {
    if (note != null && note!.label != null && note!.label!.id != null) {
      // Load existing label.
      labelController.getNoteLabels();

      // Load suggested labels.
      if (note!.searchableContent != null) {
        await labelController.generateLabel(
          ComponentType.note,
          note!.searchableContent!,
        );
      }
    }
  }

  // Future<Delta> _syncLocalImage(Delta delta) async {
  //   final newDelta = Delta();

  //   for (var operation in delta.toList()) {
  //     final data = operation.data;
  //     if (data is Map && data['image'] != null) {
  //       final image = data['image'] as String;
  //       if (image.toString().startsWith('data:image/')) {
  //         final base64Data = image.split(',').last;
  //         final bytes = base64Decode(base64Data);

  //         // Upload image to Firebase Storage.
  //         final storageReference = fs.FirebaseStorage.instance
  //             .ref()
  //             .child("note_images")
  //             .child("${DateTime.now().millisecondsSinceEpoch}.jpg");
  //         await storageReference.putData(bytes);

  //         // Get download url.
  //         final downloadUrl = await storageReference.getDownloadURL();
  //         newDelta.insert({"image": downloadUrl});
  //       } else {
  //         newDelta.insert({"image": image});
  //       }
  //     } else {
  //       newDelta.push(operation);
  //     }
  //   }
  //   return newDelta;
  // }

  Future<void> _commitAttachments(String componentId) async {
    if (note?.id != null) {
      if (attachmentController.temporaryList.isNotEmpty) {
        await attachmentController.commitTemporaryAttachments(componentId);
      }

      if (attachmentController.errorMessage.value.isNotEmpty) {
        CustomDialog.showError(
          "Error",
          attachmentController.errorMessage.value,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final delta = contentController.document.toDelta();
        // final syncedDelta = await _syncLocalImage(delta);
        final deltaJson = jsonEncode(delta.toJson());
        final searchableContent = contentController.document
            .toPlainText()
            .trim();
        if (hasChanged && (widget.mode != Mode.view)) {
          final isShared = widget.mode == Mode.createShared;
          if (widget.mode == Mode.create || widget.mode == Mode.createShared) {
            note = Note(
              id: UniqueKey().toString(),
              title: titleController.text.trim(),
              content: deltaJson,
              searchableContent: searchableContent,
              createdAt: DateTime.now(),
              viewedAt: isShared ? null : DateTime.now(),
              updatedAt: DateTime.now(),
              isPinned: false,
              isArchived: isShared ? null : false,
              label: isShared ? null : selectedLabel,
              labelName: isShared ? selectedLabel?.name : null,
            );

            if (note != null) {
              if (widget.mode == Mode.create) {
                final createdNote = await noteController.create(note!);
                if (createdNote != null && createdNote.id != null) {
                  _commitAttachments(createdNote.id!);
                  note = createdNote;
                }
              } else if (widget.mode == Mode.createShared &&
                  widget.groupId != null &&
                  widget.groupType != null) {
                noteController.shareMultiple(
                  [note!],
                  widget.groupId!,
                  widget.groupType!,
                );
              }
            }
            if (noteController.errorMessage.value.isNotEmpty) {
              CustomDialog.showError(
                "Error",
                noteController.errorMessage.value,
              );
              return;
            }

            CustomDialog.showSuccess("Success", "Successfully create note.");
            Get.back(result: note);
            return;
          } else {
            if (note != null) {
              await uploadImageService.deleteImages(
                note: note!,
                currentContentJson: jsonEncode(
                  contentController.document.toDelta().toJson(),
                ),
              );
            }
            note = note!.copyWith(
              title: titleController.text.trim(),
              content: deltaJson,
              searchableContent: contentController.document
                  .toPlainText()
                  .trim(),
              label: isShared ? null : selectedLabel,
              labelName: isShared ? selectedLabel?.name : null,
              isViewed: isShared ? false : true,
              isUpdated: true,
            );

            if (widget.mode == Mode.edit) {
              noteController.edit([note!]);
            } else if (widget.mode == Mode.editShared &&
                widget.groupId != null &&
                widget.groupType != null) {
              noteController.editShared(
                note!,
                widget.groupId!,
                widget.groupType!,
              );
            }

            if (noteController.errorMessage.value.isNotEmpty) {
              CustomDialog.showError(
                "Error",
                noteController.errorMessage.value,
              );
              return;
            }
            await uploadImageService.attemptUpload();

            if (!uploadImageService.hasError.value) {
              CustomDialog.showSuccess("Success", "Successfully edit note.");
              Get.back(result: note);
            }
            return;
          }
        }
        if (widget.mode == Mode.edit && !hasChanged) {
          final viewedNote = note!.copyWith(isViewed: true);
          noteController.edit([viewedNote]);
          if (noteController.errorMessage.value.isNotEmpty) {
            CustomDialog.showError("Error", noteController.errorMessage.value);
          }
        }
        Get.back();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          titleText: title,
          subtitle: widget.description,
          actions:
              (note != null &&
                  (widget.mode == Mode.edit || widget.mode == Mode.editShared))
              ? AdditionalOptions.buildDefaultOptions(
                  context: context,
                  controller: noteController,
                  contentController: contentController,
                  titleController: titleController,
                  notes: [note!],
                  isForShared: widget.mode == Mode.editShared,
                  onUpdate: (updatedNotes) {
                    final list = updatedNotes
                        .map((item) => item as Note)
                        .toList();
                    if (list.length == 1) {
                      setState(() {
                        note = list.first;
                      });
                    }
                  },
                )
              : [],
          replaceDefaultActions: false,
        ),
        endDrawer: const HamburgerMenu(),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(10),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (widget.additionalDetails != null) ...[
                    widget.additionalDetails!,
                    const SizedBox(height: 10),
                  ],
                  CustomTextField(
                    withBorder: false,
                    maxLength: 50,
                    controller: titleController,
                    hintText: "Title",
                    isReadOnly: widget.mode == Mode.view,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: 70,
                          child: CustomLabelEditor(
                            type: ComponentType.note,
                            labelController: labelController,
                            initialLabel:
                                widget.initialLabel ?? widget.note?.label,
                            isReadOnly:
                                widget.isLabelReadOnly ||
                                widget.mode == Mode.view,
                            onTagsChanged: (value) {
                              if (!widget.isLabelReadOnly) {
                                setState(() {
                                  selectedLabel = value;
                                  updateHasChanged();
                                });
                              }
                            },
                            withGenerateLabelSwitch: widget.mode != Mode.view
                                ? true
                                : false,
                            contentToSuggestLabel: contentController.document
                                .toPlainText(),
                            initialSwitchState: toggleEnabled,
                          ),
                        ),
                      ),
                      if (widget.mode != Mode.view &&
                          !widget.hideAttachmentButton)
                        Obx(() {
                          final isOnline = connectivityService.isOnline.value;
                          if (!isOnline) return SizedBox.shrink();
                          return AttachmentExpandableButton(
                            entity: note,
                            count: attachmentController.totalCount.value,
                            attachmentController: attachmentController,
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: BoxBorder.all(width: 1),
                    ),
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: QuillEditor(
                      focusNode: quillFocusNode,
                      scrollController: quillScrollController,
                      controller: contentController,
                      config: QuillEditorConfig(
                        showCursor: widget.mode != Mode.view,
                        autoFocus: false,
                        embedBuilders: [
                          ImageEmbedBuilder(),
                          ...FlutterQuillEmbeds.editorBuilders(),
                        ],
                      ),
                    ),
                  ),
                  if (widget.mode != Mode.view)
                    QuillSimpleToolbar(
                      controller: contentController,
                      config: QuillSimpleToolbarConfig(
                        showUndo: false,
                        showRedo: false,
                        showStrikeThrough: false,
                        showColorButton: false,
                        showBackgroundColorButton: false,
                        showFontFamily: false,
                        showFontSize: false,
                        showSmallButton: false,
                        showListCheck: false,
                        showListNumbers: false,
                        showCodeBlock: false,
                        showQuote: false,
                        showIndent: false,
                        showLink: false,
                        showDividers: false,
                        showSearchButton: false,
                        showInlineCode: false,
                        showHeaderStyle: false,
                        showAlignmentButtons: false,
                        showDirection: false,
                        showClearFormat: false,
                        showSubscript: false,
                        showSuperscript: false,
                        embedButtons: FlutterQuillEmbeds.toolbarButtons(
                          videoButtonOptions: null,
                          imageButtonOptions: QuillToolbarImageButtonOptions(
                            tooltip: "Image",
                            imageButtonConfig: QuillToolbarImageConfig(
                              onRequestPickImage: (context) async {
                                // Allow user to pick image.
                                final imagePicker = ImagePicker();
                                final pickedImage = await imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (pickedImage == null) return null;

                                // final file = File(pickedImage.path);

                                // if (connectivityService.isOnline.value) {
                                //   try {
                                //     // Save to Firebase Cloud Storage.
                                //     final storageReference = FirebaseStorage
                                //         .instance
                                //         .ref()
                                //         .child("note_images")
                                //         .child(
                                //           "${DateTime.now().millisecondsSinceEpoch}.jpg",
                                //         );
                                //     await storageReference.putFile(file);

                                //     // Get download url.
                                //     final downloadUrl = await storageReference
                                //         .getDownloadURL();
                                //     return downloadUrl;
                                //   } catch (ex) {
                                //     CustomDialog.showError("Error", "Failed to upload image.");
                                //     return pickedImage.path;
                                //   }
                                // }

                                return pickedImage.path;
                              },
                              onImageInsertCallback:
                                  (imageUrl, controller) async {
                                    controller.replaceText(
                                      controller.selection.baseOffset,
                                      0,
                                      BlockEmbed.image(imageUrl),
                                      TextSelection.collapsed(
                                        offset:
                                            controller.selection.baseOffset + 1,
                                      ),
                                    );

                                    final noteId = note?.id ?? controllerTag;
                                    final contentJson = jsonEncode(
                                      controller.document.toDelta().toJson(),
                                    );
                                    uploadImageService.queueUpload(
                                      localPath: imageUrl,
                                      noteId: noteId,
                                      currentContentJson: contentJson,
                                    );

                                    hasChanged = true;
                                  },
                            ),
                          ),
                        ),
                        customButtons: [
                          if (widget.mode != Mode.view) ...[
                            QuillToolbarCustomButtonOptions(
                              icon: Icon(Icons.draw_outlined),
                              tooltip: "Draw",
                              onPressed: () async {
                                final result = await showModalBottomSheet<String>(
                                  // isScrollControlled: true,
                                  context: context,
                                  builder: (_) => Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.all(10),
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Signature(
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.6,
                                              controller: drawingController,
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                final data =
                                                    await drawingController
                                                        .toPngBytes();
                                                if (data != null) {
                                                  final directory =
                                                      await getApplicationCacheDirectory();
                                                  final filePath =
                                                      '${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
                                                  final file = File(filePath);
                                                  await file.writeAsBytes(data);
                                                  // final image =
                                                  //     await decodeImageFromList(
                                                  //       data,
                                                  //     );
                                                  // final byteData = await image
                                                  //     .toByteData(
                                                  //       format: ui
                                                  //           .ImageByteFormat
                                                  //           .png,
                                                  //     );
                                                  // final pngBytes = byteData!
                                                  //     .buffer
                                                  //     .asUint8List();

                                                  // final base64 =
                                                  //     base64Encode(pngBytes)
                                                  //         .replaceAll('\n', '')
                                                  //         .replaceAll('\r', '')
                                                  //         .replaceAll(' ', '')
                                                  //         .trim();
                                                  // final imageUrl =
                                                  //     'data:image/png;base64,$base64';

                                                  Get.back(result: filePath);
                                                }
                                              },
                                              child: Text('Save'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Get.back(result: null);
                                              },
                                              child: Text('Cancel'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  // final data = base64Decode(result);
                                  // final storageReference = FirebaseStorage.instance
                                  //     .ref()
                                  //     .child('drawings')
                                  //     .child(
                                  //       '${DateTime.now().millisecondsSinceEpoch}.png',
                                  //     );
                                  // await storageReference.putData(data);
                                  // final downloadUrl = await storageReference
                                  //     .getDownloadURL();
                                  contentController.replaceText(
                                    contentController.selection.baseOffset,
                                    0,
                                    BlockEmbed.image(result),
                                    TextSelection.collapsed(
                                      offset:
                                          contentController
                                              .selection
                                              .baseOffset +
                                          1,
                                    ),
                                  );
                                  final noteId = note?.id ?? controllerTag;
                                  final contentJson = jsonEncode(
                                    contentController.document
                                        .toDelta()
                                        .toJson(),
                                  );
                                  uploadImageService.queueUpload(
                                    localPath: result,
                                    noteId: noteId,
                                    currentContentJson: contentJson,
                                  );
                                }

                                hasChanged = true;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (widget.mode != Mode.view)
                    ValueListenableBuilder(
                      valueListenable: numberOfCharacters,
                      builder: (_, value, _) {
                        return Text('${value - 1}/$maxLength');
                      },
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttachmentExpandableButton extends StatelessWidget {
  final FilterableEntity? entity;
  final AttachmentController attachmentController;
  final int count;
  const AttachmentExpandableButton({
    super.key,
    this.entity,
    required this.attachmentController,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Positioned(
          child: ElevatedButton(
            onPressed: () {
              AttachmentScreen.displayAttachments(
                context: context,
                entity: entity,
                attachmentController: attachmentController,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Icon(Icons.first_page),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ImageEmbedBuilder extends EmbedBuilder {
  static final Map<String, Uint8List> cache = {};

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final data = node.value.data as String;

    Widget imageWidget;
    // Detect image path (online or local path).
    if (data.startsWith('data:image')) {
      final cachedBytes = cache[data];

      final Uint8List bytes;
      if (cachedBytes != null) {
        bytes = cachedBytes;
      } else {
        final base64String = data.split(',')[1];
        final base64 = base64String.replaceAll(RegExp(r'\s+'), '');
        bytes = base64Decode(base64);
        cache[data] = bytes;
      }

      imageWidget = Image.memory(bytes, fit: BoxFit.contain);
    } else if (data.startsWith('/')) {
      imageWidget = Image.file(File(data), fit: BoxFit.contain);
    } else if (data.startsWith('http')) {
      imageWidget = Image.network(data.toString(), fit: BoxFit.contain);
    } else {
      imageWidget = Icon(Icons.broken_image);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.hardEdge,
        color: Colors.white,
        child: imageWidget,
      ),
    );
  }

  @override
  String get key => BlockEmbed.imageType;
}
