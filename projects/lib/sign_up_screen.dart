import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ValueNotifier<bool> isPasswordVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isConfirmPasswordVisible = ValueNotifier<bool>(false);

  final AuthService _auth = AuthService();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    isPasswordVisible.dispose();
    isConfirmPasswordVisible.dispose();
    super.dispose();
  }

  void _validateAndSignUp() async {
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text("Invalid form")));
    return;
  }

  final email = emailController.text.trim();
  final username = usernameController.text.trim();
  final password = passwordController.text.trim();

  bool created = await _auth.signUp(email, username,password);
  if (created) {
    // After sign-up, auto-sign-in so Flask session is created
    bool signedIn = await _auth.signIn(email, password);
    if (signedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-up succeeded but login failed.")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sign-up failed.")),
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
                  Image.asset(
                    'assets/images/SEP_Logo.png', // Replace this path with your image
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Create your account",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  buildInputField("Username", usernameController, Icons.person),
                  const SizedBox(height: 15),
                  buildInputField("Email", emailController, Icons.email, isEmail: true),
                  const SizedBox(height: 15),
                  buildPasswordField("Password", passwordController, isPasswordVisible),
                  const SizedBox(height: 15),
                  buildPasswordField("Confirm Password", confirmPasswordController, isConfirmPasswordVisible, isConfirm: true),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _validateAndSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?", style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signin');
                        },
                        child: const Text("Sign In", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller, IconData icon, {bool isEmail = false}) {
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label is required";
        }
        if (isEmail && !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(value)) {
          return "Enter a valid email";
        }
        return null;
      },
    );
  }

  Widget buildPasswordField(String label, TextEditingController controller, ValueNotifier<bool> visibilityNotifier, {bool isConfirm = false}) {
    return ValueListenableBuilder(
      valueListenable: visibilityNotifier,
      builder: (context, value, child) {
        return TextFormField(
          controller: controller,
          obscureText: !value,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.yellow),
            prefixIcon: const Icon(Icons.lock, color: Colors.yellow),
            suffixIcon: IconButton(
              icon: Icon(value ? Icons.visibility : Icons.visibility_off, color: Colors.white),
              onPressed: () {
                visibilityNotifier.value = !visibilityNotifier.value;
              },
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "$label is required";
            }
            if (!isConfirm && value.length < 6) {
              return "Password must be at least 6 characters";
            }
            if (isConfirm && value != passwordController.text) {
              return "Passwords do not match";
            }
            return null;
          },
        );
      },
    );
  }
}
