import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/colors.dart';
import 'controller/home_controller.dart';

class BatteryInfo extends StatefulWidget {
  BatteryInfo({Key? key}) : super(key: key);

  @override
  State<BatteryInfo> createState() => _BatteryInfoState();
}

class _BatteryInfoState extends State<BatteryInfo> {
  int batteryTemperature = 0;
  String batteryHealth = "";
  int batteryVoltage = 0;
  int batteryCapacity = 0;
  bool isCharging = false;
  final BatteryInfoPlugin _batteryInfo = BatteryInfoPlugin();
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  bool isAndroid = false;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  Battery battery = Battery();
  var controller = Get.put(HomeController());
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initBatteryInfo();
    _initBatteryChargingState();
    initPlatformState();
    loadTemptoggle();
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel(); // Cancel subscription when disposing
    super.dispose();
  }

  void loadTemptoggle() async{
    prefs = await SharedPreferences.getInstance();
    controller.temperature.value = prefs.getBool("temperature")?? false!;
  }

  Future<Text> getChargerType() async {
    Battery battery = Battery();
    await battery.onBatteryStateChanged.first; // Wait for the initial battery state update

    if (battery.batteryState == BatteryState.charging) {
      return Text('Wired', style: TextStyle(
        color: textColor
      ),);
    }
    return Text('not connected',style: TextStyle(
        color: textColor));
  }

  String getChargingStatus() {
    return isCharging ? 'Wired' : 'Not connected';
  }


  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
        isAndroid = true;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        isAndroid = false;
      } else {
        deviceData = <String, dynamic>{'Error:': 'Unsupported platform'};
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'displaySizeInches':
      ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
      'displayWidthPixels': build.displayMetrics.widthPx,
      'displayWidthInches': build.displayMetrics.widthInches,
      'displayHeightPixels': build.displayMetrics.heightPx,
      'displayHeightInches': build.displayMetrics.heightInches,
      'displayXDpi': build.displayMetrics.xDpi,
      'displayYDpi': build.displayMetrics.yDpi,
      'serialNumber': build.serialNumber,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const separatorWidth = 1.0; // Width of the separator
    final separatorMargin = screenWidth * 0.02; // Margin based on screen width
    final topMargin = screenHeight * 0.02; // Margin from the top
    final leftMargin = screenWidth * 0.02; // Margin from the top
    final rightMargin = screenWidth * 0.02; // Margin from the right
    final upMargin = screenHeight * 0.01;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          children: [
            SizedBox(height: topMargin),
            Row(
              children: [
                SizedBox(width: leftMargin),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/batteryicons/status charger.svg',
                                  width: screenWidth * 0.05, // Adjust the width of the SvgPicture
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Expanded(
                                  child: AutoSizeText(
                                    'Status Charging',
                                    style: TextStyle(color: linesColor),
                                    maxLines: 2, // You can adjust the font size as needed
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: upMargin),
                            Padding(
                              padding:  EdgeInsets.only(left: screenWidth * 0.06),
                              child: Text(
                                isCharging ? 'Charging' : 'No Charging',
                                style: TextStyle(
                                  color: isCharging ? animation : themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Technology.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Technology',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.075),
                              child: Text(_deviceData['brand'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: textColor,
                                  )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: rightMargin),
              ],
            ),
            Row(
              children: [
                SizedBox(width: leftMargin),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Battery Health.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Health',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.07),
                              child: Text(
                                batteryHealth.split('_').last.toUpperCase(),
                                style: TextStyle(
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Temperature.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Temperature',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.075),
                              child: Obx(() {
                                return controller.temperature.value == true
                                    ? Text(
                                  '${(batteryTemperature * 9/5 + 32)} °F',
                                  style: TextStyle(
                                    color: textColor,
                                  ),
                                )
                                    : Text(
                                  '$batteryTemperature °C',
                                  style: TextStyle(
                                    color: textColor,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: rightMargin),
              ],
            ),
            Row(
              children: [
                SizedBox(width: leftMargin),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Voltage.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Voltage',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.065),
                              child: Text('$batteryVoltage v',
                                  style: TextStyle(
                                    color: textColor,
                                  )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Charger.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Charger',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.075),
                              child: Text(
                                getChargingStatus(),
                                style: TextStyle(
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: rightMargin),
              ],
            ),
            Row(
              children: [
                SizedBox(width: leftMargin),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/model.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Model',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.065),
                              child: Text(_deviceData['model'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: textColor,
                                  )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Battery Capacity.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Capacity',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.075),
                              child: Text('$batteryCapacity mAH',
                                  style: TextStyle(
                                    color: textColor,
                                  )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: rightMargin),
              ],
            ),
            Row(
              children: [
                SizedBox(width: leftMargin),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Android.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Expanded(
                                  child: AutoSizeText(
                                    'Android Version',
                                    style: TextStyle(color: linesColor),
                                    maxLines: 2, // You can adjust the font size as needed
                                    overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.065),
                              child: Text(_deviceData['version.release'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: textColor,
                                  )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    child: Card(
                      color: foreGround,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.05, bottom: screenWidth * 0.05,
                            left: screenWidth * 0.03, right: screenWidth * 0.001),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/batteryicons/Build_id.svg'),
                                SizedBox(width: screenWidth * 0.01,),
                                Text('Build ID',
                                    style: TextStyle(
                                      color: linesColor,
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height: upMargin),
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.075),
                              child: Text(
                                _deviceData['version.incremental'] ?? 'Unknown',
                                style: TextStyle(
                                  color: textColor,
                                ),
                                maxLines: 1, // Ensure only one line is displayed
                                overflow: TextOverflow.ellipsis, // Add ellipsis if the text exceeds one line
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: rightMargin),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
