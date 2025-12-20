import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/chat_repository.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class PrivateChatDetailScreen extends StatefulWidget {
  final String chatId;
  const PrivateChatDetailScreen({super.key, required this.chatId});

  @override
  State<PrivateChatDetailScreen> createState() =>
      _PrivateChatDetailScreenState();
}

class _PrivateChatDetailScreenState extends State<PrivateChatDetailScreen> {
  final ChatRepository _repository = ChatRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _targetUserId = "";
  String _targetUserName = "User";
  String? _targetAvatarBase64;
  String? _currentUserName;
  String? _currentUserAvatar;

  Map<String, Map<String, dynamic>> _membersData = {};
  bool _isLoadingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

  Future<void> _loadChatInfo() async {
    final currentUid = _repository.currentUserId;
    if (currentUid == null) return;

    try {
      final doc = await _db.collection('chats').doc(widget.chatId).get();
      final members = List<String>.from(doc.data()?['members'] ?? []);

      final Map<String, Map<String, dynamic>> temp = {};
      for (var uid in members) {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          temp[uid] = userDoc.data()!;
        }
      }

      final otherUid = members.firstWhere(
        (id) => id != currentUid,
        orElse: () => "",
      );
      setState(() {
        _membersData = temp;
        _targetUserId = otherUid;
        _targetUserName = temp[otherUid]?['username'] ?? "User";
        _targetAvatarBase64 = temp[otherUid]?['avatarBase64'];
        _currentUserName = temp[currentUid]?['username'];
        _currentUserAvatar = temp[currentUid]?['avatarBase64'];
        _isLoadingInfo = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingInfo = false);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _repository.sendMessage(widget.chatId, text);
    _messageController.clear();
  }

  String _formatDateHeader(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year)
      return "Today";
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year)
      return "Yesterday";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _repository.currentUserId;
    const purple = AppColors.primaryPurple;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isLoadingInfo
            ? const SizedBox.shrink()
            : Row(
                children: [
                  _Avatar(
                    avatarBase64: _targetAvatarBase64,
                    name: _targetUserName,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _targetUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
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
                    final nextMsg = index < messages.length - 1
                        ? messages[index + 1]
                        : null;

                    bool showHeader = false;
                    if (nextMsg == null) {
                      showHeader = true;
                    } else {
                      final currDate = (msg['timestamp'] as Timestamp?)
                          ?.toDate();
                      final nextDate = (nextMsg['timestamp'] as Timestamp?)
                          ?.toDate();
                      if (currDate != null &&
                          nextDate != null &&
                          (currDate.day != nextDate.day ||
                              currDate.month != nextDate.month ||
                              currDate.year != nextDate.year)) {
                        showHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showHeader)
                          _DateHeader(
                            text: _formatDateHeader(msg['timestamp']),
                          ),
                        _MessageBubble(
                          text: msg['text'] ?? "",
                          isMine: isMine,
                          timestamp: msg['timestamp'] as Timestamp?,
                          senderAvatar: !isMine ? _targetAvatarBase64 : null,
                          isSharedMovie: msg['isSharedMovie'] ?? false,
                          movieData: msg['isSharedMovie'] == true ? msg : null,
                        ),
                      ],
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
      color: Colors.transparent,
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

class _DateHeader extends StatelessWidget {
  final String text;
  const _DateHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1B3D).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primaryPurple,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final Timestamp? timestamp;
  final String? senderAvatar;
  final bool isSharedMovie;
  final Map<String, dynamic>? movieData;

  const _MessageBubble({
    required this.text,
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
            _Avatar(avatarBase64: senderAvatar, name: "?", size: 36),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: isSharedMovie
                ? _MovieBubble(data: movieData!, isMine: isMine)
                : Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(timestamp!.toDate()),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
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
                          "⭐ ${(data['movieRating'] as num?)?.toDouble().toStringAsFixed(1) ?? '0.0'}",
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
          colors: [purple.withOpacity(0.3), const Color(0xFF2A1B3D)],
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
