import 'package:flutter/material.dart';
import 'package:snake_game/screens/game_screen.dart';  

class DifficultyScreen extends StatelessWidget {
  final String gameMode;

  const DifficultyScreen({super.key, required this.gameMode});

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
                color: Color(0xFF8B0000),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            Container(
              width: 280, // Fixed width for all buttons
              child: Column(
                children: [
                  _buildDifficultyButton(context, 'Easy'),
                  const SizedBox(height: 20),
                  _buildDifficultyButton(context, 'Medium'),
                  const SizedBox(height: 20),
                  _buildDifficultyButton(context, 'Hard'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF8B0000),
                size: 40,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String difficulty) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
    );
  }
}