import 'package:flutter/material.dart';
import 'package:snake_game/screens/difficulty_screen.dart';
import 'screens/mode_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryColor = Color(0xFF8B0000); // Dark red
  static const Color buttonColor = Color(0xFF1A1A1A); // Dark gray for buttons

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
      theme: ThemeData(
        colorScheme: ColorScheme.dark().copyWith(
          primary: primaryColor,
          secondary: buttonColor,
        ),
        useMaterial3: true,
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  Widget _buildModeButton(BuildContext context, String mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MyApp.buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(
                color: MyApp.primaryColor,
                width: 2,
              ),
            ),
            elevation: 5,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DifficultyScreen(gameMode: mode),
              ),
            );
          },
          child: Text(
            mode,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Snake Game',
              style: TextStyle(
                color: MyApp.primaryColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildModeButton(context, 'Classic'),
            _buildModeButton(context, 'Boxed'),
            _buildModeButton(context, 'Challenge'),
          ],
        ),
      ),
    );
  }
}
