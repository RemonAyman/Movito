import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../utils/constants.dart';

class FriendsScreen extends StatefulWidget {
  final String userId;
  const FriendsScreen({super.key, required this.userId});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final ProfileRepository _repository = ProfileRepository();
  late TabController _tabController;

  List<Map<String, dynamic>> _friendsList = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _repository.getFriendsList(widget.userId);
      final incoming = await _repository.getFriendRequests();
      final sent = await _repository.getSentFriendRequests();
      setState(() {
        _friendsList = friends;
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
    _loadAllData();
  }

  Future<void> _declineRequest(String friendId) async {
    await _repository.cancelFriendRequest(friendId);
    _loadAllData();
  }

  Future<void> _cancelRequest(String targetId) async {
    await _repository.cancelFriendRequest(targetId);
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;
    final totalRequests = _incomingRequests.length + _sentRequests.length;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B1330),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: purple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Friends'),
                  if (_friendsList.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _CountBadge(count: _friendsList.length, color: purple),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requests'),
                  if (totalRequests > 0) ...[
                    const SizedBox(width: 8),
                    _CountBadge(
                      count: totalRequests,
                      color: _incomingRequests.isNotEmpty
                          ? Colors.redAccent
                          : purple,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: purple))
          : TabBarView(
              controller: _tabController,
              children: [
                _FriendsListTab(
                  friends: _friendsList,
                  onFriendClick: (uid) =>
                      Navigator.pushNamed(context, '/profile', arguments: uid),
                ),
                _RequestsTab(
                  incoming: _incomingRequests,
                  sent: _sentRequests,
                  onAccept: _acceptRequest,
                  onDecline: _declineRequest,
                  onCancel: _cancelRequest,
                  onUserClick: (uid) =>
                      Navigator.pushNamed(context, '/profile', arguments: uid),
                ),
              ],
            ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _FriendsListTab extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final Function(String) onFriendClick;

  const _FriendsListTab({required this.friends, required this.onFriendClick});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return _buildEmptyState("No friends yet", "Start adding friends!");
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _FriendCard(
          friend: friend,
          onClick: () => onFriendClick(friend['uid']),
        );
      },
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

class _RequestsTab extends StatelessWidget {
  final List<Map<String, dynamic>> incoming;
  final List<Map<String, dynamic>> sent;
  final Function(String) onAccept;
  final Function(String) onDecline;
  final Function(String) onCancel;
  final Function(String) onUserClick;

  const _RequestsTab({
    required this.incoming,
    required this.sent,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onUserClick,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Incoming Requests",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (incoming.isEmpty)
          _buildEmptyBox("No incoming requests")
        else
          ...incoming.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(
                user: user,
                primaryActionText: "Accept",
                primaryColor: Colors.green,
                secondaryActionText: "Decline",
                onPrimary: () => onAccept(user['uid']),
                onSecondary: () => onDecline(user['uid']),
                onClick: () => onUserClick(user['uid']),
              ),
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          "Sent Requests",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (sent.isEmpty)
          _buildEmptyBox("No sent requests")
        else
          ...sent.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(
                user: user,
                primaryActionText: "Cancel",
                primaryColor: Colors.redAccent,
                onPrimary: () => onCancel(user['uid']),
                onClick: () => onUserClick(user['uid']),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyBox(String text) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1330).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Map<String, dynamic> friend;
  final VoidCallback onClick;

  const _FriendCard({required this.friend, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final purple = AppColors.primaryPurple;
    final avatarBase64 = friend['avatarBase64'] ?? "";
    final username = friend['username'] ?? "User";

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
            _AvatarImage(
              avatarBase64: avatarBase64,
              username: username,
              purple: purple,
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
                    friend['email'] ?? "",
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
            const Text(
              "Friend",
              style: TextStyle(
                color: Color(0xFF48C774),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String primaryActionText;
  final Color primaryColor;
  final String? secondaryActionText;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback onClick;

  const _RequestCard({
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
        ),
        child: Row(
          children: [
            _AvatarImage(
              avatarBase64: avatarBase64,
              username: username,
              purple: purple,
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

class _AvatarImage extends StatelessWidget {
  final String avatarBase64;
  final String username;
  final Color purple;

  const _AvatarImage({
    required this.avatarBase64,
    required this.username,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            ? Image.memory(base64Decode(avatarBase64), fit: BoxFit.cover)
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
    );
  }
}
