import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:battery_alarm/views/Ringtones/ringtones.dart';
import 'package:battery_alarm/views/controller/home_controller.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lecle_volume_flutter/lecle_volume_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:volume_controller/volume_controller.dart';

import 'ChargingHistory/charging_history_provider.dart';
import 'Ringtones/batteryalarm_provider.dart';
import 'Ringtones/screen_flash_type.dart';
import 'Ringtones/screen_vibration_type.dart';
import 'feed_back.dart';
import 'helper.dart';
import 'languages.dart';

class Settings extends StatefulWidget {
  const Settings({super.key, this.rateMyApp});

  final rateMyApp;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool chargeHistorySwitch = false;
  bool isProcessing = false;
  bool ringOnSilentSwitch = false;
  bool notificationSwitch = true;
  late SharedPreferences prefs;
  final Battery battery = Battery();
  double _volumeListenerValue = 0;
  double _setVolumeValue = 0;

  late double maxNotificationVolume = 10.0; // Set a default value
  double _sliderValue = 0.0; // Track slider value separately
  double? currentNotificationVolume;
  late AudioManager audioManager = AudioManager.streamNotification;

  @override
  void initState() {
    _checkBackgroundServiceStatus();
    super.initState();
    _initVolume();
    initNotificationVolume();
    loadSettings();
    battery.onBatteryStateChanged.listen((BatteryState state) {
      if (state == BatteryState.full && notificationSwitch) {
        showBatteryFullNotification(message: "'Battery level reached to 100% ");
        // Call your function to trigger the alarm at 100%
        if (battery.batteryLevel == 100) {
          // Call your function to play the alarm
          playAlarm();
        }
      }
    });

    if (_sliderValue == 0.0) {
      // Check if the slider value hasn't been changed
      if (currentNotificationVolume != null &&
          currentNotificationVolume! <= maxNotificationVolume) {
        setState(() {
          _sliderValue =
              currentNotificationVolume!; // Use the current volume as the initial value
        });
      } else {
        setState(() {
          _sliderValue =
              maxNotificationVolume; // Set the slider to the maximum if the current volume exceeds the range
        });
      }
    }
  }

  Future<void> _initVolume() async {
    final volume = await VolumeController().getVolume();
    setState(() {
      _setVolumeValue = volume ?? 40; // Update the slider value
    });

    VolumeController().listener((volume) {
      setState(() {
        _volumeListenerValue = volume;
        _setVolumeValue =
            volume; // Update the slider value to reflect the system's volume
      });
    });
  }

  Future<void> initNotificationVolume() async {
    await Volume.initAudioStream(audioManager);
    await updateNotificationVolumes();

    if (currentNotificationVolume != null &&
        currentNotificationVolume! <= maxNotificationVolume) {
      setState(() {
        _sliderValue =
            currentNotificationVolume!; // Use the current volume as the initial value
      });
    } else {
      setState(() {
        _sliderValue =
            maxNotificationVolume; // Set the slider to the maximum if the current volume exceeds the range
      });
    }
  }

  Future<void> updateNotificationVolumes() async {
    maxNotificationVolume = await Volume.getMaxVol ?? 1.0;
    currentNotificationVolume = await Volume.getVol ??
        0.0; // Provide a default value if currentNotificationVolume is null
    setState(() {});
  }

  void setNotificationVolume(double volume) async {
    if (volume >= 0 && volume <= maxNotificationVolume) {
      setState(() {
        _sliderValue = volume; // Update the slider value directly
        currentNotificationVolume =
            volume; // Update current notification volume
      });

      // Update the notification volume using Volume.setVol
      try {
        await Volume.setVol(androidVol: volume.toInt(), iOSVol: volume);
      } catch (e) {
        print('Error setting notification volume: $e');
      }

      // Update notification volumes after setting the volume
      await updateNotificationVolumes();
    }
  }

