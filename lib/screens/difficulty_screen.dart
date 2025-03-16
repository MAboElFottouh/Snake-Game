import 'package:flutter/material.dart';
import '../main.dart';
import 'package:snake_game/screens/game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  final String gameMode;

  const DifficultyScreen({super.key, required this.gameMode});

  Widget _buildDifficultyButton(BuildContext context, String difficulty) {
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
                builder: (context) => GameScreen(
                  difficulty: difficulty,
                  gameMode: gameMode,
                ),
              ),
            );
          },
          child: Text(
            difficulty,
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
            Text(
              '$gameMode Mode',
              style: const TextStyle(
                color: MyApp.primaryColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildDifficultyButton(context, 'Easy'),
            _buildDifficultyButton(context, 'Medium'),
            _buildDifficultyButton(context, 'Hard'),
          ],
        ),
      ),
    );
  }
}