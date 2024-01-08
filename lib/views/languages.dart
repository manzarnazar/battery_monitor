import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/languages_model.dart';
import '../widgets/colors.dart';

class LanguagesScreen extends StatefulWidget {
  @override
  _LanguagesScreenState createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  late SharedPreferences _prefs;
  String searchString = '';
  late Language selectedLanguage = languages.isNotEmpty ? languages.first : Language(code: 'en', name: 'English', flagAsset: 'assets/flags/America.svg');


  @override
  void initState() {
    filteredLanguages = languages;
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      _loadSelectedLanguage(); // Load selected language
    });
    super.initState();
  }

  void _loadSelectedLanguage() {
    String? selectedLanguageCode = _prefs.getString('selectedLanguageCode');
    if (selectedLanguageCode != null) {
      setState(() {
        selectedLanguage = languages.firstWhere(
              (language) => language.code == selectedLanguageCode,
          orElse: () => languages.first, // Set default language if not found
        );
      });
    } else {
      setState(() {
        selectedLanguage = languages.first; // Set default language if not saved
      });
    }
    // Update isSelected flag for loaded selectedLanguage
    languages.forEach((language) {
      language.isSelected = language == selectedLanguage;
    });
  }

  void _setSelectedLanguage(Language language) {
    setState(() {
      selectedLanguage = language;
      _prefs.setString('selectedLanguageCode', language.code);
      // Update isSelected flag for all languages
      languages.forEach((lang) {
        lang.isSelected = lang == selectedLanguage;
      });
    });
  }

  List<Language> languages = [
    Language(code: 'en', name: 'English', flagAsset: 'assets/flags/America.svg'),
    Language(code: 'Ar', name: 'Arabic', flagAsset: 'assets/flags/Group 21118.svg'),
    Language(code: 'Ba', name: 'Bangali', flagAsset: 'assets/flags/Group 21140.svg'),
    Language(code: 'ch', name: 'Chinese', flagAsset: 'assets/flags/Group 21129.svg'),
    Language(code: 'Fr', name: 'France', flagAsset: 'assets/flags/Group 21122.svg'),
    Language(code: 'Ge', name: 'German', flagAsset: 'assets/flags/Group 21132.svg'),
    Language(code: 'hi', name: 'Hindi', flagAsset: 'assets/flags/Group 21119.svg'),
    Language(code: 'in', name: 'Indonesia', flagAsset: 'assets/flags/Group 21125.svg'),
    Language(code: 'ma', name: 'Malay', flagAsset: 'assets/flags/Group 21124.svg'),
    Language(code: 'du', name: 'Dutch', flagAsset: 'assets/flags/Group 21137.svg'),
    Language(code: 'ir', name: 'Irish', flagAsset: 'assets/flags/Group 21306.svg'),
    Language(code: 'it', name: 'Italian', flagAsset: 'assets/flags/Group 21305.svg'),
    Language(code: 'ja', name: 'Japanese', flagAsset: 'assets/flags/Group 21304.svg'),
    Language(code: 'ko', name: 'Korean', flagAsset: 'assets/flags/Group 21302.svg'),
    Language(code: 'pe', name: 'Persian', flagAsset: 'assets/flags/Group 21128.svg'),
    Language(code: 'po', name: 'Polish', flagAsset: 'assets/flags/Group 21126.svg'),
    Language(code: 'po', name: 'Portugese', flagAsset: 'assets/flags/Group 21131.svg'),
    Language(code: 'Ro', name: 'Romanian', flagAsset: 'assets/flags/Group 21134.svg'),
    Language(code: 'Ru', name: 'Russian', flagAsset: 'assets/flags/Group 21127.svg'),
    Language(code: 'Ta', name: 'Tamili', flagAsset: 'assets/flags/Group 21119.svg'),
    Language(code: 'th', name: 'Thai', flagAsset: 'assets/flags/Group 21133.svg'),
    Language(code: 'tu', name: 'Turkish', flagAsset: 'assets/flags/Group 21130.svg'),
    Language(code: 'ur', name: 'Urdu', flagAsset: 'assets/flags/Group 21123.svg'),
  ];


  List<Language> filteredLanguages = []; // Filtered languages based on search query

  void filterLanguages(String query) {
    setState(() {
      filteredLanguages = languages
          .where((language) =>
          language.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: foreGround,
        title: Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Text(
            'Choose the Language',
            style: TextStyle(color: textColor),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.only(right: 14.0),
              child: Icon(Icons.arrow_forward_sharp),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: foreGround,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchString = value.toLowerCase();
                            filterLanguages(searchString);
                          });
                        },
                        style: TextStyle(color: linesColor),
                        decoration: InputDecoration(
                          hintText: 'Search Language',
                          hintStyle: TextStyle(color: linesColor),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.search,
                      color: linesColor,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                top: screenHeight * 0.02,
              ),
              child: Text(
                'Selected Language',
                style: TextStyle(color: textColor),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Container(

                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: ListTile(
                  title: Text(
                    selectedLanguage.name,
                    style: TextStyle(color: textColor),
                  ),
                  leading: SvgPicture.asset(
                    selectedLanguage.flagAsset,
                    width: 25,
                    height: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                top: screenHeight * 0.02,
              ),
              child: Text(
                'All Languages',
                style: TextStyle(color: textColor),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredLanguages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _setSelectedLanguage(filteredLanguages[index]);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      child: Card(
                        color: filteredLanguages[index].isSelected
                            ? themeColor
                            : foreGround,
                        child: ListTile(
                          leading: SvgPicture.asset(
                            filteredLanguages[index].flagAsset,
                            width: 25,
                            height: 20,
                          ),
                          title: Text(
                            filteredLanguages[index].name,
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
