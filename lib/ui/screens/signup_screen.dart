import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../widgets/neon_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      _showError("All fields are required");
      return;
    }

    if (!RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email)) {
      _showError("Invalid email address");
      return;
    }

    if (!RegExp(r"^01[0-9]{9}$").hasMatch(phone)) {
      _showError("Phone must start with 01 and be 11 digits");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid ?? "";

      await _db.collection("users").document(uid).set({
        "username": username,
        "email": email,
        "phone": phone,
        "password":
            password, // Note: Kotlin project saves password in plain text to Firestore (not recommended, but I'm porting it)
        "uid": uid,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Signup failed");
    } catch (e) {
      _showError("Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              const NeonTitle(title: "Sign Up"),
              const SizedBox(height: 24),
              NeonInput(
                controller: _usernameController,
                placeholder: "Username",
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              NeonInput(
                controller: _emailController,
                placeholder: "Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              NeonInput(
                controller: _phoneController,
                placeholder: "Phone Number",
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              NeonPassword(
                controller: _passwordController,
                placeholder: "Password",
              ),
              const SizedBox(height: 16),
              NeonPassword(
                controller: _confirmPasswordController,
                placeholder: "Confirm Password",
              ),
              const SizedBox(height: 24),
              NeonButton(
                text: "Sign Up",
                onClick: _handleSignUp,
                loading: _loading,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Already have an account? Log in",
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

// Extension to match document() vs doc() in newer web/js vs flutter firestore
extension FirestoreDocExt on CollectionReference {
  DocumentReference document(String path) => doc(path);
}
