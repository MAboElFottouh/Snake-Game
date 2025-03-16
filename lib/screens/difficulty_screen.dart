import 'package:flutter/material.dart';
import '../main.dart';
import '../services/score_service.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatefulWidget {
  final String gameMode;
  const DifficultyScreen({super.key, required this.gameMode});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    highScore = await ScoreService.getHighScore(widget.gameMode);
    setState(() {});
  }

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
                  gameMode: widget.gameMode,
                ),
              ),
            ).then((_) => _loadHighScore()); // Reload high score when returning
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
              '${widget.gameMode} Mode',
              style: const TextStyle(
                color: MyApp.primaryColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'High Score: $highScore',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 24,
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