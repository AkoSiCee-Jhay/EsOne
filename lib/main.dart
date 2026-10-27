import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(WhiteboardStrokeAdapter());

  await Hive.openBox<NoteModel>('notes');
  await Hive.openBox<WhiteboardStroke>('whiteboard');

  // ADDED THIS LINE: Required to save the Fill Tool image
  await Hive.openBox('whiteboard_bg');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'EsOne',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          primaryColor: Colors.blue,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
