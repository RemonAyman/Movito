import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../widgets/neon_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showMsg(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMsg("Email is required");
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMsg("Reset link sent to your email");
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showMsg(e.message ?? "Error sending reset email");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const NeonTitle(title: "Reset"),
            const SizedBox(height: 24),
            NeonInput(
              controller: _emailController,
              placeholder: "Enter your email",
              icon: Icons.email,
            ),
            const SizedBox(height: 24),
            NeonButton(
              text: "Send Reset Link",
              onClick: _handleReset,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
