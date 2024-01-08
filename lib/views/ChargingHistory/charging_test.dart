import 'package:battery_alarm/views/ChargingHistory/charging_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChargingHistoryScreen extends StatefulWidget {
  const ChargingHistoryScreen({super.key});

  @override
  _ChargingHistoryScreenState createState() => _ChargingHistoryScreenState();
}

class _ChargingHistoryScreenState extends State<ChargingHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ChargingHistoryProvider>(
        builder: (context, historyProvider, child) {
          final history = historyProvider.history;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return ListTile(
                title: Text('Battery Status: ${entry.status}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Battery Percentage: ${entry.percentage}%'),
                    Text('Plug-in Percentage: ${entry.plugInPercentage}%'),
                    Text('Plug-out Percentage: ${entry.plugOutPercentage}%'),
                    Text('Total Percentage: ${entry.totalPercentage}%'),
                    Text('Timestamp: ${entry.timestamp}'),
                    Text('Plug-in Time: ${entry.plugInTimestamp}'),
                    Text('Plug-out Time: ${entry.plugOutTimestamp}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
