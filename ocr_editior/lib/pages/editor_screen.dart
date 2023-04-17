import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ocr_editior/models/notes.dart';
import 'package:ocr_editior/services/notes_services.dart';
import 'package:ocr_editior/widgets/scnackbar.dart';
import 'package:ocr_editior/widgets/share_dialog.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../services/pdf_handlers.dart';

enum _SelectionType {
  none,
  word,
}

class EditorScreen extends StatefulWidget {
  final Notes note;
  final int index;
  EditorScreen({
    required this.note,
    required this.index,
  });
  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late QuillController _controller;
  late FlutterTts _flutterTts;

  final FocusNode _focusNode = FocusNode();
  Timer? _selectAllTimer;
  _SelectionType _selectionType = _SelectionType.none;

  // late TtsState _ttsState;
  @override
  void dispose() {
    _selectAllTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    setState(() {
      _controller = QuillController(
        document: widget.note.data,
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
  }

  /// Save the changed data to Firebase
  Future<void> _saveChangesToFirebase() async {
    NotesServices().saveChangesToFirebase(
      widget.note.id,
      _controller.document.toDelta().toList(),
    );
  }

  // Text to Speech to read the notes that you have made
  Future<void> _readDocument() async {
    try {
      final data = _controller.document.toPlainText();
      await _flutterTts.speak(data);
    } catch (_) {
      throw Exception();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff6A3EA1),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Notes ${widget.index + 1}',
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight,
            ),
            ListTile(
              leading: Icon(
                Icons.save_rounded,
                color: Color(0xff6A3EA1),
              ),
              title: const Text('Save Changes'),
              onTap: () async {
                try {
                  await _saveChangesToFirebase();
                  showSnackBar(
                    context,
                    'Notes Saved!',
                    isSuccess: true,
                  );
                } catch (_) {
                  showSnackBar(
                    context,
                    'Error while saving notes!',
                  );
                }
              },
            ),
            if (!kIsWeb)
              ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xff6A3EA1),
                  ),
                  title: const Text('Export PDF'),
                  onTap: () async {
                    try {
                      final path = await PdfHandler.getPDFromHtml(
                        _controller.document.toDelta(),
                        widget.note.id,
                      );

                      showSnackBar(
                        context,
                        'PDF saved at $path',
                        isSuccess: true,
                      );
                    } catch (_) {
                      showSnackBar(
                        context,
                        'Error while saving notes!',
                      );
                    }
                  }),
            ListTile(
              leading: Icon(
                Icons.speaker_rounded,
                color: Color(0xff6A3EA1),
              ),
              title: const Text('Read Document'),
              onTap: () async {
                _readDocument();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share_rounded,
                color: Color(0xff6A3EA1),
              ),
              title: Text('Share Notes'),
              onTap: () {
                showDialog(
                    context: context,
                    builder: (_) {
                      return ShareNotesDialog(
                        docId: widget.note.id,
                      );
                    });
              },
            )
          ],
        ),
      ),
      body: _buildWelcomeEditor(context),
    );
  }

  bool _onTripleClickSelection() {
    final controller = _controller;

    _selectAllTimer?.cancel();
    _selectAllTimer = null;

    // If you want to select all text after paragraph, uncomment this line
    // if (_selectionType == _SelectionType.line) {
    //   final selection = TextSelection(
    //     baseOffset: 0,
    //     extentOffset: controller.document.length,
    //   );

    //   controller.updateSelection(selection, ChangeSource.REMOTE);

    //   _selectionType = _SelectionType.none;

    //   return true;
    // }

    if (controller.selection.isCollapsed) {
      _selectionType = _SelectionType.none;
    }

    if (_selectionType == _SelectionType.none) {
      _selectionType = _SelectionType.word;
      _startTripleClickTimer();
      return false;
    }

    if (_selectionType == _SelectionType.word) {
      final child = controller.document.queryChild(
        controller.selection.baseOffset,
      );
      final offset = child.node?.documentOffset ?? 0;
      final length = child.node?.length ?? 0;

      final selection = TextSelection(
        baseOffset: offset,
        extentOffset: offset + length,
      );

      controller.updateSelection(selection, ChangeSource.REMOTE);

      // _selectionType = _SelectionType.line;

      _selectionType = _SelectionType.none;

      _startTripleClickTimer();

      return true;
    }

    return false;
  }

  void _startTripleClickTimer() {
    _selectAllTimer = Timer(const Duration(milliseconds: 900), () {
      _selectionType = _SelectionType.none;
    });
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    Widget quillEditor = MouseRegion(
      cursor: SystemMouseCursors.text,
      child: QuillEditor(
        controller: _controller,
        scrollController: ScrollController(),
        scrollable: true,
        focusNode: _focusNode,
        autoFocus: false,
        readOnly: false,
        placeholder: 'Add content',
        enableSelectionToolbar: isMobile(),
        expands: false,
        padding: EdgeInsets.zero,
        onImagePaste: _onImagePaste,
        onTapUp: (details, p1) {
          return _onTripleClickSelection();
        },
        customStyles: DefaultStyles(
          h1: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 32,
                color: Colors.black,
                height: 1.15,
                fontWeight: FontWeight.w300,
              ),
              const VerticalSpacing(16, 0),
              const VerticalSpacing(0, 0),
              null),
          sizeSmall: const TextStyle(fontSize: 9),
        ),
        embedBuilders: [
          ...FlutterQuillEmbeds.builders(),
          NotesEmbedBuilder(addEditNote: _addEditNote)
        ],
      ),
    );
    if (kIsWeb) {
      quillEditor = MouseRegion(
        cursor: SystemMouseCursors.text,
        child: QuillEditor(
          controller: _controller,
          scrollController: ScrollController(),
          scrollable: true,
          focusNode: _focusNode,
          autoFocus: false,
          readOnly: false,
          placeholder: 'Add content',
          expands: false,
          padding: EdgeInsets.zero,
          onTapUp: (details, p1) {
            return _onTripleClickSelection();
          },
          customStyles: DefaultStyles(
            h1: DefaultTextBlockStyle(
                const TextStyle(
                  fontSize: 32,
                  color: Colors.black,
                  height: 1.15,
                  fontWeight: FontWeight.w300,
                ),
                const VerticalSpacing(16, 0),
                const VerticalSpacing(0, 0),
                null),
            sizeSmall: const TextStyle(fontSize: 9),
          ),
        ),
      );
    }
    var toolbar = QuillToolbar.basic(
      controller: _controller,
      showAlignmentButtons: true,
      showRedo: false,
      showFontFamily: false,
      showFontSize: false,
      showSearchButton: false,
      showClearFormat: false,
      showUndo: false,
      showLink: false,
      showHeaderStyle: false,
      afterButtonPressed: _focusNode.requestFocus,
    );
    if (kIsWeb) {
      toolbar = QuillToolbar.basic(
        controller: _controller,
        showAlignmentButtons: true,
        showRedo: false,
        showFontFamily: false,
        showFontSize: false,
        showSearchButton: false,
        showClearFormat: false,
        showUndo: false,
        showLink: false,
        showHeaderStyle: false,
        afterButtonPressed: _focusNode.requestFocus,
      );
    }
    if (_isDesktop()) {
      toolbar = QuillToolbar.basic(
        controller: _controller,
        showAlignmentButtons: true,
        showRedo: false,
        showFontFamily: false,
        showFontSize: false,
        showSearchButton: false,
        showClearFormat: false,
        showUndo: false,
        showLink: false,
        showHeaderStyle: false,
        afterButtonPressed: _focusNode.requestFocus,
      );
    }

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          kIsWeb
              ? Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    color: Colors.grey.shade50,
                    child: toolbar,
                  ),
                )
              : Container(
                  color: Colors.grey.shade50,
                  child: toolbar,
                ),
          Expanded(
            flex: 15,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: quillEditor,
            ),
          ),
        ],
      ),
    );
  }

  bool _isDesktop() => !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

  Future<String> _onImagePaste(Uint8List imageBytes) async {
    // Saves the image to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = await File(
            '${appDocDir.path}/${basename('${DateTime.now().millisecondsSinceEpoch}.png')}')
        .writeAsBytes(imageBytes, flush: true);
    return file.path.toString();
  }

  Future<void> _addEditNote(BuildContext context, {Document? document}) async {
    final isEditing = document != null;
    final quillEditorController = QuillController(
      document: document ?? Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, top: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${isEditing ? 'Edit' : 'Add'} note'),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            )
          ],
        ),
        content: QuillEditor.basic(
          controller: quillEditorController,
          readOnly: false,
        ),
      ),
    );

    if (quillEditorController.document.isEmpty()) return;

    final block = BlockEmbed.custom(
      NotesBlockEmbed.fromDocument(quillEditorController.document),
    );
    final controller = _controller;
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    if (isEditing) {
      final offset =
          getEmbedNode(controller, controller.selection.start).offset;
      controller.replaceText(
          offset, 1, block, TextSelection.collapsed(offset: offset));
    } else {
      controller.replaceText(index, length, block, null);
    }
  }
}

class NotesEmbedBuilder extends EmbedBuilder {
  NotesEmbedBuilder({required this.addEditNote});

  Future<void> Function(BuildContext context, {Document? document}) addEditNote;

  @override
  String get key => 'notes';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
  ) {
    final notes = NotesBlockEmbed(node.value.data).document;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          notes.toPlainText().replaceAll('\n', ' '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const Icon(Icons.notes),
        onTap: () => addEditNote(context, document: notes),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}

class NotesBlockEmbed extends CustomBlockEmbed {
  const NotesBlockEmbed(String value) : super(noteType, value);

  static const String noteType = 'notes';

  static NotesBlockEmbed fromDocument(Document document) =>
      NotesBlockEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document => Document.fromJson(jsonDecode(data));
}
