import 'package:battery_alarm/views/controller/home_controller.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenVibrationType extends StatefulWidget {
  @override
  State<ScreenVibrationType> createState() => _ScreenVibrationTypeState();
}

class _ScreenVibrationTypeState extends State<ScreenVibrationType> {
  final HomeController controller = Get.put(HomeController());
@override
  void initState() {
  getVibrationValue();
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: foreGround,
        title: Text(
          'Vibration',
          style: TextStyle(color: textColor),
        ),
        actions: [
          GestureDetector(
            onTap: (){
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.only(right: 14.0),
              child: SvgPicture.asset('assets/icons/done.svg'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05,),
        child: Column(
          children: [
            Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02,),
                  child: Text('Select Type',
                    style: TextStyle(
                        color: textColor
                    ),),
                )),
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              child: Card(
                color: foreGround,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenWidth * 0.02),
                    buildRadio("small", "Short time"),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Container(
                          width: 1,
                          height: 300,
                          color: linesColor,
                        ),
                      ),
                    ),
                    buildRadio("medium", "Medium"),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Container(
                          width: 1,
                          height: 300,
                          color: linesColor,
                        ),
                      ),
                    ),
                    buildRadio("large", "Long time"),
                  ],
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  void vibrationValue(String newValue)async{
   final prefs = await SharedPreferences.getInstance();
   prefs.setString("selctedVibrate", newValue);
  }
  void getVibrationValue()async{
    final prefs = await SharedPreferences.getInstance();
    controller.selctedVibrate.value = prefs.getString("selctedVibrate")?? "medium";

  }

  Widget buildRadio(String value, String label) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,style: TextStyle(color: textColor),),
        Obx(() {
          return Radio(
            value: value,
            groupValue: controller.selctedVibrate.value,
            activeColor: Colors.red,
            onChanged: (value) {
              vibrationValue(value!);
              controller.selctedVibrate.value = value!;
              setState(() {

              });

            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // To reduce tap target size
            visualDensity: VisualDensity.compact, // To reduce the overall size
            // Set the unselected color (background color when not selected)
            fillColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.red; // Selected color
                }
                return Colors.white; // Unselected color
              },
            ),
          );
        }),
      ],
    ).paddingOnly(top: screenHeight * 0.01 ,bottom: screenHeight * 0.01,
    left: screenWidth * 0.05, right: screenWidth * 0.04);
  }
}
