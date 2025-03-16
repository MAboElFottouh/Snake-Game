import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static String _getHighScoreKey(String gameMode) => 'highScore_$gameMode';

  static Future<int> getHighScore(String gameMode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_getHighScoreKey(gameMode)) ?? 0;
  }

  static Future<void> updateHighScore(String gameMode, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = await getHighScore(gameMode);
    if (score > currentHigh) {
      await prefs.setInt(_getHighScoreKey(gameMode), score);
    }
  }
}