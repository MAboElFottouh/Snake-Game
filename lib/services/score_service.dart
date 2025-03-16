import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const String _highScoreKey = 'highScore';

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  static Future<void> updateHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = await getHighScore();
    if (score > currentHigh) {
      await prefs.setInt(_highScoreKey, score);
    }
  }
}