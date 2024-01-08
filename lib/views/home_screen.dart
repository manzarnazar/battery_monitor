// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:ffi';

import 'package:battery_alarm/views/battery_info.dart';
import 'package:battery_alarm/views/battery_monitor.dart';
import 'package:battery_alarm/views/controller/home_controller.dart';
import 'package:battery_alarm/views/device_info.dart';
import 'package:battery_alarm/views/settings.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/custom_animation.dart';
import '../widgets/home_screen_animation.dart';
import 'ChargingHistory/charging_history.dart';
import 'ChargingHistory/charging_history_provider.dart';
import 'battery_alarm.dart';
import 'helper.dart';
import 'languages.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.rateMyApp});

  final rateMyApp;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String appBarTitle = 'Battery Alarm';
  final Battery battery = Battery();
  BatteryState lastState = BatteryState.unknown;
  int lastPercentage = 0;
  DateTime? plugInTime;
  int plugInPercentage = 0;
  int totalPercentage = 0;
  bool BlockPopUp = false;
  bool _isHomeTabSelected = true;

  StreamSubscription<BatteryState>? _batteryStateSubscription;
  DateTime chargeStartTime = DateTime.now();
  bool newvalue = false;
  late SharedPreferences prefs;

  @override
  var controller = Get.put(HomeController());

  void initState() {
    super.initState();
    setDefaultSettings();

    //getBackgroundRunningToggle();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // if (BlockPopUp == false) {
      //   _showPopup();
      // }
      battery.onBatteryStateChanged.listen((BatteryState state) async {
        final status =
            state == BatteryState.charging ? 'Charging' : 'Discharging';
        final timestamp = DateTime.now();
        final batteryLevel = await battery.batteryLevel;

        if (state != lastState) {
          lastState = state;

          if (state == BatteryState.charging) {
            plugInTime = timestamp;
            plugInPercentage = batteryLevel;
            chargeStartTime = timestamp;
            setState(() {});
          } else if (state == BatteryState.discharging && plugInTime != null) {
            final plugOutTime = timestamp;
            final plugOutPercentage = batteryLevel;
            final chargeTime = plugOutTime.difference(chargeStartTime);
            setState(() {});

            //asign data to BatteryHistory Class to add in data base

            final historyEntry = BatteryHistory(
              chargeTime: chargeTime,
              status: status,
              percentage: plugOutPercentage,
              timestamp: timestamp,
              plugInTimestamp: plugInTime,
              plugOutTimestamp: plugOutTime,
              plugInPercentage: plugInPercentage,
              totalPercentage: totalPercentage,
            );

            // charging_history_provider.dart  function to add entry in data base
            final historyProvider =
                Provider.of<ChargingHistoryProvider>(context, listen: false);
            await historyProvider.addHistoryEntry(historyEntry);

            plugInTime = null;
          }
        } else if (state == BatteryState.charging) {
          totalPercentage += batteryLevel - lastPercentage;
        }

        lastPercentage = batteryLevel;
      });
    });
    _initBatteryChargingState();
  }

  void setDefaultSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

    if (isFirstLaunch) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LanguagesScreen()));
      bool permissionGranted = await _showPermissionDialog(context);

      if (permissionGranted) {
        setState(() {
          prefs.setBool('chargeNotification', true);
          prefs.setBool('chargeHistory', true);
        });
      }

      prefs.setBool('firstLaunch', false);
    }
  }

  Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: foreGround,
              title: Text(
                'Permission Request',
                style: TextStyle(color: textColor),
              ),
              content: Text(
                'Do you grant permission to enable Notifications?'
                'These can be configured in settings',
                style: TextStyle(color: textColor),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Grant permission
                  },
                  child: Text(
                    'Yes',
                    style: TextStyle(color: animation),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if the dialog is dismissed
  }

  Future<void> getBackgroundRunningToggle() async {
    prefs = await SharedPreferences.getInstance();
    // Get the value of "backgroundRunning" from SharedPreferences
    BlockPopUp = prefs.getBool("backgroundRunning") ?? false;
    // Update the observable variable
  }

  Future<void> _initBatteryChargingState() async {
    _batteryStateSubscription =
        battery.onBatteryStateChanged.listen((BatteryState state) {
      if (state == BatteryState.charging) {
        setState(() {
          isCharging = true;
        });
      } else {
        setState(() {
          isCharging = false;
        });
      }
    });
  }

  BottomNavigationBarItem buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
      activeIcon: Stack(
        children: [
          Icon(icon),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2.0,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        appBarTitle = 'Battery Alarm';
        _isHomeTabSelected = true;
      } else if (index == 1) {
        appBarTitle = 'Charging History';
        _isHomeTabSelected = false;
      } else if (index == 2) {
        appBarTitle = 'Battery Information';
        _isHomeTabSelected = false;
      }
    });
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        if (_isHomeTabSelected == false || _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Switch to the Home tab
            _isHomeTabSelected = true;
            appBarTitle = 'Battery Alarm'; // Reset to true to allow app closing
          });
          return false; // Prevent app from closing
        } else {
          SystemNavigator.pop();
          return true; // Allow the app to close
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: foreGround,
          title: Align(
              alignment: Alignment.topLeft,
              child: Text(
                appBarTitle,
                style: TextStyle(color: textColor),
              )),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Settings(rateMyApp: widget.rateMyApp)));
              },
              icon: Icon(
                Icons.settings,
                color: textColor,
              ),
            ),
          ],
        ),
        body: _buildBody(_selectedIndex),
        bottomNavigationBar: CustomBottomNavigationBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          screenWidth: screenWidth,
        ),
      ),
    );
  }
}

