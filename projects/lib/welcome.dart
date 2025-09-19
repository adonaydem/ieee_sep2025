import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xdd04003d),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            Image.asset(
              'assets/images/SEP_Logo.png',
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),

            // "Get Started" Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3d75d7),
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Sign In | Sign Up Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/signin');
                  },
                  child: const Text(
                    "Sign In",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text(
                  "  |  ",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 2), // More space at the bottom to move everything a bit up
          ],
        ),
      ),
    );
  }
}
