import 'package:flutter/material.dart';
import 'calculator_screen.dart';
import 'clock_screen.dart'; // <-- NEW IMPORT
import 'whiteboard_screen.dart';
import 'notepad_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'CALCULATOR',
        'icon': Icons.calculate_outlined,
        'screen': const CalculatorScreen()
      },
      {
        'title': 'CLOCK',
        'icon': Icons.timer,
        'screen': const ClockScreen()
      }, // <-- COMBINED TIMER & STOPWATCH
      {
        'title': 'WHITEBOARD',
        'icon': Icons.draw_outlined,
        'screen': const WhiteboardScreen()
      },
      {
        'title': 'REVIEWER',
        'icon': Icons.menu_book,
        'screen': const NotepadListScreen()
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icons
              const Row(
                children: [
                  Icon(Icons.home, color: Colors.white, size: 30),
                  SizedBox(width: 15),
                  Icon(Icons.star, color: Colors.blue, size: 30),
                ],
              ),
              const SizedBox(height: 30),
              // Welcome Text
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                        text: 'Welcome to ',
                        style: TextStyle(color: Colors.blue)),
                    TextSpan(
                        text: 'EsOne!', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Divider(color: Colors.blue, thickness: 1),
              const SizedBox(height: 20),
              // Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => tools[index]['screen'] as Widget),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(tools[index]['icon'] as IconData,
                                color: Colors.white, size: 50),
                            const SizedBox(height: 15),
                            Text(
                              tools[index]['title'] as String,
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