Widget _buildBody(int selectedIndex) {
  switch (selectedIndex) {
    case 0:
      return const HomeTabContent();
    case 1:
      // Implement your "History" tab content here
      return const BatteryHistoryScreen();
    case 2:
      // Show the "Info" tab content
      return BatteryInfo();
    default:
      return Container(); // Handle other cases as needed
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final double screenWidth;

  const CustomBottomNavigationBar(
      {super.key,
      required this.selectedIndex,
      required this.onItemTapped,
      required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.0012),
      height: screenHeight * 0.08,
      color: foreGround,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => onItemTapped(0),
            child: SvgIconWithLabel(
              iconAsset: 'assets/icons/clarity_home-solid.svg',
              label: 'Home',
              isSelected: selectedIndex == 0,
              screenWidth: screenWidth,
            ),
          ),
          GestureDetector(
            onTap: () => onItemTapped(1),
            child: SvgIconWithLabel(
              iconAsset: 'assets/icons/ic_baseline-history.svg',
              label: 'History',
              isSelected: selectedIndex == 1,
              screenWidth: screenWidth,
            ),
          ),
          GestureDetector(
            onTap: () => onItemTapped(2),
            child: SvgIconWithLabel(
              iconAsset: 'assets/icons/ri_battery-2-charge-fill.svg',
              label: 'Info',
              isSelected: selectedIndex == 2,
              screenWidth: screenWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class SvgIconWithLabel extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isSelected;
  final double screenWidth;
  final double itemWidth = 100.0;

  const SvgIconWithLabel({
    super.key,
    required this.iconAsset,
    required this.label,
    this.isSelected = false,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconAsset,
            color: isSelected ? themeColor : Colors.grey,
          ),
          SizedBox(
              height: screenWidth *
                  0.003), // Adjust the spacing between icon and label
          Text(
            label,
            style: TextStyle(
              color: isSelected ? themeColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(height: screenWidth * 0.006),
          if (isSelected)
            Container(
              width: itemWidth * 0.5, // Adjust the width of the underline
              height: screenWidth * 0.002,
              color: themeColor, // Color of the underline
            ),
        ],
      ),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  var controller = Get.put(HomeController());

  bool newValue = false;
  final battery = Battery();
  int batteryTemperature = 0;
  String batteryHealth = "";
  int batteryVoltage = 0;
  int batteryCapacity = 0;
  bool BlockPopUp = false;
  final BatteryInfoPlugin _batteryInfo = BatteryInfoPlugin();

  // StreamSubscription<BatteryState>? _batteryStateSubscription;
  int batteryLevel = 0;

  Duration timeRemaining = const Duration(hours: 0, minutes: 0);
  bool isPopupShown = false;

  late BatteryMonitor _batteryMonitor;
  late SharedPreferences prefs;
  @override
  void initState() {
    loadTemptoggle();
    // alarmSetting();

    super.initState();
    // Schedule the execution of _showPopup after initState is completed
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      // _showPopup();
    });

    _initBatteryInfo();
  }

  void alarmSetting() async {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      // print("object: ${prefs.getDouble('currentLowValue') ?? 20.0}");
    });
  }

  void togglebackgroundScreen() async {
    prefs = await SharedPreferences.getInstance();
    controller.temperature.value = prefs.getBool("backgroundRunning") ?? false!;
  }

  void loadTemptoggle() async {
    prefs = await SharedPreferences.getInstance();
    controller.temperature.value = prefs.getBool("temperature") ?? false!;
  }

  void fetchBatteryInfo() async {
    final batteryStatus = await battery.batteryLevel;

    setState(() {
      batteryLevel = batteryStatus;
    });
  }

  Future<void> _initBatteryInfo() async {
    final info = await _batteryInfo.androidBatteryInfo;
    setState(() {
      batteryTemperature = info?.temperature ?? 0;
      batteryHealth = info?.health ?? "Unknown";
      batteryVoltage = info?.voltage ?? 0;
      batteryCapacity = info?.batteryCapacity ?? 0;
    });
  }

  Future<void> getBackgroundRunningToggle() async {
    prefs = await SharedPreferences.getInstance();
    // Get the value of "backgroundRunning" from SharedPreferences
    BlockPopUp = prefs.getBool("backgroundRunning") ?? false;
    // Update the observable variable
  }

  @override
  void dispose() {
    alarmSetting();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print("from Home Screen ${prefs.getDouble('currentLowValue') ?? 20.0}");
    fetchBatteryInfo();
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
                bottom: screenWidth * 0.02,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                top: screenWidth * 0.05),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              child: Card(
                color: foreGround,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isCharging == true
                                        ? 'Charging'
                                        : 'No Charging',
                                    style: TextStyle(
                                        color: isCharging == true
                                            ? animation
                                            : themeColor,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenWidth * 0.05),
                              Row(
                                children: [
                                  Text(
                                    '$batteryLevel%',
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${timeRemaining.inHours}h ${timeRemaining.inMinutes.remainder(60)}m',
                                    style: TextStyle(color: linesColor),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child:
                                  //BatteryGaugeDemo(
                                  //   isHorizontal: false,
                                  //   isGrid: false,
                                  // ), //AnimatedBatteryIndicator(),
                                  AnimatedCircularProgressIndicator(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                bottom: screenWidth * 0.03),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              child: Card(
                color: foreGround,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'assets/icons/Temperature.svg'),
                                SizedBox(width: screenWidth * 0.01),
                                Obx(() {
                                  return controller.temperature.value == true
                                      ? Text(
                                          '${(batteryTemperature * 9 / 5 + 32)} °F',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          '$batteryTemperature °C',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                }),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.015),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Temperature',
                                  style: TextStyle(
                                    color: linesColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                width: 1,
                                height: screenWidth * 0.4,
                                color: linesColor,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'assets/icons/Battery Health.svg'),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  batteryHealth.split('_').last.toUpperCase(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.015),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Battery Health',
                                  style: TextStyle(
                                    color: linesColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: screenWidth * 0.3,
                        color: linesColor,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/icons/Voltage.svg'),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  '$batteryVoltage V',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.015),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Voltage',
                                  style: TextStyle(
                                    color: linesColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Container(
                                width: 1,
                                height: screenWidth * 0.4,
                                color: linesColor,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'assets/icons/Battery Capacity.svg'),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  '$batteryCapacity mAh',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.015),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Capacity',
                                  style: TextStyle(
                                    color: linesColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                right: screenWidth * 0.05, left: screenWidth * 0.05),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BatteryAlarm(),
                  ),
                );
              },
              icon: SvgPicture.asset('assets/icons/Battery Alarm.svg'),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.04),
                    child: Text(
                      'Battery Alarm',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  SvgPicture.asset('assets/icons/NEXT_ARROW-2.svg'),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: foreGround,
                padding: EdgeInsets.all(screenWidth * 0.05),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.0125),
          Padding(
            padding: EdgeInsets.only(
                right: screenWidth * 0.05, left: screenWidth * 0.05),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DeviceInfoScreen()),
                );
              },
              icon: SvgPicture.asset('assets/icons/Device Information.svg'),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.04),
                    child: Text(
                      'Device Information',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  SvgPicture.asset('assets/icons/NEXT_ARROW.svg'),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: foreGround,
                padding: EdgeInsets.all(screenWidth * 0.05),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
