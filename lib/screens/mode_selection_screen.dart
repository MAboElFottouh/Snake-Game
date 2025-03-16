import 'package:flutter/material.dart';
import 'difficulty_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  Widget _buildModeButton(BuildContext context, String mode, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
              'Select Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildModeButton(context, 'Classic', Colors.green[700]!),
            _buildModeButton(context, 'Boxed', Colors.blue[700]!),
            _buildModeButton(
              context, 
              'Challenge', 
              Colors.purple[700]!, // Purple color for Challenge mode
            ),
          ],
        ),
      ),
    );
  }
}