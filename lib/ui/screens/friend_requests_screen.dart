import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../utils/constants.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final ProfileRepository _repository = ProfileRepository();

  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final incoming = await _repository.getFriendRequests();
      final sent = await _repository.getSentFriendRequests();
      setState(() {
        _incomingRequests = incoming;
        _sentRequests = sent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(String friendId) async {
    await _repository.acceptFriendRequest(friendId);
    _fetchRequests();
  }

  Future<void> _declineRequest(String friendId) async {
    await _repository.cancelFriendRequest(friendId);
    _fetchRequests();
  }

  Future<void> _cancelRequest(String targetId) async {
    await _repository.cancelFriendRequest(targetId);
    _fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      appBar: AppBar(
        title: const Text(
          'Friend Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B1330),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    title: "Incoming Requests",
                    list: _incomingRequests,
                    itemBuilder: (user) => _FriendRequestCard(
                      user: user,
                      primaryActionText: "Accept",
                      primaryColor: Colors.green,
                      secondaryActionText: "Decline",
                      onPrimary: () => _acceptRequest(user['uid']),
                      onSecondary: () => _declineRequest(user['uid']),
                      onClick: () => Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: user['uid'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: "Sent Requests",
                    list: _sentRequests,
                    itemBuilder: (user) => _FriendRequestCard(
                      user: user,
                      primaryActionText: "Cancel",
                      primaryColor: Colors.redAccent,
                      onPrimary: () => _cancelRequest(user['uid']),
                      onClick: () => Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: user['uid'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> list;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  const _Section({
    required this.title,
    required this.list,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1330).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No requests",
                    style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 16),
                  ),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => itemBuilder(list[index]),
          ),
      ],
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String primaryActionText;
  final Color primaryColor;
  final String? secondaryActionText;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback onClick;

  const _FriendRequestCard({
    required this.user,
    required this.primaryActionText,
    required this.primaryColor,
    this.secondaryActionText,
    required this.onPrimary,
    this.onSecondary,
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    primaryActionText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (secondaryActionText != null) ...[
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF5350),
                      side: const BorderSide(color: Color(0xFFEF5350)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      secondaryActionText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
