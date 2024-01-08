import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'database_helper.dart';

class ChargingHistoryProvider extends ChangeNotifier {
  List<BatteryHistory> _history = [];

  List<BatteryHistory> get history => _history;

// Load Cahrging History From Database...The entry comes from Main.dart My App Class Widget
// and store it in _history List which is used in BatteryHistoryScreen

  Future<void> loadHistory() async {
    print('provider');
    final db = await DatabaseHelperChargingHistory.instance.database;
    final history = await db.query(
      'battery_history',
      orderBy: 'id DESC',
      limit: 1,
    );

    _history = history.map((entry) {
      Duration chargeTime = Duration(seconds: entry['chargeTime'] as int);
      return BatteryHistory(
        chargeTime: chargeTime,
        percentage: entry['percentage'] as int,
        totalPercentage: entry["totalPercentage"] as int,
        plugInPercentage: entry["plugInPercentage"] as int,
        plugOutPercentage: entry['plugOutPercentage'] as int,
        plugInTimestamp: DateTime.parse(entry["plugInTimestamp"] as String),
        plugOutTimestamp: DateTime.parse(entry["plugOutTimestamp"] as String),
        id: entry['id'] as int,
        status: entry['status'] as String,
        timestamp: DateTime.parse(entry['timestamp'] as String),
      );
    }).toList();

    notifyListeners();
  }

// Add History Entry To Database...The entry comes from Main.dart My App Class Widget
  Future<void> addHistoryEntry(BatteryHistory entry) async {
    final db = await DatabaseHelperChargingHistory.instance.database;
    final id = await db.insert('battery_history', entry.toMap());

    entry.id = id;
    _history.add(entry);
    notifyListeners();
  }
}

//Battery History Model To Store Data In Sqflie  Database

class BatteryHistory {
  int? id;
  final String status;
  final int percentage;
  final int plugInPercentage;
  final int plugOutPercentage;
  final int totalPercentage;
  final DateTime timestamp;
  DateTime? plugInTimestamp;
  DateTime? plugOutTimestamp;
  final Duration? chargeTime;

  BatteryHistory({
    this.id,
    required this.status,
    required this.percentage,
    required this.timestamp,
    this.chargeTime,
    this.plugInTimestamp,
    this.plugOutTimestamp,
    this.plugInPercentage = 0,
    this.plugOutPercentage = 0,
    this.totalPercentage = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'percentage': percentage,
      'plugInPercentage': plugInPercentage,
      'plugOutPercentage': plugOutPercentage,
      'totalPercentage': totalPercentage,
      'timestamp': timestamp.toIso8601String(),
      'plugInTimestamp': plugInTimestamp?.toIso8601String(),
      'plugOutTimestamp': plugOutTimestamp?.toIso8601String(),
      'chargeTime': chargeTime!.inSeconds,
    };
  }
}
Future<bool> isBackgroundServiceRunning() async {
  final service = FlutterBackgroundService();
  // Check the status of the service and return accordingly
  // This is a dummy example; replace with actual check
  return  service.isRunning();
}
