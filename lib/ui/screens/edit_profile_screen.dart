import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const EditProfileScreen({super.key, this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _avatarBase64;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _usernameController.text = data?['username'] ?? '';
            _emailController.text = data?['email'] ?? '';
            _phoneController.text = data?['phone'] ?? '';
            _avatarBase64 = data?['avatarBase64'];
            _isLoading = false;
          });
        }
      } catch (e) {
        _showSnackbar('❌ فشل تحميل البيانات');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await File(image.path).readAsBytes();
        final base64 = base64Encode(bytes);

        final user = _auth.currentUser;
        if (user != null) {
          await _db.collection('users').doc(user.uid).update({
            'avatarBase64': base64,
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('avatarBase64', base64);

          setState(() {
            _avatarBase64 = base64;
            _isUploading = false;
          });
          _showSnackbar('✅ الصورة اتسجلت');
        }
      } catch (e) {
        _showSnackbar('❌ فشل حفظ الصورة');
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = _usernameController.text.trim();
    if (name.length < 3) {
      _showSnackbar('⚠️ الاسم لازم يكون 3 حروف على الأقل');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _db.collection('users').doc(user.uid).update({'username': name});
      _showSnackbar('✅ تم حفظ التغييرات');
    } catch (e) {
      _showSnackbar('❌ فشل حفظ التغييرات');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: purple))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _TopBarNeon(
                    borderColor: purple,
                    onBackClick: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  _AvatarSection(
                    avatarBase64: _avatarBase64,
                    usernameInitial: _usernameController.text.isNotEmpty
                        ? _usernameController.text[0].toUpperCase()
                        : '?',
                    onPickImage: _pickImage,
                    isUploading: _isUploading,
                    purple: purple,
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _OutlinedPurpleField(
                          controller: _usernameController,
                          placeholder: 'Username',
                          icon: Icons.person,
                          borderColor: purple,
                        ),
                        const SizedBox(height: 20),
                        _OutlinedPurpleField(
                          controller: _emailController,
                          placeholder: 'Email',
                          icon: Icons.email,
                          borderColor: purple,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),
                        _OutlinedPurpleField(
                          controller: _phoneController,
                          placeholder: 'Phone Number',
                          icon: Icons.phone,
                          borderColor: purple,
                          readOnly: true,
                        ),
                        const SizedBox(height: 30),
                        _SaveButton(
                          isSaving: _isSaving || _isUploading,
                          onPressed: _saveChanges,
                          purple: purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TopBarNeon extends StatelessWidget {
  final Color borderColor;
  final VoidCallback onBackClick;
  const _TopBarNeon({required this.borderColor, required this.onBackClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(top: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 15,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: borderColor),
              onPressed: onBackClick,
            ),
          ),
          const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: AppColors.primaryPurple, blurRadius: 25)],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final String? avatarBase64;
  final String usernameInitial;
  final VoidCallback onPickImage;
  final bool isUploading;
  final Color purple;

  const _AvatarSection({
    required this.avatarBase64,
    required this.usernameInitial,
    required this.onPickImage,
    required this.isUploading,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: purple.withValues(alpha: 0.5), blurRadius: 40),
              ],
              color: avatarBase64 != null
                  ? Colors.transparent
                  : Colors.grey[800],
            ),
            child: ClipOval(
              child: avatarBase64 != null
                  ? Image.memory(base64Decode(avatarBase64!), fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        usernameInitial,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: purple,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: onPickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: purple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          if (isUploading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutlinedPurpleField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final Color borderColor;
  final bool readOnly;

  const _OutlinedPurpleField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    required this.borderColor,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: borderColor),
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;
  final Color purple;

  const _SaveButton({
    required this.isSaving,
    required this.onPressed,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 20,
          shadowColor: purple,
        ),
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
