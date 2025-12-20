import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../widgets/neon_widgets.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isEmail(String input) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(input);
  }

  bool _isPhone(String input) {
    return RegExp(r"^01[0-9]{9}$").hasMatch(input);
  }

  Future<String?> _findEmailByIdentifier(String field, String value) async {
    try {
      final result = await _db
          .collection("users")
          .where(field, isEqualTo: value)
          .get();

      if (result.docs.isNotEmpty) {
        return result.docs.first.get("email") as String?;
      } else {
        String errorMsg = field == "username"
            ? "Username not found"
            : "Phone number not found";
        _showError(errorMsg);
        return null;
      }
    } catch (e) {
      _showError("Database error: $e");
      return null;
    }
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showError("All fields are required");
      return;
    }

    setState(() => _loading = true);

    try {
      String? emailToLogin;

      if (_isEmail(identifier)) {
        emailToLogin = identifier;
      } else if (_isPhone(identifier)) {
        emailToLogin = await _findEmailByIdentifier("phone", identifier);
      } else {
        emailToLogin = await _findEmailByIdentifier("username", identifier);
      }

      if (emailToLogin != null) {
        await _auth.signInWithEmailAndPassword(
          email: emailToLogin,
          password: password,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);

        widget.onLoginSuccess();
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Login failed";
      if (e.code == 'user-not-found') {
        errorMsg = "User not found";
      } else if (e.code == 'wrong-password') {
        errorMsg = "Wrong password";
      } else {
        errorMsg = e.message ?? "Login failed";
      }
      _showError(errorMsg);
    } catch (e) {
      _showError("Unexpected error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const NeonTitle(title: "Login"),
              const SizedBox(height: 24),
              NeonInput(
                controller: _identifierController,
                placeholder: "Email, Username or Phone",
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              NeonPassword(
                controller: _passwordController,
                placeholder: "Password",
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/resetPassword');
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: AppColors.textColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                text: "Login",
                onClick: _handleLogin,
                loading: _loading,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(color: AppColors.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
