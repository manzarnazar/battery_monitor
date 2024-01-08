import 'package:battery_alarm/widgets/colors.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';// Import the FlareActor
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';


class AnimatedMP4CircularProgressIndicator extends StatefulWidget {
  String? screen;
  AnimatedMP4CircularProgressIndicator({super.key,this.screen});

  @override
  _AnimatedMP4CircularProgressIndicatorState createState() =>
      _AnimatedMP4CircularProgressIndicatorState();
}

class _AnimatedMP4CircularProgressIndicatorState
    extends State<AnimatedMP4CircularProgressIndicator> {
  late VideoPlayerController _controller;
  Battery battery = Battery();
  int batteryLevel = 0;
  // late Timer _batteryUpdateTimer;

  @override
  void initState() {
    super.initState();
    try {
      _controller = VideoPlayerController.asset(
        'assets/animation/Battery-Icon_3.mp4',
      );
      _controller.addListener(() {
        // setState(() {});
      });
      // Initialize the controller and start playing
      _controller.initialize().then((_) {
        if (mounted) {
          // setState(() {});
          _controller.setLooping(true);
          _controller.play();
        }
      });
    } catch (e) {
      print('Error initializing VideoPlayerController: $e');
    }



    _getBatteryLevel();

  }

  @override
  void dispose() {
    _controller.dispose();
    // _batteryUpdateTimer.cancel();
    super.dispose();
  }

  Future<void> _getBatteryLevel() async {
    int batteryStatus = await battery.batteryLevel;
    setState(() {
      batteryLevel = batteryStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // double batteryPercentage = batteryLevel / 100.0;
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width:   widget.screen == 'home'  ? screenSize.width * 0.3 : screenSize.width * 0.5, // Adjust the width using the screen size
            height: widget.screen == 'home'  ? screenSize.width * 0.3 : screenSize.width * 0.5,
            child: WillPopScope(
              onWillPop: () async {
                return false; // Prevent going back to the previous screen
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  SvgPicture.asset('assets/icons/Group 21650.svg'),
                  // widget.screen == 'home' ? const SizedBox(): Text(
                  //   "$batteryLevel%",
                  //   style: TextStyle(
                  //     color: textColor,
                  //     fontSize: 24.0,
                  //     fontWeight: FontWeight.bold,
                  //     decoration: TextDecoration.none,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
