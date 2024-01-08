import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rate_my_app/src/core.dart';

import 'package:lottie/lottie.dart';
import '../widgets/animation_battery.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key,
    this.rateMyApp});

  final rateMyApp;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      // Navigate to the HomeScreen after the delay.
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(rateMyApp: widget.rateMyApp)));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topMargin = screenHeight * 0.02; // Margin from the top
    final leftMargin = screenWidth * 0.02; // Margin from the top
    final rightMargin = screenWidth * 0.02; // Margin from the right
    final downMargin = screenHeight * 0.08;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items at the bottom
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedMP4CircularProgressIndicator(),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Battery Alarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                  width: screenWidth * 0.4, // Set your desired width
                  height: screenHeight * 0.2,
                  child: Lottie.asset('assets/animation/Animation - 1701428153685.json')),
            ),
          ],
        ),
      ),
    );
  }
}
