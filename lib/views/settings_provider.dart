import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool soundSwitch = false;
  bool vibrationSwitch = false;
  bool flashlightSwitch = false;

  void updateSoundSwitch(bool value) {
    soundSwitch = value;
    notifyListeners();
  }

  void updateVibrationSwitch(bool value) {
    vibrationSwitch = value;
    notifyListeners();
  }

  void updateFlashlightSwitch(bool value) {
    flashlightSwitch = value;
    notifyListeners();
  }
}
