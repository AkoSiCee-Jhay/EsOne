import 'package:flutter/material.dart';
import 'calculator_screen.dart';
import 'notepad_list_screen.dart';

class SplitScreenView extends StatelessWidget {
  const SplitScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Split View Mode',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: const Column(
        children: [
          Expanded(child: CalculatorScreen()),
          Divider(color: Colors.blue, thickness: 2),
          Expanded(child: NotepadListScreen()),
        ],
      ),
    );
  }
}
