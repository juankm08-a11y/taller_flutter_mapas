import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'screens/add_place_screen.dart';
import 'services/supabase_service.dart';
import 'services/gemini_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  final gemini = GeminiService();

  runApp(MyApp(gemini: gemini));
}

class MyApp extends StatelessWidget {
  final GeminiService gemini;
  const MyApp({super.key, required this.gemini});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Maps + IA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => MapScreen(gemini: gemini),
        '/add': (ctx) => AddPlaceScreen(gemini: gemini),
      },
    );
  }
}
