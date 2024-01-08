import 'package:battery_alarm/main.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class AnimatedCircularProgressIndicator extends StatefulWidget {
  const AnimatedCircularProgressIndicator({Key? key}) : super(key: key);

  @override
  State<AnimatedCircularProgressIndicator> createState() =>
      _AnimatedCircularProgressIndicatorState();
}

class _AnimatedCircularProgressIndicatorState
    extends State<AnimatedCircularProgressIndicator> {
  late VideoPlayerController _controller;
  Battery battery = Battery();
  int batteryLevel = 0;
  late Timer _batteryUpdateTimer;
  bool isCharging = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/animation/Battery-Icon_3.mp4',
    );
    _controller.initialize().then((_) {
      _controller.setLooping(false);
      _controller.pause();
    });

    _getBatteryLevel();

    const updateInterval = Duration(seconds: 3);
    _batteryUpdateTimer = Timer.periodic(updateInterval, (_) {
      _getBatteryLevel();
    });
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _controller.dispose();
    _batteryUpdateTimer.cancel();
    super.dispose();
  }

  StreamSubscription<BatteryState>? _batteryStateSubscription;

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

  Future<void> _getBatteryLevel() async {
    int batteryStatus = await battery.batteryLevel;
    _initBatteryChargingState();
    setState(() {
      batteryLevel = batteryStatus;
      if (!isCharging) {
        //_controller.play(); // Play the video when not charging
        _controller.seekTo(
          Duration(
            seconds: batteryLevel * _controller.value.duration.inSeconds ~/ 100,
          ),
        );
      } else {
        _controller.play(); // Pause the video when charging
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: screenSize.width * 0.3,
            height: screenSize.width * 0.3,
            child: WillPopScope(
              onWillPop: () async => false,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isCharging)
                    VideoPlayer(_controller),
                    Visibility(
                    visible: isCharging == true,
                    child: Stack(
                      children: [
                        VideoPlayer(_controller),
                        Center(child: SvgPicture.asset('assets/icons/Vector 12.svg')),
                      ],
                    )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
