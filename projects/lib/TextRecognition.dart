import 'package:flutter/material.dart';

class TextScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xdd04003d),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 25,
                child: Icon(Icons.person, size: 30, color: Colors.black),
              ),
            ),

            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "VisionAid",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                height: 350, // Match the MainPage height
                width: double.infinity, // Take full width
                decoration: BoxDecoration(
                  color: const Color(
                      0xFF0F3460),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Positioned(
              bottom: 50,
              right: 50,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red, // Red color
                    borderRadius: BorderRadius.circular(60),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "back",
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
