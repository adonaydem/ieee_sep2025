import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<bool> isPasswordVisible = ValueNotifier<bool>(false);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final AuthService _auth = AuthService();
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceCommand = "";
  String _activeField = "username";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    isPasswordVisible.dispose();
    super.dispose();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech Status: $status"),
      onError: (error) => print("Speech Error: $error"),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _voiceCommand = result.recognizedWords;
        });
        _handleSpeechInput(_voiceCommand);
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleSpeechInput(String command) {
    command = command.toLowerCase();

    if (command.contains("sign in")) {
      _validateAndSignIn();
      return;
    }

    setState(() {
      if (_activeField == "username") {
        usernameController.text = command;
      } else if (_activeField == "password") {
        passwordController.text = command;
      }
    });
  }

  void _validateAndSignIn() async {
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text("Invalid form")));
    return;
  }

  final email = usernameController.text.trim();
  final password = passwordController.text.trim();

  // Call AuthService
  bool success = await _auth.signIn(email, password);
  if (success) {
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sign-in failed. Check credentials.")),
    );
  }
}


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xdd04003d),
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replace logo with image
                  Image.asset(
                    'assets/images/SEP_Logo.png',
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffffeb3b),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildInputField("Username", usernameController, Icons.person, "username"),
                  const SizedBox(height: 15),
                  buildPasswordField(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _validateAndSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.yellow, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: FloatingActionButton(
                      onPressed: _isListening ? _stopListening : _startListening,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 40,
                      ),
                      backgroundColor: Colors.blue,
                      elevation: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller, IconData icon, String field) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.yellow),
        prefixIcon: Icon(icon, color: Colors.yellow),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.yellow),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) =>
      value == null || value.isEmpty ? "$label is required" : null,
      onTap: () {
        setState(() {
          _activeField = field;
        });
      },
    );
  }

  Widget buildPasswordField() {
    return ValueListenableBuilder(
      valueListenable: isPasswordVisible,
      builder: (context, value, child) {
        return TextFormField(
          controller: passwordController,
          obscureText: !value,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: const TextStyle(color: Colors.yellow),
            prefixIcon: const Icon(Icons.vpn_key, color: Colors.yellow),
            suffixIcon: IconButton(
              icon: Icon(
                value ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: () => isPasswordVisible.value = !isPasswordVisible.value,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.yellow),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? "Password is required"
              : (value.length < 6
              ? "Password must be at least 6 characters"
              : null),
          onTap: () {
            setState(() {
              _activeField = "password";
            });
          },
        );
      },
    );
  }
}
