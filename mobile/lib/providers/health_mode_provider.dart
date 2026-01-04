import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Enum representing the health approach mode
enum HealthMode {
  scientific, // Evidence-based, clinical approach
  ayurvedic, // Traditional, holistic approach
}

/// Provider to manage the user's preferred health approach mode
class HealthModeProvider extends ChangeNotifier {
  static const String _modeKey = 'health_mode';
  final Box _settingsBox = Hive.box('settings');

  HealthMode _mode = HealthMode.scientific;

  HealthModeProvider() {
    _loadMode();
  }

  HealthMode get mode => _mode;

  bool get isAyurvedic => _mode == HealthMode.ayurvedic;

  bool get isScientific => _mode == HealthMode.scientific;

  /// Get the mode as a string for API calls
  String get modeString =>
      _mode == HealthMode.ayurvedic ? 'ayurvedic' : 'scientific';

  /// Get display name for current mode
  String getDisplayName(BuildContext context) {
    return isAyurvedic ? 'Ayurvedic 🌿' : 'Scientific 🔬';
  }

  /// Get description for current mode
  String getDescription() {
    return isAyurvedic
        ? 'Traditional holistic healing with doshas, herbs, and natural remedies'
        : 'Evidence-based medicine with clinical approach and modern treatments';
  }

  void _loadMode() {
    final savedMode = _settingsBox.get(_modeKey, defaultValue: 'scientific');
    _mode =
        savedMode == 'ayurvedic' ? HealthMode.ayurvedic : HealthMode.scientific;
  }

  Future<void> setMode(HealthMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    await _settingsBox.put(
        _modeKey, mode == HealthMode.ayurvedic ? 'ayurvedic' : 'scientific');
    notifyListeners();
  }

  Future<void> setAyurvedic() async {
    await setMode(HealthMode.ayurvedic);
  }

  Future<void> setScientific() async {
    await setMode(HealthMode.scientific);
  }

  Future<void> toggleMode() async {
    if (isScientific) {
      await setAyurvedic();
    } else {
      await setScientific();
    }
  }
}
