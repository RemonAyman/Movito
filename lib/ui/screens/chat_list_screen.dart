import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/chat_repository.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatRepository _repository = ChatRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, Map<String, dynamic>> _usersMap = {};

  @override
  void initState() {
    super.initState();
    _listenToUsers();
  }

  void _listenToUsers() {
    _db.collection('users').snapshots().listen((snapshot) {
      final Map<String, Map<String, dynamic>> temp = {};
      for (var doc in snapshot.docs) {
        temp[doc.id] = doc.data();
      }
      if (mounted) setState(() => _usersMap = temp);
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return DateFormat('HH:mm').format(date);
    if (diff.inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;
    final currentUid = _repository.currentUserId;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B1330),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: purple),
            onPressed: () {
              // TODO: Navigate to new chat
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repository.getChatList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: purple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final chats = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final isGroup = chat['isGroup'] ?? false;
              String name = "Unknown";
              String? avatarBase64;

              if (isGroup) {
                name = chat['name'] ?? "Group";
                avatarBase64 = chat['avatarBase64'];
              } else {
                final members = List<String>.from(chat['members'] ?? []);
                final otherUid = members.firstWhere(
                  (id) => id != currentUid,
                  orElse: () => "",
                );
                final user = _usersMap[otherUid];
                name = user?['username'] ?? "Unknown";
                avatarBase64 = user?['avatarBase64'];
              }

              return _ChatItemCard(
                id: chat['id'],
                name: name,
                lastMessage: chat['lastMessage'] ?? "",
                time: _formatTimestamp(chat['lastMessageTime'] as Timestamp?),
                avatarBase64: avatarBase64,
                unreadCount: (chat['unread'] ?? 0) as int,
                onClick: () {
                  if (isGroup) {
                    Navigator.pushNamed(
                      context,
                      '/chat_detail',
                      arguments: chat['id'],
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/private_chat_detail',
                      arguments: chat['id'],
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "No chats yet",
            style: TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a conversation with your friends!",
            style: TextStyle(
              color: AppColors.primaryPurple.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItemCard extends StatelessWidget {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String? avatarBase64;
  final int unreadCount;
  final VoidCallback onClick;

  const _ChatItemCard({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.avatarBase64,
    required this.unreadCount,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final purple = AppColors.primaryPurple;

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
            _Avatar(avatarBase64: avatarBase64, name: name, purple: purple),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      Text(
                        time,
                        style: TextStyle(
                          color: purple.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: const TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B5DE5), Color(0xFF7B3FD5)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? "99+" : "$unreadCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarBase64;
  final String name;
  final Color purple;

  const _Avatar({this.avatarBase64, required this.name, required this.purple});

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
        border: Border.all(color: purple.withOpacity(0.3), width: 2),
      ),
      child: ClipOval(
        child: avatarBase64 != null && avatarBase64!.isNotEmpty
            ? Image.memory(base64Decode(avatarBase64!), fit: BoxFit.cover)
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
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
