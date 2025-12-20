import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/chat_repository.dart';
import '../../utils/constants.dart';

class NewPrivateChatScreen extends StatefulWidget {
  const NewPrivateChatScreen({super.key});

  @override
  State<NewPrivateChatScreen> createState() => _NewPrivateChatScreenState();
}

class _NewPrivateChatScreenState extends State<NewPrivateChatScreen> {
  final ChatRepository _repository = ChatRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _searchText = "";
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUid = _repository.currentUserId;
      final snapshot = await _db.collection('users').get();
      final list = snapshot.docs
          .where((doc) => doc.id != currentUid)
          .map((doc) => doc.data()..['uid'] = doc.id)
          .toList();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startChat(String otherUid) async {
    setState(() => _isCreating = true);
    try {
      final chatId = await _repository.getOrCreatePrivateChat(otherUid);
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/private_chat_detail',
          arguments: chatId,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;
    final filteredUsers = _users.where((user) {
      final name = (user['username'] ?? "").toString().toLowerCase();
      return name.contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      appBar: AppBar(
        title: const Text(
          'Start Private Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B1330),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => _searchText = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search user by name...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: purple),
                filled: true,
                fillColor: const Color(0xFF1B1330),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2A1B3D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: purple),
                ),
              ),
            ),
          ),
          if (_isCreating) const LinearProgressIndicator(color: purple),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: purple))
                : filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _UserCard(
                        user: user,
                        onClick: () => _startChat(user['uid']),
                        purple: purple,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "No users found",
            style: TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search term",
            style: TextStyle(
              color: AppColors.primaryPurple.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onClick;
  final Color purple;

  const _UserCard({
    required this.user,
    required this.onClick,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['username'] ?? "User";
    final avatarBase64 = user['avatarBase64'] ?? "";

    return InkWell(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1330),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(avatarBase64: avatarBase64, name: name, purple: purple),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.person_add, color: purple, size: 24),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatarBase64;
  final String name;
  final Color purple;

  const _Avatar({
    required this.avatarBase64,
    required this.name,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [purple.withValues(alpha: 0.3), const Color(0xFF2A1B3D)],
        ),
      ),
      child: ClipOval(
        child: avatarBase64.isNotEmpty
            ? Image.memory(base64Decode(avatarBase64), fit: BoxFit.cover)
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: purple,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}
