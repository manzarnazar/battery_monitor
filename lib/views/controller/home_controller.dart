import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/colors.dart';
import '../helper.dart';

class HomeController extends GetxController {
  RxBool temperature = false.obs;
  RxBool charging = true.obs;
  RxBool fullBatterySwitch = false.obs;
  RxBool backgroundRunning = false.obs;
  RxDouble setVolumeValue = 0.0.obs;
  RxDouble currentValue = 0.0.obs;
  RxDouble currentLowValue = 0.0.obs;
  RxBool lowBatterySwitch = false.obs;
  RxBool vibrationSwitch = false.obs;
  RxBool ringOnSilentSwitch = false.obs;
  RxBool flashlightSwitch = false.obs;
  RxString smallVibrate = "small".obs;
  RxString largeVibrate = "large".obs;
  RxString mediumVibrate = "medium".obs;
  RxString selctedVibrate = "small".obs;
  RxString flashType = "short".obs;
  RxString flashTypel = "long".obs;
  RxBool soundSwitch = false.obs;
  late SharedPreferences prefs;
  bool popup = false;
  RxBool isProcessing = false.obs;

  Future<void> backgroundAppToggle(bool value) async {
    if (isProcessing.value) return;
    prefs.setBool("backgroundRunning", value);
    backgroundRunning.value = value;

    //isProcessing.value = true;
    final service = FlutterBackgroundService();

    if (value) {
      bool serviceStarted = await service.startService();
      if (serviceStarted == true) {}
    } else {
      FlutterBackgroundService().invoke('stopService');
    }
    isBackgroundServiceRunningNotifier.value = value;
    isProcessing.value = false;
  }

  Widget backgroundRunnin() {
    return Align(
      alignment: Alignment.centerRight,
      child: ValueListenableBuilder<bool>(
        valueListenable: isBackgroundServiceRunningNotifier,
        builder: (context, bool isRunning, _) {
          // backgroundRunning.value = isRunning;
          return Switch(
            onChanged: backgroundAppToggle,
            value: backgroundRunning.value,
            activeColor: themeColor,
            activeTrackColor: textColor,
            inactiveThumbColor: linesColor,
            inactiveTrackColor: textColor,
          );
        },
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    getBackgroundRunningToggle();
  }

  Future<void> getBackgroundRunningToggle() async {
    prefs = await SharedPreferences.getInstance();
    // Get the value of "backgroundRunning" from SharedPreferences
    backgroundRunning.value = prefs.getBool("backgroundRunning") ?? false;
    // Update the observable variable
  }
}
