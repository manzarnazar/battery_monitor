import 'package:battery_alarm/views/ChargingHistory/charging_history_provider.dart';
import 'package:battery_alarm/views/battery_monitor.dart';
import 'package:battery_alarm/views/controller/home_controller.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryHistoryScreen extends StatefulWidget {
  const BatteryHistoryScreen({
    super.key,
  });

  @override
  State<BatteryHistoryScreen> createState() => _BatteryHistoryScreenState();
}

class _BatteryHistoryScreenState extends State<BatteryHistoryScreen> {
  late BatteryMonitor _batteryMonitor;
  late SharedPreferences prefs;
  var controller = Get.put(HomeController());
  @override
  void initState() {
    var provider = Provider.of<ChargingHistoryProvider>(context, listen: false);
    alarmSetting();
    provider.loadHistory();
    super.initState();
  }

  void alarmSetting() async {
    prefs = await SharedPreferences.getInstance();
    _batteryMonitor = BatteryMonitor(
      isNotificationShown: false,
      isLowBatteryNotificationShown: false,
      currentValue: controller.currentValue.value,
      currentLowValue: prefs.getDouble('currentLowValue') ?? 20.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ChargingHistoryProvider>(
        builder: (context, pro, child) {
          final history = pro.history;
          return history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/icons/charge 1.svg'),
                      KText(
                        text: "There is no charging history yet!",
                        fontSize: 16.sp,
                        color: textColor,
                      ),
                    ],
                  ),
                )
              : Obx(() {
                  return controller.charging.value == true
                      ? ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = history[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                left: 16,
                                right: 16,
                              ),
                              child: Container(
                                height: 188.h,
                                width: 312.w,
                                padding: EdgeInsets.symmetric(
                                    vertical: 16.h, horizontal: 10.w),
                                decoration: BoxDecoration(
                                  color: foreGround,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    TextRow(
                                      text1: entry.chargeTime != null
                                          ? formatChargeTime(entry.chargeTime!)
                                          : "",
                                      text1Color: linesColor,
                                      text2: "+${entry.totalPercentage}%",
                                      text2Color: textColor,
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      height: 5.w,
                                      width: 312.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: const [
                                            Color(0xffF74A5E), // First color
                                            Color(0xffF74A5E), // First color
                                            Color(0xff727477), // Second color
                                            Color(0xff727477), // Second color
                                          ],
                                          stops: [
                                            0.0,
                                            // First color start
                                            entry.percentage / 100,
                                            // First color end (dynamic based on _totalPercentage)
                                            entry.percentage / 100,
                                            // Second color start (dynamic based on _totalPercentage)
                                            1.0,
                                            // Second color end
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    TextRow(
                                      text1: "${entry.plugInPercentage}%",
                                      fontSize1: 16.sp,
                                      text1Color: textColor,
                                      text2: "${entry.percentage}%",
                                      text2Color: textColor,
                                    ),
                                    SizedBox(height: 18.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconTextRow(
                                          text: "Plug in",
                                          icon: "assets/icons/Plug_in.png",
                                          iconsColor: animation,
                                          iconSize: 18.sp,
                                        ),
                                        IconTextRow(
                                          text: "Plug out",
                                          icon: "assets/icons/plug_out.png",
                                          iconsColor: themeColor,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 14.h),
                                    TextRow(
                                      text1: entry.plugInTimestamp != null
                                          ? DateFormat("HH:mm:ss | dd MMM yyyy")
                                              .format(entry.plugInTimestamp!)
                                          : "10%",
                                      fontSize1: 12.sp,
                                      text2: entry.plugOutTimestamp != null
                                          ? DateFormat("HH:mm:ss | dd MMM yyyy")
                                              .format(entry.plugOutTimestamp!)
                                          : "100%",
                                      fontSize2: 12.sp,
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            "Update Charging setting",
                            style: TextStyle(color: textColor),
                          ),
                        );
                });
        },
      ),
    );
  }
}

String formatChargeTime(Duration chargeTime) {
  if (chargeTime.inSeconds < 60) {
    // Display in seconds if it's less than a minute
    return 'Charged for ${chargeTime.inSeconds} seconds';
  } else {
    // Display in minutes if it's one minute or more
    return 'Charged for ${chargeTime.inMinutes} minutes';
  }
}

class TextRow extends StatelessWidget {
  const TextRow({
    super.key,
    required this.text1,
    required this.text2,
    this.text1Color,
    this.text2Color,
    this.fontSize1,
    this.fontSize2,
  });

  final String text1;
  final String text2;
  final Color? text1Color;
  final Color? text2Color;
  final double? fontSize1;
  final double? fontSize2;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        KText(
          text: text1,
          color: text1Color ?? const Color(0xff6D6D6D),
          fontSize: fontSize1 ?? 14.sp,
        ),
        KText(
          text: text2,
          fontSize: fontSize2 ?? 16.sp,
          color: text2Color ?? const Color(0xff6D6D6D),
        )
      ],
    );
  }
}

class IconTextRow extends StatelessWidget {
  const IconTextRow({
    super.key,
    required this.text,
    required this.icon,
    required this.iconsColor,
    this.iconSize,
  });

  final String text;
  final String icon;
  final Color iconsColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          icon,
          height: iconSize ?? 24.h,
          width: iconSize ?? 24.w,
          color: iconsColor,
        ),
        SizedBox(
          width: 4.w,
        ),
        KText(
          text: text,
          fontSize: 16.sp,
          color: textColor,
        )
      ],
    );
  }
}

class KText extends StatelessWidget {
  const KText(
      {super.key, this.fontSize, this.fontWeight, this.color, this.text});

  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "",
      style: GoogleFonts.inter(
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? textColor,
      ),
    );
  }
}
