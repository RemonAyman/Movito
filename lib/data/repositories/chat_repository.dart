import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notification_service.dart';
import '../user_preferences.dart';

class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<Map<String, dynamic>>> getChatList() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('chats')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList(),
        );
  }

  Future<void> sendMessage(
    String chatId,
    String text, {
    bool isImage = false,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final messageData = {
      'senderId': uid,
      'text': text,
      'isImage': isImage,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    final messageRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(messageRef, messageData);

    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': isImage ? '📷 Image' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Trigger Notifications
    try {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data()!;
      final members = List<String>.from(chatData['members']);
      final isGroup = chatData['isGroup'] ?? false;
      final chatTitle = isGroup
          ? (chatData['name'] ?? "Group Chat")
          : "New Message";

      final userData = await UserPreferences.getUserData();
      final senderName = userData['name'] ?? "Someone";
      final senderAvatar = userData['avatar'] ?? "";

      final notificationService = NotificationService();
      for (var memberId in members) {
        if (memberId != uid) {
          await notificationService.sendNotificationToUser(
            userId: memberId,
            title: isGroup ? "$chatTitle ($senderName)" : senderName,
            body: isImage ? "📷 Image" : text,
            chatId: chatId,
            isGroup: isGroup,
            senderAvatar: senderAvatar,
          );
        }
      }
    } catch (e) {
      print("Error sending notifications: $e");
    }
  }

  Future<String> getOrCreatePrivateChat(String otherUserId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("User not logged in");

    final existing = await _db
        .collection('chats')
        .where('isGroup', isEqualTo: false)
        .where('members', arrayContains: uid)
        .get();

    for (var doc in existing.docs) {
      final members = List<String>.from(doc.data()['members']);
      if (members.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new
    final newChat = await _db.collection('chats').add({
      'isGroup': false,
      'members': [uid, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unread': 0,
    });

    return newChat.id;
  }
}
