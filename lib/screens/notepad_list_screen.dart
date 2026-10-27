import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import 'notepad_editor_screen.dart';

class NotepadListScreen extends StatelessWidget {
  const NotepadListScreen({super.key});

  void _showAddTopicDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    int selectedType = 1; // 1 = Notepad, 2 = Threads

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CREATE NEW TOPIC',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Enter Topic Title',
                    hintStyle: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: selectedType,
                          activeColor: Colors.blue,
                          onChanged: (val) =>
                              setStateDialog(() => selectedType = val!),
                        ),
                        const Text('Notepad',
                            style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<int>(
                          value: 2,
                          groupValue: selectedType,
                          activeColor: Colors.blue,
                          onChanged: (val) =>
                              setStateDialog(() => selectedType = val!),
                        ),
                        const Text('Threads',
                            style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        final box = Hive.box<NoteModel>('notes');
                        final newNote = NoteModel(
                          title: titleController.text,
                          content: '',
                          updatedAt: DateTime.now(),
                          // SAVE THE TYPE HERE
                          isThread: selectedType == 2,
                        );
                        box.add(newNote);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('ADD',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(width: 10),
                  const Text('TOPICS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D8BCE),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    onPressed: () => _showAddTopicDialog(context),
                    child: const Text('+ NEW',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            // List
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<NoteModel>('notes').listenable(),
                builder: (context, Box<NoteModel> box, _) {
                  if (box.isEmpty) {
                    return const Center(
                        child: Text("No topics yet.",
                            style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final note = box.getAt(index)!;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[800]!)),
                        child: ListTile(
                          title: Text(note.title,
                              style: const TextStyle(color: Colors.white)),
                          // DYNAMICALLY SHOW "Notepad" OR "Threads"
                          subtitle: Text(note.isThread ? "Threads" : "Notepad",
                              style: TextStyle(
                                  color: note.isThread
                                      ? Colors.blue
                                      : Colors.grey)),
                          trailing: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => box.deleteAt(index)),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => NotepadEditorScreen(
                                      note: note, index: index))),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
