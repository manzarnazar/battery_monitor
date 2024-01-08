import 'dart:developer';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:battery_alarm/Model/ringtones_model.dart';
import 'package:battery_alarm/views/Ringtones/batteryalarm_provider.dart';
import 'package:battery_alarm/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class Ringtones extends StatefulWidget {
  const Ringtones({super.key});

  @override
  State<Ringtones> createState() => _RingtonesState();
}

class _RingtonesState extends State<Ringtones> {
  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  Future<void> playSound(String assetPath) async {
    try {
      await assetsAudioPlayer.open(
        Audio(assetPath),
      );
    } catch (e) {
      print('Error playing sound: $e');
    }
  }


  @override
  void dispose() {
    assetsAudioPlayer.stop(); // Stop the audio when the screen is disposed
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    BatteryAlarmprovider pro = Provider.of<BatteryAlarmprovider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: foreGround,
        title: Align(
          alignment: Alignment.topLeft,
          child: Text("Ringtones",
          style: TextStyle(
            color: textColor
            ),
          ),
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
        child: Container(
          margin: EdgeInsets.only(bottom: screenHeight * 0.05),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02,),
                    child: Text('Select your favourite ringtone',
                    style: TextStyle(
                      color: textColor
                    ),),
                  )),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  child: Card(
                    color: foreGround,
                    child: Center(
                      child: ListView.builder(
                        itemCount: ringtonesList.length,
                        itemBuilder: (BuildContext context, int index) {
                          String name = ringtonesList[index].name;
                          String path = ringtonesList[index].filePath;
                          log("name: $name");


                          bool isSelected = pro.selectedIndex == index;

                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  name,
                                  style: TextStyle(color: textColor,),
                                ),
                                onTap: () async {
                                  await playSound(path);
                                  pro.toggleCheckbox(index);
                                  pro.selectedRingtone(path);
                                },
                                trailing : Radio<String>(
                                  activeColor: themeColor, // Color when selected
                                  value: isSelected ? 'selected' : 'unselected', // Use isSelected to determine value
                                  groupValue: 'selected', // Set the same group value for all radio buttons
                                  onChanged: (value) {
                                    pro.toggleCheckbox(index);
                                    pro.selectedRingtone(path);
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Adjust tap target size
                                  // Use different colors or styles based on the 'value'
                                  fillColor: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                      if (isSelected) {
                                        return themeColor; // Selected color
                                      }
                                      return Colors.white; // Unselected color
                                    },
                                  ),
                                ),
                              ),
                              if (index != ringtonesList.length - 1) // Render the line if it's not the last ringtone
                                Padding(
                                  padding: const EdgeInsets.only(top: 0, left: 8.0, right: 8,bottom: 0),
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: Container(
                                      width: 1,
                                      height: 300,
                                      color: linesColor,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
