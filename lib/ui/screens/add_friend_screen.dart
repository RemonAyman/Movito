import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../utils/constants.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final ProfileRepository _repository = ProfileRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Map<String, String> _userStatuses = {};
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _repository.getAllUsers();
      final Map<String, String> statuses = {};
      for (var user in users) {
        statuses[user['uid']] = await _repository.getRelationshipStatus(
          user['uid'],
        );
      }
      setState(() {
        _allUsers = users;
        _userStatuses = statuses;
        _isLoading = false;
        _filterUsers(_searchQuery);
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = [];
      } else {
        _filteredUsers = _allUsers.where((user) {
          final username = user['username']?.toString().toLowerCase() ?? "";
          final email = user['email']?.toString().toLowerCase() ?? "";
          return username.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _sendRequest(String targetId) async {
    await _repository.sendFriendRequest(targetId);
    _updateStatus(targetId);
  }

  Future<void> _cancelRequest(String targetId) async {
    await _repository.cancelFriendRequest(targetId);
    _updateStatus(targetId);
  }

  Future<void> _updateStatus(String targetId) async {
    final status = await _repository.getRelationshipStatus(targetId);
    setState(() {
      _userStatuses[targetId] = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      appBar: AppBar(
        title: const Text(
          'Find Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B1330),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by username',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: purple),
                filled: true,
                fillColor: const Color(0xFF1B1330),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: purple))
                : _searchQuery.isEmpty
                ? _buildEmptyState(
                    "Search for users",
                    "Enter a username to find friends",
                  )
                : _filteredUsers.isEmpty
                ? _buildEmptyState("No users found", "Try a different search")
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final status = _userStatuses[user['uid']] ?? 'none';
                      return _UserCard(
                        user: user,
                        status: status,
                        onAdd: () => _sendRequest(user['uid']),
                        onCancel: () => _cancelRequest(user['uid']),
                        onClick: () => Navigator.pushNamed(
                          context,
                          '/profile',
                          arguments: user['uid'],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.primaryPurple.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String status;
  final VoidCallback onAdd;
  final VoidCallback onCancel;
  final VoidCallback onClick;

  const _UserCard({
    required this.user,
    required this.status,
    required this.onAdd,
    required this.onCancel,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final purple = AppColors.primaryPurple;
    final avatarBase64 = user['avatarBase64'] ?? "";
    final username = user['username'] ?? "User";

    return InkWell(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1330),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purple.withOpacity(0.3), const Color(0xFF2A1B3D)],
                ),
              ),
              child: ClipOval(
                child: avatarBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(avatarBase64),
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : "?",
                          style: TextStyle(
                            color: purple,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user['email'] ?? "",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (status == 'friend') {
      return const Text(
        "Friend",
        style: TextStyle(
          color: Color(0xFF48C774),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (status == 'sent') {
      return OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF5350),
          side: const BorderSide(color: Color(0xFFEF5350)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text(
          "Cancel",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    } else if (status == 'pending') {
      return const Text(
        "Pending",
        style: TextStyle(
          color: Colors.orangeAccent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onAdd,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text(
          "Add Friend",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}
