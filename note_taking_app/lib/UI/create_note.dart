import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
import 'package:note_taking_app/UI/SharedComponents/confirmation_message.dart';
import 'package:note_taking_app/UI/SharedComponents/info_button.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  String lastGeneratedContent = '';
  bool hasGeneratedLabels = false;

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

    // Clear suggested labels.
    labelController.suggestedLabels.value = [];

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
    lastGeneratedContent = contentController.document.toPlainText().trim();
    hasGeneratedLabels = false;

    _listenToContentChanges();

    // Load labels.
    selectedLabel = widget.initialLabel ?? widget.note?.label;
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   _loadLabels();
    //   if (selectedLabel != null &&
    //       !labelController.noteLabels.any(
    //         (label) => label.id == selectedLabel!.id,
    //       )) {
    //     labelController.noteLabels.insert(0, selectedLabel!);
    //   }
    // });

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

  Future<void> _generateLabels() async {
    if (!toggleEnabled) return;

    final currentContent = contentController.document.toPlainText().trim();
    final isSuggestedEmpty = labelController.suggestedLabels.isEmpty;
    final hasContentChanged = currentContent != lastGeneratedContent;

    final shouldGenerate = isSuggestedEmpty || hasContentChanged;

    if (shouldGenerate) {
      await labelController.generateLabel(ComponentType.note, currentContent);

      if (labelController.errorMessage.value.isEmpty) {
        lastGeneratedContent = currentContent;
        hasGeneratedLabels = true;
      }
    }
  }

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

  Future<void> _createNote({
    required String deltaJson,
    required String searchableContent,
    required Function(Note? note) successAction,
  }) async {
    final isShared = widget.mode == Mode.createShared;
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
      CustomDialog.showError("Error", noteController.errorMessage.value);
      return;
    }

    CustomDialog.showSuccess("Success", "Successfully create note.");
    successAction(note);
  }

  Future<void> _editNote({
    required String deltaJson,
    required String searchableContent,
    required Function(Note? note) successAction,
  }) async {
    final isShared = widget.mode == Mode.createShared;
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
      searchableContent: contentController.document.toPlainText().trim(),
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
      noteController.editShared(note!, widget.groupId!, widget.groupType!);
    }

    if (noteController.errorMessage.value.isNotEmpty) {
      CustomDialog.showError("Error", noteController.errorMessage.value);
      return;
    }
    uploadImageService.attemptUpload();
    CustomDialog.showSuccess("Success", "Successfully edit note.");
    successAction(note);
  }

  Future<void> _saveChanges({
    required Function(Note? note) successAction,
  }) async {
    final delta = contentController.document.toDelta();
    final deltaJson = jsonEncode(delta.toJson());
    final searchableContent = contentController.document.toPlainText().trim();
    if (hasChanged && (widget.mode != Mode.view)) {
      if (widget.mode == Mode.create || widget.mode == Mode.createShared) {
        await _createNote(
          deltaJson: deltaJson,
          searchableContent: searchableContent,
          successAction: successAction,
        );
      } else {
        await _editNote(
          deltaJson: deltaJson,
          searchableContent: searchableContent,
          successAction: successAction,
        );
      }
    }
    if (widget.mode == Mode.edit && !hasChanged) {
      final viewedNote = note!.copyWith(isViewed: true);
      noteController.edit([viewedNote]);
      if (noteController.errorMessage.value.isNotEmpty) {
        CustomDialog.showError("Error", noteController.errorMessage.value);
      }
    }
  }

  void _showUnsavedChangesDialog({
    bool canSave = true,
    bool canDiscard = false,
    bool canCancel = true,
  }) {
    buildConfirmationMessage(
      context: context,
      title: 'Unsaved Changes. Would you like to save changes?',
      buttonDetails: [
        if (canSave)
          ButtonDetails(
            text: "Save",
            buttonColor:
                Theme.of(
                  context,
                ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
                Colors.black,
            onTapOption: () async => await _saveChanges(
              successAction: (note) async {
                print("SAVE SUCCESS: note = ${note?.runtimeType}, id = ${note?.id}");

                print("Popping NoteDetailScreen with result");
                Get.back(result: note);
              },
            ),
          ),
        if (canDiscard)
          ButtonDetails(
            text: "Discard",
            buttonColor: Colors.red,
            onTapOption: () async => Get.back(),
          ),
        if (canCancel) ButtonDetails(text: "Cancel", buttonColor: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (hasChanged) {
          _showUnsavedChangesDialog(canDiscard: true);
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          titleWidget: Row(
            children: [
              Text(title),
              CustomInfoButton(
                infoDetails: [
                  Info(
                    text:
                        "To save changes, select the back button to apply changes.",
                  ),
                ],
              ),
            ],
          ),
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
                        hasChanged = true;
                      });
                    }
                  },
                )
              : [],
          replaceDefaultActions: false,
          onMenuTap: () {
            if (hasChanged) {
              _showUnsavedChangesDialog();
            } else {
              _scaffoldKey.currentState?.openEndDrawer();
            }
          },
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
                        child: CustomLabelEditor(
                          type: ComponentType.note,
                          labelController: labelController,
                          initialLabel:
                              widget.initialLabel ?? widget.note?.label,
                          isReadOnly:
                              widget.isLabelReadOnly ||
                              widget.mode == Mode.view,
                          onTagsChanged: (value) {
                            if (!widget.isLabelReadOnly &&
                                widget.mode != Mode.view) {
                              setState(() {
                                selectedLabel = value;
                                updateHasChanged();
                              });
                            }
                          },
                          withGenerateLabelSwitch: widget.mode != Mode.view
                              ? true
                              : false,
                          contentController: contentController,
                          initialSwitchState: toggleEnabled,
                          onToggled: (value) => setState(() {
                            toggleEnabled = value;
                          }),
                          onEditorOpened: _generateLabels,
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
                        placeholder: "Content",
                        customStyles: DefaultStyles(
                          placeHolder: DefaultTextBlockStyle(
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.grey,
                            ),
                            HorizontalSpacing(0, 0),
                            VerticalSpacing(0, 0),
                            VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
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
                        buttonOptions: QuillSimpleToolbarButtonOptions(
                          base: QuillToolbarBaseButtonOptions(
                            iconTheme: QuillIconTheme(
                              iconButtonSelectedData: IconButtonData(
                                color: Colors.black,
                              ),
                              iconButtonUnselectedData: IconButtonData(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
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

                                return pickedImage.path;
                              },
                              onImageInsertCallback:
                                  (imagePath, controller) async {
                                    final index =
                                        controller.selection.baseOffset;
                                    controller.document.insert(
                                      index,
                                      BlockEmbed.image(imagePath),
                                    );
                                    controller.updateSelection(
                                      TextSelection.collapsed(
                                        offset: index + 1,
                                      ),
                                      ChangeSource.local,
                                    );

                                    final noteId = note?.id ?? controllerTag;
                                    final contentJson = jsonEncode(
                                      controller.document.toDelta().toJson(),
                                    );
                                    await uploadImageService.queueUpload(
                                      localPath: imagePath,
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
                                                      await getApplicationDocumentsDirectory();
                                                  final filePath =
                                                      '${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
                                                  await directory.create(
                                                    recursive: true,
                                                  );
                                                  final file = File(filePath);
                                                  await file.writeAsBytes(data);

                                                  // Add after file.writeAsBytes
                                                  print(
                                                    "File exists: ${await file.exists()}",
                                                  );
                                                  print(
                                                    "File path: ${file.path}",
                                                  );

                                                  print(
                                                    "Saved drawing to: $filePath",
                                                  );

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
                                  await uploadImageService.queueUpload(
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
                        return Text(
                          '${value - 1}/$maxLength',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: Colors.grey.shade700),
                        );
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.black),
                ),
                Icon(Icons.first_page, color: Colors.black),
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
