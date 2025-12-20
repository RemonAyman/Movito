import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/chat_repository.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatRepository _repository = ChatRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _groupName = "Group Chat";
  Map<String, Map<String, dynamic>> _membersData = {};

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

  Future<void> _loadChatInfo() async {
    try {
      final doc = await _db.collection('chats').doc(widget.chatId).get();
      final name = doc.data()?['name'] ?? "Group Chat";
      final members = List<String>.from(doc.data()?['members'] ?? []);

      final Map<String, Map<String, dynamic>> temp = {};
      for (var uid in members) {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          temp[uid] = userDoc.data()!;
        }
      }

      setState(() {
        _groupName = name;
        _membersData = temp;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _repository.sendMessage(widget.chatId, text);
    _messageController.clear();
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1330),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MembersSheet(
        chatId: widget.chatId,
        currentMembers: _membersData,
        onUpdate: _loadChatInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _repository.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _groupName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: _showMembersSheet,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _repository.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg['senderId'] == currentUid;
                    final sender = _membersData[msg['senderId']];
                    final senderName = sender?['username'] ?? "Unknown";
                    final senderAvatar = sender?['avatarBase64'];

                    return _MessageBubble(
                      text: msg['text'] ?? "",
                      senderName: isMine ? "You" : senderName,
                      isMine: isMine,
                      timestamp: msg['timestamp'] as Timestamp?,
                      senderAvatar: senderAvatar,
                      isSharedMovie: msg['isSharedMovie'] ?? false,
                      movieData: msg['isSharedMovie'] == true ? msg : null,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A1B3D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMine;
  final Timestamp? timestamp;
  final String? senderAvatar;
  final bool isSharedMovie;
  final Map<String, dynamic>? movieData;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.isMine,
    this.timestamp,
    this.senderAvatar,
    this.isSharedMovie = false,
    this.movieData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            _Avatar(avatarBase64: senderAvatar, name: senderName, size: 36),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Text(
                    senderName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 2),
                if (isSharedMovie)
                  _MovieBubble(data: movieData!, isMine: isMine)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppColors.primaryPurple
                          : const Color(0xFF333333),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('HH:mm').format(timestamp!.toDate()),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _MovieBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMine;
  const _MovieBubble({required this.data, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isMine ? AppColors.primaryPurple : const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/details',
          arguments: data['movieId'],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['moviePoster'] ?? "",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey, width: 60, height: 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['movieTitle'] ?? "Movie",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "⭐ ${data['movieRating']?.toStringAsFixed(1) ?? '0.0'}",
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Tap to view details",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarBase64;
  final String name;
  final double size;

  const _Avatar({this.avatarBase64, required this.name, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final purple = AppColors.primaryPurple;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [purple.withValues(alpha: 0.3), const Color(0xFF2A1B3D)],
        ),
      ),
      child: ClipOval(
        child: avatarBase64 != null && avatarBase64!.isNotEmpty
            ? Image.memory(base64Decode(avatarBase64!), fit: BoxFit.cover)
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: purple,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}

class _MembersSheet extends StatefulWidget {
  final String chatId;
  final Map<String, Map<String, dynamic>> currentMembers;
  final VoidCallback onUpdate;

  const _MembersSheet({
    required this.chatId,
    required this.currentMembers,
    required this.onUpdate,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final snapshot = await _db.collection('users').get();
    setState(() {
      _allUsers = snapshot.docs
          .map((doc) => doc.data()..['uid'] = doc.id)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _toggleMember(String uid, bool isAdd) async {
    if (isAdd) {
      await _db.collection('chats').doc(widget.chatId).update({
        'members': FieldValue.arrayUnion([uid]),
      });
    } else {
      await _db.collection('chats').doc(widget.chatId).update({
        'members': FieldValue.arrayRemove([uid]),
      });
    }
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Manage Members",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      final isMember = widget.currentMembers.containsKey(
                        user['uid'],
                      );
                      return ListTile(
                        leading: _Avatar(
                          avatarBase64: user['avatarBase64'],
                          name: user['username'] ?? "?",
                          size: 40,
                        ),
                        title: Text(
                          user['username'] ?? "User",
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isMember ? Icons.remove_circle : Icons.add_circle,
                            color: isMember ? Colors.red : Colors.green,
                          ),
                          onPressed: () =>
                              _toggleMember(user['uid'], !isMember),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
