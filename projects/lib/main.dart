import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'TextRecognition.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import 'welcome.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'settings.dart';
import 'profile.dart';
import 'tutorial.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await requestPermissions();
  await dotenv.load();
  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  var status = await Permission.microphone.request();
  if (status.isDenied) {
    // If denied, request again
    await Permission.microphone.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/signin': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/home': (context) => MainPage(),
        '/text': (context) => TextScreen(),
        '/settings': (context) => SettingsScreen(),
        '/profile': (context) => ProfilePage(), 
        '/tutorial': (context) => TutorialScreen(),
      },
    );
  }
}
