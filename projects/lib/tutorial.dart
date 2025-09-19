import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, String>> sections = const [
    {
      "title": "🔐 1. Sign Up",
      "desc": "Choose 'Sign Up' on the home screen. You’ll need to create a secure account to unlock all features of the app.",
      "image": "assets/images/signup.png",
    },
    {
      "title": "📝 2. Fill in Your Details",
      "desc": "Enter a valid email address, create a password with at least 6 characters, and make sure both password fields match.",
      "image": "assets/images/form.png",
    },
    {
      "title": "🔍 3. Real-Time Object & Hazard Detection",
      "desc": "The app uses your camera to detect objects and potential hazards live. You’ll hear alerts for things like people, vehicles, or obstacles around you.",
      "image": "assets/images/object_detection.png",
    },
    {
      "title": "📝 4. Text Recognition",
      "desc": "Point the camera at printed text like signs or menus. The app will read the content aloud in your selected language.",
      "image": "assets/images/text_recognition.png",
    },
    {
      "title": "🌄 5. Scene Description",
      "desc": "Receive a spoken summary of your surroundings—perfect for quickly understanding your environment without focusing on specific objects.",
      "image": "assets/images/scene_description.png",
    },
    {
      "title": "💬 6. Voice Messaging",
      "desc": "Send and receive voice messages. You can also attach media or share your location through this screen.",
      "image": "assets/images/voice_messaging.png",
    },
    {
      "title": "🚨 7. Emergency Access",
      "desc": "Use the Emergency button to instantly alert a trusted contact. Your live location and a help message will be sent automatically.",
      "image": "assets/images/emergency.png",
    },
    {
      "title": "⚙️ 8. Settings",
      "desc": "Customize the app to suit your needs—adjust voice speed, detection preferences, recognition languages, and more.",
      "image": "assets/images/settings.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _playIntroAudio();
  }

  Future<void> _playIntroAudio() async {
    await _audioPlayer.play(AssetSource('audio/tutorial_intro.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff04003d),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F3460),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'User Manual',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.yellow,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.yellow,
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSection(
              section['title']!,
              section['desc']!,
              section['image']!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String content, String imagePath) {
    return Center(
      child: Card(
        color: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(imagePath),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
