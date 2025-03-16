import 'package:flutter/material.dart';
import '../main.dart';
import 'difficulty_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  Widget _buildModeButton(BuildContext context, String mode, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: SizedBox(
        width: double.infinity,
        height: 80,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MyApp.buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: MyApp.primaryColor,
                width: 2,
              ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mode,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Mode',
              style: TextStyle(
                color: MyApp.primaryColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildModeButton(
              context, 
              'Classic',
              'Original snake game with wraparound edges'
            ),
            _buildModeButton(
              context, 
              'Boxed',
              'No wraparound - hit the walls and game over'
            ),
            _buildModeButton(
              context, 
              'Challenge',
              'Dodge moving obstacles while collecting food'
            ),
            _buildModeButton(
              context, 
              'Walls',
              'Navigate through moving wall barriers'
            ),
          ],
        ),
      ),
    );
  }
}