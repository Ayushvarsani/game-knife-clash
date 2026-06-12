import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackController {
  bool _enabled = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('settings_haptics') ?? true;
  }

  void light() { if (_enabled) HapticFeedback.lightImpact(); }
  void medium() { if (_enabled) HapticFeedback.mediumImpact(); }
  void heavy() { if (_enabled) HapticFeedback.heavyImpact(); }
}
