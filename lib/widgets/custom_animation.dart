import 'package:battery_alarm/widgets/colors.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:animated_battery_gauge/animated_battery_gauge.dart';

class BatteryGaugeDemo extends StatefulWidget {
  final bool isHorizontal;
  final bool isGrid;
  const BatteryGaugeDemo(
      {Key? key, required this.isHorizontal, required this.isGrid})
      : super(key: key);

  @override
  State<BatteryGaugeDemo> createState() => _BatteryGaugeDemoState();
}

class _BatteryGaugeDemoState extends State<BatteryGaugeDemo> {
  Battery battery = Battery();
  int batteryLevel = 0;

@override
 void initState() {
  _getBatteryLevel();
   super.initState();
}

  Future<void> _getBatteryLevel() async {
    int batteryStatus = await battery.batteryLevel;
    setState(() {
      batteryLevel = batteryStatus;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (widget.isGrid) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: CupertinoPageScaffold(
            child: Center(
              child: AnimatedBatteryGauge(
                duration: Duration(seconds: 5),
                value: batteryLevel.toDouble(),
                size: (widget.isHorizontal) ? Size(150, 50) : Size(50, 100),
                borderColor: linesColor,
                valueColor: (widget.isHorizontal)
                    ? animation
                    : animation
              ),
            )),
      );
    } else {
      return CupertinoPageScaffold(
        child: Center(
          child: AnimatedBatteryGauge(
            duration: Duration(seconds: 2),
            value: (widget.isHorizontal) ? 60 : 42,
            size: (widget.isHorizontal) ? Size(120, 50) : Size(50, 120),
            borderColor: linesColor,
            valueColor: (widget.isHorizontal)
                ? animation
                : animation,
          ),
        ),
      );
    }
  }
}