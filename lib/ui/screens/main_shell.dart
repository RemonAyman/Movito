import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';
import 'add_friend_screen.dart';
import 'profile_screen.dart';
import '../../data/user_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String? _avatarBase64;
  String? _username;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const ChatListScreen(),
    const AddFriendScreen(),
    ProfileScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ""),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final data = await UserPreferences.getUserData();
    setState(() {
      _username = data['name'];
      _avatarBase64 = data['avatar'];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primaryPurple,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: "Search",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: "Chats",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_add_alt_1_rounded),
              label: "Add",
            ),
            BottomNavigationBarItem(
              icon: _buildProfileIcon(),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    final bool isSelected = _selectedIndex == 4;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primaryPurple : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _avatarBase64 != null && _avatarBase64!.isNotEmpty
            ? Image.memory(
                base64Decode(_avatarBase64!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 20),
              )
            : Container(
                color: AppColors.primaryPurple.withOpacity(0.5),
                child: Center(
                  child: Text(
                    _username != null && _username!.isNotEmpty
                        ? _username![0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
