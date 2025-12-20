import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<String> getTotalWatchedTime(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('watched')
          .get();

      int totalMinutes = 0;
      for (var doc in snapshot.docs) {
        totalMinutes += (doc.data()['duration'] as num?)?.toInt() ?? 0;
      }

      final days = totalMinutes ~/ (24 * 60);
      final hours = (totalMinutes % (24 * 60)) ~/ 60;
      final minutes = totalMinutes % 60;

      return '${days}d ${hours}h ${minutes}m';
    } catch (e) {
      return '0d 0h 0m';
    }
  }

  Future<List<Map<String, dynamic>>> getWatchedMovies(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('watched')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getFavoriteMovies(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .limit(5)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getWatchlistMovies(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getRatedMovies(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('ratings')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Friends Logic
  Future<int> getFriendsCount(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();
    return snapshot.docs.length;
  }

  Future<String> getRelationshipStatus(String targetUserId) async {
    final uid = currentUserId;
    if (uid == null || uid == targetUserId) return 'self';

    // Check if friends
    final friendDoc = await _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(targetUserId)
        .get();
    if (friendDoc.exists) return 'friend';

    // Check friend requests
    final requestDoc = await _db
        .collection('users')
        .doc(uid)
        .collection('friendRequests')
        .doc(targetUserId)
        .get();
    if (requestDoc.exists) {
      return requestDoc.data()?['status'] ?? 'none';
    }

    return 'none';
  }

  Future<void> sendFriendRequest(String targetId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final batch = _db.batch();
    final senderRef = _db
        .collection('users')
        .doc(uid)
        .collection('friendRequests')
        .doc(targetId);
    final receiverRef = _db
        .collection('users')
        .doc(targetId)
        .collection('friendRequests')
        .doc(uid);

    batch.set(senderRef, {
      'from': uid,
      'to': targetId,
      'status': 'sent',
      'timestamp': FieldValue.serverTimestamp(),
    });
    batch.set(receiverRef, {
      'from': uid,
      'to': targetId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> acceptFriendRequest(String friendId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final batch = _db.batch();
    batch.delete(
      _db
          .collection('users')
          .doc(uid)
          .collection('friendRequests')
          .doc(friendId),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(friendId)
          .collection('friendRequests')
          .doc(uid),
    );

    final friendData = {'since': FieldValue.serverTimestamp()};
    batch.set(
      _db.collection('users').doc(uid).collection('friends').doc(friendId),
      friendData,
    );
    batch.set(
      _db.collection('users').doc(friendId).collection('friends').doc(uid),
      friendData,
    );

    await batch.commit();
  }

  Future<void> removeFriend(String friendId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(uid).collection('friends').doc(friendId),
    );
    batch.delete(
      _db.collection('users').doc(friendId).collection('friends').doc(uid),
    );
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final uid = currentUserId;
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .where((doc) => doc.id != uid)
        .map((doc) => doc.data()..['uid'] = doc.id)
        .toList();
  }

  Future<void> cancelFriendRequest(String targetId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final batch = _db.batch();
    batch.delete(
      _db
          .collection('users')
          .doc(uid)
          .collection('friendRequests')
          .doc(targetId),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(targetId)
          .collection('friendRequests')
          .doc(uid),
    );
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .get();

    List<Map<String, dynamic>> users = [];
    for (var doc in snapshot.docs) {
      final userDoc = await _db.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        users.add(userDoc.data()!..['uid'] = userDoc.id);
      }
    }
    return users;
  }

  Future<List<Map<String, dynamic>>> getSentFriendRequests() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('friendRequests')
        .where('status', isEqualTo: 'sent')
        .get();

    List<Map<String, dynamic>> users = [];
    for (var doc in snapshot.docs) {
      final userDoc = await _db.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        users.add(userDoc.data()!..['uid'] = userDoc.id);
      }
    }
    return users;
  }

  Future<List<Map<String, dynamic>>> getFriendsList(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();

    List<Map<String, dynamic>> users = [];
    for (var doc in snapshot.docs) {
      final userDoc = await _db.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        users.add(userDoc.data()!..['uid'] = userDoc.id);
      }
    }
    return users;
  }
}
