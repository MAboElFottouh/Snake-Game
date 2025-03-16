import 'package:flutter/services.dart';

class AudioService {
  static Future<void> playEatSound() async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
  }

  static Future<void> playGameOverSound() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
  }
}