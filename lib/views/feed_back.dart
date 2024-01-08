import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/colors.dart';

class FeedbackForm extends StatefulWidget {
  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = ''; // Initialize with an empty category
  List<String> _selectedCategories = [];
  // Function to submit feedback to Firebase
  Future<void> _submitFeedback() async {
    try {
      if (_selectedCategories.isEmpty) {
        return;
      }
      // Get a reference to the Firestore collection
      CollectionReference feedbackCollection =
      FirebaseFirestore.instance.collection('feedback');

      // Add the feedback to Firestore
      await feedbackCollection.add({
        'categories': _selectedCategories,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the message field after submission
      _messageController.clear();
      // Optionally, show a success message or navigate to a new screen
      print('Feedback submitted successfully!');
    } catch (e) {
      // Handle errors if any
      print('Error submitting feedback: $e');
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category); // Remove category if already selected
      } else {
        _selectedCategories.add(category); // Add category if not selected
      }
    });
  }


  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: foreGround,
        title: Text('Feedback',
          style: TextStyle(color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.02,),
                child: Text(
                  'Which type of problem you are facing?',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenWidth * 0.0125),
              Wrap(
                spacing: screenWidth * 0.001,
                runSpacing: screenHeight * 0.001,
                children: [
                  CategoryCard(
                    categoryText: 'Crash',
                    onTap: () {
                      _toggleCategory('Crash');
                    },
                    isSelected: _selectedCategories.contains('Crash') ,
                  ),
                  CategoryCard(
                    categoryText: 'Suggestion',
                    onTap: () {
                      _toggleCategory('Suggestion');
                    },
                    isSelected: _selectedCategories.contains('Suggestion'),
                  ),
                  CategoryCard(
                    categoryText: 'Ads',
                    onTap: () {
                      _toggleCategory('Ads');
                    },
                    isSelected: _selectedCategories.contains('Ads'),
                  ),
                  CategoryCard(
                    categoryText: 'Others',
                    onTap: () {
                      _toggleCategory('Others');
                    },
                    isSelected: _selectedCategories.contains('Others'),
                  ),
                  CategoryCard(
                    categoryText: 'App not responding',
                    onTap: () {
                      _toggleCategory('App not responding');
                    },
                    isSelected: _selectedCategories.contains('App not responding'),
                  ),
                  CategoryCard(
                    categoryText: 'Function Disabled',
                    onTap: () {
                      _toggleCategory('Function Disabled');
                    },
                    isSelected: _selectedCategories.contains('Function Disabled'),
                  ),
                  CategoryCard(
                    categoryText: 'Do not know how to use',
                    onTap: () {
                      _toggleCategory('Do not know how to use');
                    },
                    isSelected: _selectedCategories.contains('Do not know how to use'),
                  ),
                  CategoryCard(
                    categoryText: 'Premium not Working',
                    onTap: () {
                      _toggleCategory('Premium not Working');
                    },
                    isSelected: _selectedCategories.contains('Premium not Working'),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.02, ),
                child: Text('Details',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: screenHeight * 0.02, left: screenHeight * 0.02,),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  style: TextStyle(color: Colors.white), // Setting text color
                  decoration: InputDecoration(
                    hintText: 'Share Your Thoughts',
                    hintStyle: TextStyle(color: linesColor), // Setting hint text color
                    filled: true,
                    fillColor: foreGround, // Setting textbox color
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: foreGround), // Setting border color
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenWidth * 0.0135),
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.02,),
                child: ElevatedButton(
                  onPressed: _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    primary: themeColor, // Setting button color
                    minimumSize: Size(double.infinity, 50), // Making button block-style
                  ),
                  child: Text('Submit', style: TextStyle(color: textColor)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String categoryText;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryCard({
    required this.categoryText,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected ? themeColor : foreGround,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            categoryText,
            style: TextStyle(
              color: isSelected ? textColor : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
