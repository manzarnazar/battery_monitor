// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:developer';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memory_info/memory_info.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:system_info_plus/system_info_plus.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  _DeviceInfoScreenState createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  Battery battery = Battery();
  int batteryLevel = 0;
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  bool isAndroid = false;

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
    getDeviceRam();
    getMemoryInfo();
    initPlatformState();
  }

  Widget _buildDeviceInfoRow(String label, String value) {
    // String displayValue = isAndroid ? _deviceData[label] : value;
    // displayValue = displayValue ?? "N/A"; // Display "N/A" if the value is null

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, right: 10, left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: newLinesColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  double calculateScreenDensity(Map<String, dynamic> deviceData) {
    double xDpi = deviceData['displayXDpi']?.toDouble() ?? 0.0;
    double yDpi = deviceData['displayYDpi']?.toDouble() ?? 0.0;

    // Calculating density using DPI values
    double screenDensity = sqrt(pow(xDpi, 2) + pow(yDpi, 2));

    return screenDensity;
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


  int _deviceMemory = -1;
  int remaingMemory = -1;
  Future<void> getDeviceRam() async {
    int deviceMemory;

    try {
      deviceMemory = await SystemInfoPlus.physicalMemory ?? -1;

    } on PlatformException {
      deviceMemory = -1;
    }

    if (!mounted) return;

    setState(() {
      // Convert bytes to gigabytes and round to two decimal places
      _deviceMemory = deviceMemory;
    });
  }

  Memory? _memory;
  DiskSpace? _diskSpace;
  Future<void> getMemoryInfo() async {
    Memory? memory;
    DiskSpace? diskSpace;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      memory = await MemoryInfoPlugin().memoryInfo;
      diskSpace = await MemoryInfoPlugin().diskSpace;
    } on PlatformException catch (e) {
      print('error $e');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    if (memory != null || diskSpace != null)
      setState(() {
        double? totalSpace = _diskSpace?.totalSpace?.toDouble();
        Map<String, dynamic> totalSpaceMap = {'totalSpace': totalSpace};

        // Convert the new map to a string
        // String diskInfo = encoder.convert(totalSpaceMap);
        _memory = memory;
        _diskSpace = diskSpace;
      });
  }

  Future<void> _getBatteryLevel() async {

    int batteryStatus = await battery.batteryLevel;
    setState(() {
      batteryLevel = batteryStatus;
    });
    print("battery percentage $batteryLevel");
  }

  @override
  Widget build(BuildContext context) {
    double batteryPercentage = batteryLevel / 100.0;

    JsonEncoder encoder = JsonEncoder.withIndent('  ');
    String memInfo = encoder.convert(_memory?.toMap());
    String diskInfo = encoder.convert(_diskSpace?.toMap());
    Map<String, dynamic> diskMap = json.decode(diskInfo);
    Map<String,dynamic> RamMap = json.decode(memInfo);
    print(memInfo);
    double? freeRamSpace = RamMap['free']?.toDouble();
    double? TotalRamSpace = RamMap['total']?.toDouble();
    double? freeRam = freeRamSpace!/1024.round();
    double? totalRam = TotalRamSpace!/1024.round();
    String formattedFreeRam = freeRam.toStringAsFixed(2);
    String formattedTotalRam = totalRam.toStringAsFixed(2);
    double? diskFreeSpace = diskMap['diskFreeSpace']?.toDouble();
    double? diskTotalSpace = diskMap['diskTotalSpace']?.toDouble();
    double? diskFreeSpaceInGb = diskFreeSpace!/1024.round();
    double? diskTotalSpaceInGb = diskTotalSpace!/1024.round();
    String formattedDiskFreeSpace = diskFreeSpaceInGb.toStringAsFixed(2);
    String formattedDiskTotalSpace = diskTotalSpaceInGb.toStringAsFixed(2);

    Color progressColor = freeRamSpace < 0.4 ? themeColor : animation;
    Color progressColor1 = diskFreeSpace < 0.4 ? themeColor : Colors.orange;
    Color progressColor2 = batteryPercentage < 0.3 ? themeColor : Colors.greenAccent;



    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final upMargin = screenHeight * 0.01;
    double density = calculateScreenDensity(_deviceData);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: foreGround,
        title: Text("Device Information",
        style: TextStyle(
          color: textColor
        ),),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                child: Card(
                  color: foreGround,
                  child: Padding(
                    padding: EdgeInsets.only(left : screenWidth * 0.02, right: screenWidth * 0.02, top: screenWidth * 0.02, bottom: screenWidth * 0.04),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.01),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceEvenly, // Center the circular progress indicators
                            children: [
                              CircularPercentIndicator(
                                radius: 45.0,
                                lineWidth: 8.0,
                                animation: true,
                                animationDuration: 1000,
                                percent: freeRamSpace! / TotalRamSpace!, // Calculate RAM percentage
                                circularStrokeCap: CircularStrokeCap.round,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    AutoSizeText(
                                      '${(freeRamSpace! / TotalRamSpace! * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                                progressColor: progressColor,
                              ),
                              SizedBox(width: screenWidth * 0.012,),
                              CircularPercentIndicator(
                                radius: 45.0,
                                lineWidth: 8.0,
                                animation: true,
                                animationDuration: 1000,
                                percent: diskFreeSpace! / diskTotalSpace!, // Calculate disk space percentage
                                circularStrokeCap: CircularStrokeCap.round,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    AutoSizeText(
                                      '${(diskFreeSpace! / diskTotalSpace! * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                                progressColor: progressColor1, // Set the progress color based on disk space
                              ),
                              SizedBox(width: screenWidth * 0.012,),
                              CircularPercentIndicator(
                                radius: 45.0,
                                lineWidth: 8.0,
                                animation: true,
                                animationDuration: 1000,
                                percent: batteryPercentage,
                                circularStrokeCap: CircularStrokeCap.round,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      '$batteryLevel%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                progressColor:
                                    progressColor2, // Set the progress color based on battery level
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.01),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly, // Center the labels
                            children: [
                              Text(
                                'RAM',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.015,),
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.029),
                                child: Text(
                                  'Storage',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.015,),
                              Text(
                                'Battery',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.03, right: screenWidth * 0.08),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween, // Center the labels
                            children: [
                              AutoSizeText(
                                '$formattedFreeRam/$formattedTotalRam GB',
                                style: TextStyle(
                                  color: newLinesColor,
                                  fontSize: 6,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(right: screenWidth * 0.02),
                                child: AutoSizeText(
                                 "$formattedDiskFreeSpace/$formattedDiskTotalSpace GB",
                                  style: TextStyle(
                                    color: newLinesColor,
                                    fontSize: 6,
                                  ),
                                ),
                              ),
                              AutoSizeText(
                                '$batteryLevel/100',
                                style: TextStyle(
                                  color: newLinesColor,
                                  fontSize: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01,),
              Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      child: Card(
                        color: foreGround,
                        child: Column(
                          children: [
                            SizedBox(height: upMargin,),
                            _buildDeviceInfoRow(
                                'Manufactorer', _deviceData["manufacturer"] ?? "N/A"),
                            Padding(
                              padding: EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ), // Fetch the device name using the 'name' key
                            _buildDeviceInfoRow(
                                'Device Model', _deviceData['model'] ?? "N/A"),
                            Padding(
                              padding: EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ), // Fetch the device model using the 'model' key
                            _buildDeviceInfoRow(
                                'Android Api',
                                _deviceData['version.release'] ??
                                    "N/A"), // Fetch the OS version using the 'systemVersion' key
                            Padding(
                              padding: EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ),
                            _buildDeviceInfoRow(
                                'Screen Resolution',
                                '${_deviceData['displayWidthPixels']} x ${_deviceData['displayHeightPixels']}' ??
                                    "N/A"),
                            Padding(
                              padding: EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ),
                            _buildDeviceInfoRow(
                                'Screen Size',
                                '${(_deviceData['displayWidthInches'] ?? 0.0).toStringAsFixed(3)} x ${(_deviceData['displayHeightInches'] ?? 0.0).toStringAsFixed(3)} Inches'
                                    ??
                                    "N/A"),
                            Padding(
                              padding:  EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ),
        
                            _buildDeviceInfoRow(
                                'Screen Density',
                                '$density DPI' ??
                                    "N/A"),
                            Padding(
                              padding:  EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ),
                            _buildDeviceInfoRow(
                                'Product',
                                _deviceData['product'] ??
                                    "N/A"),
                            Padding(
                              padding: EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ),
                            _buildDeviceInfoRow(
                                'System Uptime',
                                _deviceData['host'] ??
                                    "N/A"),
                            Padding(
                              padding:  EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ),
                            _buildDeviceInfoRow(
                                'Security Patch',
                                _deviceData['version.securityPatch'] ??
                                    "N/A"),
                            Padding(
                              padding: EdgeInsets.all(screenWidth * 0.01),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Container(
                                  width: 1,
                                  height: 350, // Adjust the height
                                  color: linesColor,
                                ),
                              ),
                            ),
                            _buildDeviceInfoRow(
                                'Root Access',
                                _deviceData['isRooted'] ??
                                    "N/A"),
                            SizedBox(height: upMargin,)
        
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
