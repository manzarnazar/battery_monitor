import 'package:battery_alarm/Model/ringtones_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryAlarmprovider extends ChangeNotifier {
  bool isChecked = false;
  double lowerVal = 0;
  int? selectedIndex;
  String? selectedRingtonePath;
  late SharedPreferences prefs;
  bool ringOnSilentSwitch = false;
  bool vibrationSwitch = false;

  void toggleCheckbox(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  selectedLowerVal(double val) async {
    lowerVal = val;
    prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('currentLowValue', lowerVal);
    notifyListeners();
  }

  selectedRingtone(String path) async {
    selectedRingtonePath = path;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    await prefs?.setString('selectedRingtone', selectedRingtonePath!);
  }

  ringOnSilent(bool path) async {
    ringOnSilentSwitch = path;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    await prefs?.setBool('ringOnSilentSwitch', ringOnSilentSwitch!);
    print("Value get: ${prefs.getBool('ringOnSilentSwitch')}");
  }

  vibrateSwitich(bool path) async {
    vibrationSwitch = path;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    await prefs?.setBool('vibrationSwitch', vibrationSwitch!);
    print("vibrate Value get: ${prefs.getBool('vibrationSwitch')}");
  }
}


// class valProvider extends ChangeNotifier {
//   double lowerVal = 0;
//   late SharedPreferences prefs;

//   selectedLowerVal(double val) async {
//     lowerVal = val;
//     notifyListeners();
//     prefs = await SharedPreferences.getInstance();
//     await prefs.setDouble('currentLowValue', lowerVal);
//   }
// }