  String selectedRingtonePath = "";
  void playAlarm() {
    BatteryAlarmprovider pro =
        Provider.of<BatteryAlarmprovider>(context, listen: false);
    AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

    // Check if a ringtone is selected and it's not empty or null
    if (pro.selectedRingtonePath != null &&
        pro.selectedRingtonePath!.isNotEmpty) {
      // Play the selected ringtone
      try {
        assetsAudioPlayer.open(
          Audio(pro.selectedRingtonePath!),
        );
      } catch (e) {
        print('Error playing selected ringtone: $e');
      }
    } else {
      // Use a default sound or handle the case when no ringtone is selected
    }

    // Other alarm logic...
  }

  _checkBackgroundServiceStatus() async {
    bool serviceStatus = await isBackgroundServiceRunning();

    isBackgroundServiceRunningNotifier.value = serviceStatus;
  }

  Future<void> showBatteryFullNotification({String? message}) async {
    //playAlarmSounds();
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'basic_channel',
        title: 'Battery Alarm',
        body: message ?? 'Battery level reached your selected level!',
      ),
    );
  }

  void saveVolume(double value) async {
    prefs = await SharedPreferences.getInstance();
    prefs.setDouble('volumeValue', value);
  }

  Future<double> getVolumeValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // If the key doesn't exist, return a default value (e.g., 50)
    return prefs.getDouble('volumeValue') ?? 50.0;
  }

  void toggleRingOnSilent(bool value) async {
    setState(() {
      controller.ringOnSilentSwitch.value =
          value; // Update the local state immediately
    });
    // await prefs.setBool('ringOnSilent', value); // Save the switch state
  }

  void chargeHistoryToggle(bool value) {
    setState(() {
      controller.charging.value = value;
    });
    prefs.setBool('chargeHistorySwitch', value);
  }

  void toggleVibrateOnSilent(bool value) {
    setState(() {
      controller.vibrationSwitch.value = value;
    });
    prefs.setBool("vibrateOnSilent", value);
    if (value) {
      VolumeController().maxVolume();
    } else {
      VolumeController().muteVolume();
    }
  }

  void chargeNotificationToggle(bool value) {
    setState(() {
      notificationSwitch = value;
    });
    prefs.setBool('notificationSwitch', value);
  }

  void _saveSliderValue(double value) {
    setState(() {
      _sliderValue = value;
    });
    prefs.setDouble('sliderValue', value);
  }

  Future<void> loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('chargeHistorySwitch')) {
      chargeHistorySwitch = true;
      prefs.setBool('chargeHistorySwitch', true);
    } else {
      chargeHistorySwitch = prefs.getBool('chargeHistorySwitch') ?? false;
    }

    //chargeHistorySwitch = prefs.getBool('chargeHistorySwitch') ?? false;
    // backgroundAppSwitch = prefs.getBool('backgroundAppSwitch') ?? false;
    if (!prefs.containsKey('notificationSwitch')) {
      prefs.setBool('notificationSwitch', true);
      notificationSwitch = true;
    } else {
      notificationSwitch = prefs.getBool('notificationSwitch') ?? false;
    }

    if (prefs.containsKey('sliderValue')) {
      setState(() {
        _sliderValue = prefs.getDouble('sliderValue') ?? 0.0;
      });
    }

    //notificationSwitch = prefs.getBool('notificationSwitch') ?? false;
    controller.temperature.value = prefs.getBool("temperature") ?? false;
    controller.vibrationSwitch.value =
        prefs.getBool("vibrateOnSilent") ?? false;
    controller.ringOnSilentSwitch.value =
        prefs.getBool('ringOnSilent') ?? false;
    double savedValue = prefs.getDouble('volumeValue') ?? 100;

    _setVolumeValue = savedValue;

    setState(() {});
  }

  void toggleTemp(bool val) {
    setState(() {
      controller.temperature.value = val;
    });
    prefs.setBool("temperature", controller.temperature.value);
  }

  @override
  void dispose() {
    VolumeController().removeListener();
    super.dispose();
  }

  var controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final topMargin = screenHeight * 0.02; // Margin from the top
    final leftMargin = screenWidth * 0.02; // Margin from the top
    final rightMargin = screenWidth * 0.02; // Margin from the right
    final upMargin = screenHeight * 0.01;
    BatteryAlarmprovider pro = Provider.of<BatteryAlarmprovider>(context);

    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: textColor),
          backgroundColor: foreGround,
          title: Text(
            'Setting',
            style: TextStyle(color: textColor),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.03),
            child: Column(
              children: [
                SizedBox(height: topMargin),
                Padding(
                  padding: EdgeInsets.only(
                      top: screenWidth * 0.05,
                      right: screenWidth * 0.05,
                      left: screenWidth * 0.05),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    child: Card(
                      color: foreGround,
                      child: Column(
                        children: [
                          SizedBox(
                            height: upMargin,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: leftMargin,
                              ),
                              SizedBox(
                                width: leftMargin,
                              ),
                              ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                      textColor, BlendMode.srcIn),
                                  child: SvgPicture.asset(
                                      'assets/icons/ic_baseline-history.svg')),
                              SizedBox(
                                width: leftMargin,
                              ),
                              Text(
                                'Show Charging History',
                                style: TextStyle(color: textColor),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Obx(() {
                                  return Transform.scale(
                                    scale: 0.6,
                                    child: Switch(
                                      onChanged: chargeHistoryToggle,
                                      value: controller.charging.value,
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
                          RotatedBox(
                            quarterTurns: 3,
                            child: Container(
                              width: 1,
                              height: 300,
                              color: linesColor,
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: leftMargin,
                              ),
                              SizedBox(
                                width: leftMargin,
                              ),
                              ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                      textColor, BlendMode.srcIn),
                                  child: SvgPicture.asset(
                                      'assets/icons/charge notification.svg')),
                              SizedBox(
                                width: leftMargin,
                              ),
                              Text(
                                'Full Charge Notification',
                                style: TextStyle(color: textColor),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Transform.scale(
                                  scale: 0.6,
                                  child: Switch(
                                    onChanged: chargeNotificationToggle,
                                    value: notificationSwitch,
                                    activeColor: themeColor,
                                    activeTrackColor: textColor,
                                    inactiveThumbColor: linesColor,
                                    inactiveTrackColor: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Container(
                              width: 1,
                              height: 300,
                              color: linesColor,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.010),
                          Row(
                            children: [
                              SizedBox(
                                height: upMargin,
                                width: leftMargin,
                              ),
                              SizedBox(
                                width: leftMargin,
                              ),
                              SvgPicture.asset(
                                  'assets/icons/Temperature Unit.svg'),
                              SizedBox(
                                width: leftMargin,
                              ),
                              Text(
                                'Temperature Unit',
                                style: TextStyle(color: textColor),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Obx(() {
                                  return GestureDetector(
                                    onTap: () {
                                      // Simulate the onChanged event
                                      setState(() {
                                        controller.temperature.value =
                                            !controller.temperature.value;
                                        // Additional logic or state management as required
                                      });
                                    },
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.0185),
                                      child: ToggleSwitch(
                                        minHeight: 20,
                                        minWidth: 35.0,
                                        cornerRadius: 20.0,
                                        activeBgColors: [
                                          [themeColor!],
                                          [themeColor!]
                                        ],
                                        activeFgColor: Colors.white,
                                        inactiveBgColor: Colors.black,
                                        inactiveFgColor: Colors.white,
                                        initialLabelIndex:
                                            controller.temperature.value
                                                ? 1
                                                : 0,
                                        totalSwitches: 2,
                                        labels: ['C', 'F'],
                                        radiusStyle: true,
                                        onToggle: (index) {
                                          setState(() {
                                            controller.temperature.value =
                                                !controller.temperature.value;
                                          });
                                          prefs.setBool("temperature",
                                              controller.temperature.value);
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          // RotatedBox(
                          //   quarterTurns: 3,
                          //   child: Container(
                          //     width: 1,
                          //     height: 300,
                          //     color: linesColor,
                          //   ),
                          // ),
                          // Row(
                          //   children: [
                          //     SizedBox(
                          //       width: leftMargin,
                          //     ),
                          //     SizedBox(
                          //       width: leftMargin,
                          //     ),
                          //     SvgPicture.asset(
                          //       'assets/icons/Battery Alarm.svg',
                          //       color: Colors.white,
                          //     ),
                          //     SizedBox(
                          //       width: leftMargin,
                          //     ),
                          //     Text(
                          //       'Background Running',
                          //       style: TextStyle(color: textColor),
                          //     ),
                          //     const Spacer(),
                          //     // Align(
                          //     //   alignment: Alignment.centerRight,
                          //     //   child: ValueListenableBuilder<bool>(
                          //     //       valueListenable: isBackgroundServiceRunningNotifier,
                          //     //       builder: (context, bool isRunning, _) {
                          //     //         controller.backgroundRunning.value = isRunning;
                          //     //
                          //     //         return Switch(
                          //     //           onChanged: controller.backgroundAppToggle,
                          //     //           value: controller.backgroundRunning.value,
                          //     //           activeColor: themeColor,
                          //     //           activeTrackColor: textColor,
                          //     //           inactiveThumbColor: linesColor,
                          //     //           inactiveTrackColor: textColor,
                          //     //         );
                          //     //       }),
                          //     // ),
                          //     controller.backgroundRunnin()
                          //   ],
                          // ),

                          SizedBox(height: upMargin),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: screenWidth * 0.05,
                    left: screenWidth * 0.05,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    child: Card(
                      color: foreGround,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Ringtones()));
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: leftMargin,
                                  right: rightMargin,
                                  top: topMargin,
                                  bottom: topMargin),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: leftMargin,
                                  ),
                                  SvgPicture.asset('assets/icons/Ringtone.svg'),
                                  SizedBox(
                                    width: leftMargin,
                                  ),
                                  Text(
                                    'Ringtone',
                                    style: TextStyle(color: textColor),
                                  ),
                                  const Spacer(),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: SvgPicture.asset(
                                          'assets/icons/right circle.svg')),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Ringtones()));
                            },
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                width: 1,
                                height: 300,
                                color: linesColor,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: leftMargin,
                                right: rightMargin,
                                top: topMargin),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: leftMargin,
                                ),
                                SvgPicture.asset('assets/icons/Volume.svg'),
                                SizedBox(
                                  width: leftMargin,
                                ),
                                Text(
                                  'Volume',
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: upMargin, bottom: topMargin),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    min: 0.0,
                                    max: maxNotificationVolume,
                                    divisions: maxNotificationVolume.toInt(),
                                    onChanged: (value) {
                                      _saveSliderValue(value);
                                      setState(() {
                                        _sliderValue =
                                            value; // Update _sliderValue directly
                                      });
                                      setNotificationVolume(value
                                          .toDouble()); // Update notification volume when slider changes
                                    },
                                    value: _sliderValue,
                                    activeColor: themeColor,
                                    inactiveColor: linesColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Text(
                                    '${(_sliderValue.clamp(0.0, 10.0) * 10).toInt()}%', // Display as a percentage
                                    style: TextStyle(
                                      color: linesColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Container(
                              width: 1,
                              height: 300,
                              color: linesColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(ScreenVibrationType());
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: leftMargin,
                                  right: rightMargin,
                                  top: topMargin,
                                  bottom: topMargin),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: leftMargin,
                                  ),
                                  SvgPicture.asset(
                                      'assets/icons/material-symbols_vibration.svg'),
                                  SizedBox(
                                    width: leftMargin,
                                  ),
                                  Text(
                                    'Vibration Type',
                                    style: TextStyle(color: textColor),
                                  ),
                                  const Spacer(),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: SvgPicture.asset(
                                          'assets/icons/right circle.svg')),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(ScreenVibrationType());
                            },
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                width: 1,
                                height: 300,
                                color: linesColor,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: leftMargin,
                              ),
                              SizedBox(
                                width: leftMargin,
                              ),
                              SvgPicture.asset(
                                  'assets/icons/Ring on Silent.svg'),
                              SizedBox(
                                width: leftMargin,
                              ),
                              Text(
                                'Ring On Silent',
                                style: TextStyle(color: textColor),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Obx(() {
                                  return Transform.scale(
                                    scale: 0.6,
                                    child: Switch(
                                      onChanged: (value) {
                                        toggleRingOnSilent(value);
                                        pro.ringOnSilent(value);
                                      },
                                      value:
                                          controller.ringOnSilentSwitch.value,
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
                          RotatedBox(
                            quarterTurns: 3,
                            child: Container(
                              width: 1,
                              height: 300,
                              color: linesColor,
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: leftMargin,
                              ),
                              SizedBox(
                                width: leftMargin,
                              ),
                              SvgPicture.asset(
                                  'assets/icons/Vibrate on Silent.svg'),
                              SizedBox(
                                width: leftMargin,
                              ),
                              Text(
                                'Vibrate On Silent',
                                style: TextStyle(color: textColor),
                              ),
                              const Spacer(),
                              Obx(() {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Transform.scale(
                                    scale: 0.6,
                                    child: Switch(
                                      onChanged: (value) {
                                        toggleVibrateOnSilent(value);
                                        pro.vibrateSwitich(value);
                                      },
                                      value: controller.vibrationSwitch.value,
                                      activeColor: themeColor,
                                      activeTrackColor: textColor,
                                      inactiveThumbColor: linesColor,
                                      inactiveTrackColor: textColor,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Container(
                              width: 1,
                              height: 300,
                              color: linesColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(ScreenFlashType());
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: leftMargin,
                                  right: rightMargin,
                                  top: topMargin,
                                  bottom: topMargin),
                              child: GestureDetector(
                                onTap: () {
                                  Get.to(ScreenFlashType());
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    SvgPicture.asset(
                                        'assets/icons/Flashing Type.svg'),
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    Text(
                                      'Flashing Type',
                                      style: TextStyle(color: textColor),
                                    ),
                                    const Spacer(),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: SvgPicture.asset(
                                            'assets/icons/right circle.svg')),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ElevatedButton(
                          //   onPressed: () => _getCurrentSoundMode(),
                          //   child: Text('Get current sound mode'),
                          // ),
                          // Text("$ringerStatus")
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: screenWidth * 0.05,
                    left: screenWidth * 0.05,
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      child: Card(
                        color: foreGround,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  left: leftMargin,
                                  right: rightMargin,
                                  top: topMargin,
                                  bottom: topMargin),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            LanguagesScreen()),
                                  );
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    SvgPicture.asset(
                                        'assets/icons/Language.svg'),
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    Text(
                                      'Language',
                                      style: TextStyle(color: textColor),
                                    ),
                                    const Spacer(),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: SvgPicture.asset(
                                            'assets/icons/right circle.svg')),
                                  ],
                                ),
                              ),
                            ),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                width: 1,
                                height: 300,
                                color: linesColor,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                  left: leftMargin,
                                  right: rightMargin,
                                  top: topMargin,
                                  bottom: topMargin),
                              child: GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    SvgPicture.asset(
                                        'assets/icons/Share App.svg'),
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    Text(
                                      'Share App',
                                      style: TextStyle(color: textColor),
                                    ),
                                    const Spacer(),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: SvgPicture.asset(
                                            'assets/icons/right circle.svg')),
                                  ],
                                ),
                              ),
                            ),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                width: 1,
                                height: 300,
                                color: linesColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CustomRateDialog(
                                              rateMyApp: widget.rateMyApp,
                                            )));
                              },
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: leftMargin,
                                    right: rightMargin,
                                    top: topMargin,
                                    bottom: topMargin),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    SvgPicture.asset(
                                        'assets/icons/Rate us.svg'),
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    Text(
                                      'Rate Us',
                                      style: TextStyle(color: textColor),
                                    ),
                                    const Spacer(),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: SvgPicture.asset(
                                            'assets/icons/right circle.svg')),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CustomRateDialog(
                                              rateMyApp: widget.rateMyApp,
                                            )));
                              },
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 300,
                                  color: linesColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FeedbackForm()));
                              },
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: leftMargin,
                                    right: rightMargin,
                                    top: topMargin,
                                    bottom: topMargin),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                FeedbackForm()));
                                  },
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: leftMargin,
                                      ),
                                      SvgPicture.asset(
                                          'assets/icons/mdi_feedback.svg'),
                                      SizedBox(
                                        width: leftMargin,
                                      ),
                                      Text(
                                        'Feedback',
                                        style: TextStyle(color: textColor),
                                      ),
                                      const Spacer(),
                                      Align(
                                          alignment: Alignment.centerRight,
                                          child: SvgPicture.asset(
                                              'assets/icons/right circle.svg')),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                width: 1,
                                height: 300,
                                color: linesColor,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                  left: leftMargin,
                                  right: rightMargin,
                                  top: topMargin,
                                  bottom: topMargin),
                              child: GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    SvgPicture.asset(
                                        'assets/icons/wpf_privacy.svg'),
                                    SizedBox(
                                      width: leftMargin,
                                    ),
                                    Text(
                                      'Privacy Policy',
                                      style: TextStyle(color: textColor),
                                    ),
                                    const Spacer(),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: SvgPicture.asset(
                                            'assets/icons/right circle.svg')),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                )
              ],
            ),
          ),
        ));
  }
}

