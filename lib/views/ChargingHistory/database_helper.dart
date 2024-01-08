import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ChargingRecord {
  final int id; // Unique identifier
  final int chargingDuration; // Duration in seconds
  final int fullChargeDuration; // Duration in seconds
  final int overchargedDuration; // Duration in seconds
  final String chargerType;
  final int chargeQuantity;

  ChargingRecord({
    required this.id,
    required this.chargingDuration,
    required this.fullChargeDuration,
    required this.overchargedDuration,
    required this.chargerType,
    required this.chargeQuantity,
  });

  // Add a toMap method to convert the object to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chargingDuration': chargingDuration,
      'fullChargeDuration': fullChargeDuration,
      'overchargedDuration': overchargedDuration,
      'chargerType': chargerType,
      'chargeQuantity': chargeQuantity,
    };
  }
}

class DatabaseHelper {
  late Database _database;

  DatabaseHelper() {
    initializeDatabase();
  }

  Future<void> initializeDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    final path = join(await getDatabasesPath(), 'charging_history.db');
    _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
        'CREATE TABLE charging_history(id INTEGER PRIMARY KEY, '
        'chargingDuration INTEGER, fullChargeDuration INTEGER, '
        'overchargedDuration INTEGER, chargerType TEXT, chargeQuantity INTEGER)',
      );
    });
  }

  Future<void> saveChargingRecord(ChargingRecord record) async {
    print("Saving charging record: $record");
    await _database.insert('charging_history', record.toMap());
    print("Charging record saved.");
  }

  Future<ChargingRecord> getChargingRecord(int id) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'charging_history',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ChargingRecord(
        id: maps[0]['id'],
        chargingDuration: maps[0]['chargingDuration'],
        fullChargeDuration: maps[0]['fullChargeDuration'],
        overchargedDuration: maps[0]['overchargedDuration'],
        chargerType: maps[0]['chargerType'],
        chargeQuantity: maps[0]['chargeQuantity'],
      );
    } else {
      // Return a default ChargingRecord or handle the case when the record doesn't exist.
      return ChargingRecord(
        id: -1, // Use a unique ID to indicate no record found
        chargingDuration: 0,
        fullChargeDuration: 0,
        overchargedDuration: 0,
        chargerType: 'Unknown',
        chargeQuantity: 0,
      );
    }
  }

  Future<List<ChargingRecord>> fetchAllChargingRecords() async {
    final List<Map<String, dynamic>> maps =
        await _database.query('charging_history');
    return List.generate(maps.length, (index) {
      return ChargingRecord(
        id: maps[index]['id'],
        chargingDuration: maps[index]['chargingDuration'],
        fullChargeDuration: maps[index]['fullChargeDuration'],
        overchargedDuration: maps[index]['overchargedDuration'],
        chargerType: maps[index]['chargerType'],
        chargeQuantity: maps[index]['chargeQuantity'],
      );
    });
  }
}

class DatabaseHelperChargingHistory {
  static final DatabaseHelperChargingHistory instance =
      DatabaseHelperChargingHistory._privateConstructor();
  static Database? _database;

  DatabaseHelperChargingHistory._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'battery_history.db');

    return await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          '''
         CREATE TABLE battery_history (
            id INTEGER PRIMARY KEY,
            status TEXT,
            percentage INTEGER,
            plugInPercentage INTEGER,
            plugOutPercentage INTEGER,
            totalPercentage INTEGER,
            chargeTime INTEGER,
            timestamp TEXT,
            plugInTimestamp TEXT,
            plugOutTimestamp TEXT
          )
          ''',
        );
      },
      version: 4,
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('battery_history');
  }
}
