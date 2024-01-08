// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:battery_alarm/views/ChargingHistory/charging_history_provider.dart';
import 'package:battery_alarm/views/ChargingHistory/database_helper.dart';
import 'package:battery_alarm/views/ChargingHistory/notifi_service.dart';
import 'package:battery_alarm/views/Ringtones/batteryalarm_provider.dart';
import 'package:battery_alarm/views/battery_alarm.dart';
import 'package:battery_alarm/views/battery_monitor.dart';
import 'package:battery_alarm/views/controller/home_controller.dart';
import 'package:battery_alarm/views/settings.dart';
import 'package:battery_alarm/views/splash_screen.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:battery_alarm/widgets/rate_app_init.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'views/settings_provider.dart';

bool isCharging = false;

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    //BatteryAlarm.monitorBatteryLevel();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeService();
  Workmanager().initialize(callbackDispatcher);
  NotificationService().initNotification();
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  AwesomeNotifications().initialize(
    null, // Replace with your notification channel ID
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: backGround,
        ledColor: Colors.white,
      ),
    ],
  );

  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
    playSound: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(defaultPresentSound: false),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  // service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final Battery battery = Battery();
  BatteryState lastState = BatteryState.unknown;
  int lastPercentage = 0;
  DateTime? plugInTime;
  int plugInPercentage = 0;
  int totalPercentage = 0;

  DateTime chargeStartTime = DateTime.now();

  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  BatteryMonitor _batteryMonitor;
  var controller = Get.put(HomeController());
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Timer.periodic(const Duration(seconds: 1), (timer) async {
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
        } else if (state == BatteryState.discharging && plugInTime != null) {
          final plugOutTime = timestamp;
          final plugOutPercentage = batteryLevel;
          final chargeTime = plugOutTime.difference(chargeStartTime);

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
          final db = await DatabaseHelperChargingHistory.instance.database;
          await db.insert('battery_history', historyEntry.toMap());

          plugInTime = null;
        }
      } else if (state == BatteryState.charging) {
        totalPercentage += batteryLevel - lastPercentage;
      }

      lastPercentage = batteryLevel;
    });
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equal to AndroidConfiguration when you call the configure() method.
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
        // print("lets see ${controller.currentLowValue.value}");
        BatteryMonitor(
          isNotificationShown: false,
          isLowBatteryNotificationShown: false,
          currentValue: 90.0,
          currentLowValue: prefs.getDouble('currentLowValue') ?? 20.0,
        ).monitorBatteryLevel();
        service.setForegroundNotificationInfo(
          title: "App Status Running",
          // content: "Timer: ${DateTime.now()}",
          content:
              "Timer: ${DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.now())}",
        );
      }
    }

    // test using external plugin
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                  create: (_) => ChargingHistoryProvider()..loadHistory()),
              ChangeNotifierProvider(create: (_) => BatteryAlarmprovider()),
            ],
            child: GetMaterialApp(
                debugShowCheckedModeBanner: false,
                home: RateAppInitWidget(
                  builder: (rateMyApp) => SplashScreen(rateMyApp: rateMyApp),
                ),
                color: themeColor,
                theme: ThemeData(
                    fontFamily: 'Inter', scaffoldBackgroundColor: backGround)),
          );
        },
      ),
    );
  }
}
