import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MediaListItem {
  final String movieId;
  final String title;
  final String poster;
  final double rating;
  final double voteAverage;

  MediaListItem({
    required this.movieId,
    required this.title,
    required this.poster,
    required this.rating,
    required this.voteAverage,
  });

  factory MediaListItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MediaListItem(
      movieId: data['movieId'] ?? '',
      title: data['title'] ?? '',
      poster: data['poster'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      voteAverage: (data['vote_average'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'movieId': movieId,
      'title': title,
      'poster': poster,
      'rating': rating,
      'vote_average': voteAverage,
    };
  }
}

class RatingItem extends MediaListItem {
  final String review;
  final int ratedDate;

  RatingItem({
    required super.movieId,
    required super.title,
    required super.poster,
    required super.rating,
    required super.voteAverage,
    required this.review,
    required this.ratedDate,
  });

  factory RatingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingItem(
      movieId: data['movieId'] ?? '',
      title: data['title'] ?? '',
      poster: data['poster'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      voteAverage: (data['vote_average'] ?? 0).toDouble(),
      review: data['review'] ?? '',
      ratedDate: data['ratedDate'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['review'] = review;
    map['ratedDate'] = ratedDate;
    return map;
  }
}

class MediaRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference _getCollection(String userId, String collectionName) {
    return _db.collection('users').doc(userId).collection(collectionName);
  }

  // Generic methods for Favorites, Watchlist, Watched
  Future<List<MediaListItem>> getMediaList(
    String userId,
    String collectionName,
  ) async {
    final snapshot = await _getCollection(userId, collectionName).get();
    return snapshot.docs
        .map((doc) => MediaListItem.fromFirestore(doc))
        .toList();
  }

  Future<void> addToMediaList(String collectionName, MediaListItem item) async {
    if (currentUserId == null) return;
    await _getCollection(
      currentUserId!,
      collectionName,
    ).doc(item.movieId).set(item.toMap());
  }

  Future<void> removeFromMediaList(
    String collectionName,
    String movieId,
  ) async {
    if (currentUserId == null) return;
    await _getCollection(currentUserId!, collectionName).doc(movieId).delete();
  }

  Future<bool> isInMediaList(String collectionName, String movieId) async {
    if (currentUserId == null) return false;
    final doc = await _getCollection(
      currentUserId!,
      collectionName,
    ).doc(movieId).get();
    return doc.exists;
  }

  // Ratings
  Future<List<RatingItem>> getRatings(String userId) async {
    final snapshot = await _getCollection(
      userId,
      'ratings',
    ).orderBy('ratedDate', descending: true).get();
    return snapshot.docs.map((doc) => RatingItem.fromFirestore(doc)).toList();
  }

  Future<void> addRating(RatingItem item) async {
    if (currentUserId == null) return;
    await _getCollection(
      currentUserId!,
      'ratings',
    ).doc(item.movieId).set(item.toMap());
  }

  Future<void> updateRating(
    String movieId,
    double rating,
    String review,
  ) async {
    if (currentUserId == null) return;
    await _getCollection(currentUserId!, 'ratings').doc(movieId).update({
      'rating': rating,
      'review': review,
      'ratedDate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeRating(String movieId) async {
    if (currentUserId == null) return;
    await _getCollection(currentUserId!, 'ratings').doc(movieId).delete();
  }

  Future<RatingItem?> getRating(String userId, String movieId) async {
    final doc = await _getCollection(userId, 'ratings').doc(movieId).get();
    if (doc.exists) return RatingItem.fromFirestore(doc);
    return null;
  }
}
