// ignore_for_file: non_constant_identifier_names, unrelated_type_equality_checks

import 'dart:async';
import 'dart:ffi';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:battery_alarm/views/Ringtones/batteryalarm_provider.dart';
import 'package:battery_alarm/views/controller/home_controller.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lecle_volume_flutter/lecle_volume_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:workmanager/workmanager.dart';

class BatteryAlarm extends StatefulWidget {
  const BatteryAlarm({super.key});

  @override
  State<BatteryAlarm> createState() => _BatteryAlarmState();
}

class _BatteryAlarmState extends State<BatteryAlarm>
    with WidgetsBindingObserver {
  double _currentValue = 100;
  double _currentLowValue = 0;
  late bool fullBatterySwitch = false;
  bool soundSwitch = false;
  bool vibrationSwitch = false;
  bool flashlightSwitch = false;
  String selctedVibrate = "small";
  String selectedRingtonePath = "";
  String flashtype = "short";
  String flashtypel = "long";
  bool ringOnSilentSwitch = false;
  final assetsAudioPlayer = AssetsAudioPlayer();
  final Battery _battery = Battery();
  late SharedPreferences prefs;
  late bool isFlashlightOn;
  late Timer _blinkTimer;

  late double maxNotificationVolume;
  double? currentNotificationVolume;
  bool notificationSwitch = true;
  late AudioManager audioManager = AudioManager.streamNotification;

  @override
  void initState() {
    //alarmHelper.monitorBatteryLevel();
    _getCurrentSoundMode();
    super.initState();
    VolumeController().listener((volume) {});
    initNotificationVolume();
    //monitorBatteryInBackground();
    loadSettings();
    monitorBatteryLevel();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initNotificationVolume() async {
    await Volume.initAudioStream(audioManager);
    updateNotificationVolumes();
  }

  void updateNotificationVolumes() async {
    maxNotificationVolume = (await Volume.getMaxVol)?.toDouble() ?? 0.0;
    currentNotificationVolume = (await Volume.getVol)?.toDouble() ?? 0.0;
    setState(() {});
  }

  void setNotificationVolume(double? volume) async {
    if (volume != null) {
      await Volume.setVol(androidVol: volume.toInt(), iOSVol: volume);
      updateNotificationVolumes();
    }
  }

  void ToggleSwitchSound(bool value) async {
    setState(() {
      controller.soundSwitch.value = value;
    });
    await prefs.setBool('soundSwitch', value);

    if (value) {
      setNotificationVolume(
          5.0); // Set any desired volume when the switch is on
    } else {
      setNotificationVolume(0.0); // Mute the volume when the switch is off
    }
  }

  void initializeTorchLight() async {
    await TorchLight.enableTorch();
  }

  void toggleFlashlight(bool light) {
    if (light) {
      TorchLight.enableTorch();
    } else {
      TorchLight.disableTorch();
    }
    setState(() {
      isFlashlightOn = light;
    });
  }

  Future<void> disposeTorchLight() async {
    await TorchLight.disableTorch();
  }

  var controller = Get.put(HomeController());
  bool _isNotificationShown = false;
  bool isLowBatteryNotificationShown = false;

  // void monitorBatteryInBackground() {
  //   Workmanager().registerPeriodicTask(
  //     "batteryTask",
  //     "batteryCheck",
  //     frequency: const Duration(seconds: 15), // Adjust the frequency as needed
  //     initialDelay: const Duration(seconds: 30), // Delay before the first execution
  //   );
  // }

  void monitorBatteryLevel() {
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final batteryLevel = await _battery.batteryLevel;
      if (controller.fullBatterySwitch.value) {
        if (batteryLevel.toInt() == _currentValue.toInt()) {
          if (!_isNotificationShown) {
            await showBatteryAlarmNotification(
                message:
                    "'Battery level reached to ${_currentValue.toInt().round()}% ");
            _isNotificationShown = true;
            prefs.setBool('isNotificationShown', false);
          } else {
            _isNotificationShown = false;
          }
        }
      }

      if (batteryLevel.toInt() == _currentLowValue.toInt()) {
        if (!isLowBatteryNotificationShown) {
          await showBatteryAlarmNotification();
          isLowBatteryNotificationShown = true;
          prefs.setBool('isLowBatteryNotificationShown', false);
        } else {
          isLowBatteryNotificationShown = false;
        }
      }
    });
    setState(() {});
  }

  RingerModeStatus ringerStatus = RingerModeStatus.unknown;

  Future<void> _getCurrentSoundMode() async {
    ringerStatus = RingerModeStatus.unknown;

    Future.delayed(const Duration(seconds: 1), () async {
      try {
        ringerStatus = await SoundMode.ringerModeStatus;
        if (ringerStatus == RingerModeStatus.silent) {
          await SoundMode.setSoundMode(RingerModeStatus.normal);
          assetsAudioPlayer.open(Audio(selectedRingtonePath));
        }
      } catch (err) {
        ringerStatus = RingerModeStatus.normal;
      }

      setState(() {
        ringerStatus = ringerStatus;
      });
    });
  }

  Future<void> showBatteryAlarmNotification({String? message}) async {
    playAlarmSounds();
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'basic_channel',
        title: 'Battery Alarm',
        body: message ?? 'Battery level reached your selected level!',
      ),
    );
  }

  void playAlarmSounds() async {
    prefs = await SharedPreferences.getInstance();
    BatteryAlarmprovider pro =
        Provider.of<BatteryAlarmprovider>(context, listen: false);
    if (prefs.getBool("ringOnSilentSwitch") == true) {
      print(prefs.getBool("ringOnSilentSwitch"));
      assetsAudioPlayer.open(
        Audio(selectedRingtonePath),
      );
      print("check preferences ${prefs.getBool("ringOnSilentSwitch")}");
    } else {
      print("from preferences ${prefs.getBool("ringOnSilentSwitch")}");
    }

    if (controller.flashlightSwitch.value == true) {
      if (controller.flashType == "short") {
        initializeTorchLight();
        Timer(const Duration(seconds: 3), () {
          toggleFlashlight(false); // Turn off flashlight after 3 seconds
          disposeTorchLight();
        });
      }

      if (controller.flashTypel == "long") {
        initializeTorchLight();
        Timer(const Duration(seconds: 5), () {
          toggleFlashlight(false); // Turn off flashlight after 5 seconds
          disposeTorchLight();
        });
      }
    }

    if (prefs.getBool("vibrationSwitch") == true) {
      if (vibrationSwitch == true) {
        // Vibrate the device based on the selected pattern
        if (selctedVibrate == "small") {
          Vibration.vibrate(duration: 1000);
          Vibration.cancel();
        } else if (selctedVibrate == "medium") {
          Vibration.vibrate(
              pattern: [500, 1000, 500, 2000, 500, 3000, 500, 500]);
          Vibration.cancel();
        } else if (selctedVibrate == "large") {
          Vibration.vibrate(
            pattern: [500, 1000, 500, 2000, 500, 3000, 500, 500],
            intensities: [0, 128, 0, 255, 0, 64, 0, 255],
          );
        }
      } else {}
      print("vibrate Checkkkking ${prefs.getBool("vibrationSwitch")}");
    } else {
      print("vibrate preferences ${prefs.getBool("vibrationSwitch")}");
    }
  }

  void toggleSwitch(bool value) async {
    setState(() {
      controller.fullBatterySwitch.value =
          value; // Update the local state immediately
    });
    await prefs.setBool('fullBatterySwitch', value); // Save the switch state
  }

  void lowToggleSwitch(bool value) async {
    setState(() {
      controller.lowBatterySwitch.value = value;
    });
    await prefs.setBool('lowBatterySwitch', value);
  }

  void ToggleSwitchVibration(bool value) {
    setState(() {
      vibrationSwitch = value;
    });
    prefs.setBool('vibrationSwitch', value);
  }

  void ToggleSwitchFlashlight(bool value) async {
    setState(() {
      controller.flashlightSwitch.value = value;
    });
    await prefs.setBool('flashlightSwitch', value);
  }

  void saveTorch(bool flashlightSwitch) async {
    prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flashlightSwitch', flashlightSwitch);
  }

  void saveVibrationSwitch(bool vibrationswitch) async {
    prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationSwitch', vibrationswitch);
  }

  Future<void> loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    controller.fullBatterySwitch.value =
        prefs.getBool('fullBatterySwitch') ?? false;
    ringOnSilentSwitch = prefs.getBool("ringOnSilentSwitch") ?? false;
    flashtype = prefs.getString("flashType") ?? "short";
    selectedRingtonePath = prefs.getString("selectedRingtone") ?? "";
    controller.lowBatterySwitch.value =
        prefs.getBool('lowBatterySwitch') ?? false;
    controller.soundSwitch.value = prefs.getBool('soundSwitch') ?? false;
    vibrationSwitch = prefs.getBool('vibrationSwitch') ?? false;
    controller.flashlightSwitch.value =
        prefs.getBool('flashlightSwitch') ?? false;
    selctedVibrate = prefs.getString("selctedVibrate") ?? "small";
    _currentValue = (prefs.getDouble('currentValue') ?? 90.0);
    _currentLowValue = (prefs.getDouble('currentLowValue') ?? 20.0);
    controller.currentLowValue.value =
        (prefs.getDouble('currentLowValue') ?? 20.0);
    _isNotificationShown = (prefs.getBool('isNotificationShown') ?? false);
    isLowBatteryNotificationShown =
        (prefs.getBool('isLowBatteryNotificationShown') ?? false);
    controller.vibrationSwitch.value =
        (prefs.getBool('vibrateOnSilent') ?? false);
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeTorchLight();
    _blinkTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BatteryAlarmprovider pro = Provider.of<BatteryAlarmprovider>(context);
    print(
        "btro ${prefs.getDouble('currentLowValue') ?? 20.0} ${prefs.getBool("ringOnSilentSwitch")}");
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: foreGround,
        title: Text(
          'Battery Alarm',
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              child: Card(
                color: foreGround,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenWidth * 0.05,
                          right: screenWidth * 0.02,
                          left: screenWidth * 0.05),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                              'assets/icons/full_battery_alarm_icon.svg'),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Full Battery Alarm',
                            style: TextStyle(
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Obx(() {
                              return Transform.scale(
                                scale: 0.7,
                                child: Switch(
                                  onChanged: toggleSwitch,
                                  value: controller.fullBatterySwitch.value,
                                  activeColor: themeColor,
                                  activeTrackColor: textColor,
                                  inactiveThumbColor: linesColor,
                                  inactiveTrackColor: textColor,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.05),
                      child: Row(
                        children: [
                          Text(
                            'Ring Alarm At',
                            style: TextStyle(
                              color: linesColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: screenWidth * 0.05),
                            child: Slider(
                              value: _currentValue,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: (double value) {
                                setState(() {
                                  _currentValue = value;
                                });
                                prefs.setDouble('currentValue', _currentValue);
                              },
                              activeColor: themeColor,
                              inactiveColor: linesColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: screenWidth * 0.02),
                          child: Text(
                            '${_currentValue.toInt()}%',
                            style: TextStyle(
                              color: linesColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              child: Card(
                color: foreGround,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenWidth * 0.05,
                          right: screenWidth * 0.02,
                          left: screenWidth * 0.05),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                              'assets/icons/low_battery_alarm.svg'),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'low Battery Alarm',
                            style: TextStyle(
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Obx(() {
                              return Transform.scale(
                                scale: 0.7,
                                child: Switch(
                                  onChanged: lowToggleSwitch,
                                  value: controller.lowBatterySwitch.value,
                                  activeColor: themeColor,
                                  activeTrackColor: textColor,
                                  inactiveThumbColor: linesColor,
                                  inactiveTrackColor: textColor,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.05,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Ring Alarm At',
                            style: TextStyle(
                              color: linesColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: screenWidth * 0.05,
                            ),
                            child: Slider(
                              value: _currentLowValue,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: (double value) {
                                setState(() {
                                  _currentLowValue = value;
                                  controller.currentLowValue.value = value;
                                  pro.selectedLowerVal(value);
                                  print(
                                      "tired ${prefs.getDouble("currentLowValue")}");
                                });
                              },
                              activeColor: themeColor,
                              // Set the active color
                              inactiveColor:
                                  linesColor, // Set the inactive color
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            right: screenWidth * 0.02,
                          ),
                          child: Text(
                            '${_currentLowValue.toInt()}%',
                            // Display the slider value here
                            style: TextStyle(
                              color: linesColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              child: Card(
                color: foreGround,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenWidth * 0.02,
                          right: screenWidth * 0.02,
                          left: screenWidth * 0.05),
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/icons/Sound.svg'),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Sound',
                            style: TextStyle(
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Transform.scale(
                              scale: 0.6,
                              child: Switch(
                                onChanged: ToggleSwitchSound,
                                value: controller.soundSwitch.value,
                                activeColor: themeColor,
                                activeTrackColor: textColor,
                                inactiveThumbColor: linesColor,
                                inactiveTrackColor: textColor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: screenWidth * 0.05,
                          ),
                        ],
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Container(
                        width: 1,
                        height: 350, // Adjust the height
                        color: linesColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenWidth * 0.02,
                          right: screenWidth * 0.02,
                          left: screenWidth * 0.05),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                              'assets/icons/Vibrate on Silent.svg'),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Vibration',
                            style: TextStyle(
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Transform.scale(
                              scale: 0.6,
                              child: Switch(
                                onChanged: ToggleSwitchVibration,
                                value: vibrationSwitch,
                                activeColor: themeColor,
                                activeTrackColor: textColor,
                                inactiveThumbColor: linesColor,
                                inactiveTrackColor: textColor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: screenWidth * 0.05,
                          ),
                        ],
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Container(
                        width: 1,
                        height: 350, // Adjust the height
                        color: linesColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: screenWidth * 0.02,
                          right: screenWidth * 0.02,
                          left: screenWidth * 0.05),
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/icons/Flashlight.svg'),
                          const SizedBox(width: 10),
                          Text(
                            'Flashlight',
                            style: TextStyle(
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Transform.scale(
                              scale: 0.6,
                              child: Switch(
                                onChanged: ToggleSwitchFlashlight,
                                value: controller.flashlightSwitch.value,
                                activeColor: themeColor,
                                activeTrackColor: textColor,
                                inactiveThumbColor: linesColor,
                                inactiveTrackColor: textColor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: screenWidth * 0.05,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
