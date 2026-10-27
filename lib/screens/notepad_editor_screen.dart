import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models.dart';

class NotepadEditorScreen extends StatefulWidget {
  final NoteModel? note;
  final int? index;
  const NotepadEditorScreen({super.key, this.note, this.index});

  @override
  State<NotepadEditorScreen> createState() => _NotepadEditorScreenState();
}

class _NotepadEditorScreenState extends State<NotepadEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool isPreview = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }

  void _save() {
    final box = Hive.box<NoteModel>('notes');
    final newNote = NoteModel(
      title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
      content: _contentController.text,
      updatedAt: DateTime.now(),
      isThread: widget.note?.isThread ?? false,
    );

    if (widget.index != null) {
      box.putAt(widget.index!, newNote);
    } else {
      box.add(newNote);
    }
    Navigator.pop(context);
  }

  // HELPER: Insert formatted text at the current cursor position
  void _insertMarkdown(String markdown) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    // If there's no selection, append to the end
    final int start = selection.start == -1 ? text.length : selection.start;
    final int end = selection.end == -1 ? text.length : selection.end;

    final newText = text.replaceRange(start, end, markdown);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + markdown.length),
    );
    setState(() {});
  }

  // NEW: Dialog for adding a "Definition" card (Matches Page 21)
  void _showAddDefinitionDialog() {
    final varController = TextEditingController();
    final defController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.blue, width: 2),
          ),
          title: const Text('NEW DEFINITION',
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: varController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Variable (e.g., X)',
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: defController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Definition',
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                if (varController.text.isNotEmpty &&
                    defController.text.isNotEmpty) {
                  // Insert beautifully formatted Markdown
                  _insertMarkdown(
                      '\n\n**${varController.text}**\n*Definition:* ${defController.text}\n\n---\n');
                  Navigator.pop(context);
                }
              },
              child: const Text('ADD', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final File localImage =
          await File(image.path).copy('${appDir.path}/$fileName');

      // Insert Markdown image syntax
      _insertMarkdown('\n![Image](${localImage.path})\n');
      setState(() => isPreview = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isThread = widget.note?.isThread ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.blue, size: 30),
                      onPressed: () => Navigator.pop(context)),
                  Expanded(
                    child: Center(
                      child: Text(
                          _titleController.text.isEmpty
                              ? 'Topic'
                              : _titleController.text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  IconButton(
                      icon: Icon(isPreview ? Icons.edit : Icons.remove_red_eye,
                          color: Colors.blue),
                      onPressed: () => setState(() => isPreview = !isPreview)),
                  IconButton(
                      icon: const Icon(Icons.save, color: Colors.blue),
                      onPressed: _save),
                ],
              ),
            ),
            const Divider(color: Colors.white),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isThread ? 'Threads' : 'Notepad',
                  style: TextStyle(
                    color: isThread ? Colors.blue : Colors.grey[500],
                    fontWeight: isThread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
            // Editor Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isPreview
                    ? Markdown(
                        data: _contentController.text,
                        imageBuilder: (uri, title, alt) {
                          final file = File(uri.path);
                          if (file.existsSync()) return Image.file(file);
                          return const Text('Image not found',
                              style: TextStyle(color: Colors.red));
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.white),
                          strong:
                              const TextStyle(color: Colors.blue, fontSize: 18),
                          horizontalRuleDecoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: Colors.white24, width: 2)),
                          ),
                        ))
                    : TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Start Typing...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() {}),
                      ),
              ),
            ),

            // NEW: Bottom Toolbar for Threads (Matches Page 21)
            if (isThread && !isPreview)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: Colors.white24, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _showAddDefinitionDialog,
                        icon: const Icon(Icons.add, color: Colors.blue),
                        label: const Text('ADD THREAD',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image, color: Colors.blue),
                      label: const Text('IMAGE',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