class CustomRateDialog extends StatefulWidget {
  final RateMyApp rateMyApp;

  const CustomRateDialog({Key? key, required this.rateMyApp}) : super(key: key);

  @override
  _CustomRateDialogState createState() => _CustomRateDialogState();
}

class _CustomRateDialogState extends State<CustomRateDialog> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      backgroundColor: foreGround, // Set the background color
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: screenHeight * 0.012,
          ),
          Center(child: SvgPicture.asset('assets/icons/Group 21238.svg')),
          SizedBox(
            height: screenHeight * 0.012,
          ),
          AutoSizeText(
            'Enjoying the App?',
            style: TextStyle(color: textColor),
          ),
          SizedBox(
            height: screenHeight * 0.012,
          ),
          Center(
            child: AutoSizeText(
              'We work super hard to make application better for you and would love to know',
              style: TextStyle(
                  color: textColor, fontSize: 10), // Set content text color
              maxLines: 2,
            ),
          ),
          SizedBox(
            height: screenHeight * 0.012,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = i;
                    });
                  },
                  child: Row(
                    children: [
                      _rating >= i
                          ? SvgPicture.asset(
                              'assets/icons/Vector.svg',
                              color: Colors.yellow,
                            )
                          : SvgPicture.asset(
                              'assets/icons/Vector.svg',
                              color: Colors.grey,
                            ),
                      SizedBox(
                        width: screenWidth * 0.012,
                      )
                    ],
                  ),
                ),
              SizedBox(
                width: screenWidth * 0.015,
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thanks for your feedback!')),
            );

            if (_rating >= 4) {
              // Redirect to rate on the store
              widget.rateMyApp.launchStore();
            } else {
              // Move back to settings
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            primary: themeColor, // Setting button color
            minimumSize: Size(double.infinity, 50), // Making button block-style
          ),
          child: Text('Submit', style: TextStyle(color: textColor)),
        ),
      ],
    );
  }
}
