import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/models/movie.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user profile
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repository = ProfileRepository();

  bool _isLoading = true;
  String _username = "Username";
  String _avatarBase64 = "";
  String _joinDate = "Jun 5, 2025";
  int _friendsCount = 0;
  String _totalWatchTime = "0d 0h 0m";
  String _relationshipStatus = "self";

  List<Movie> _favoriteMovies = [];
  List<Movie> _watchlistMovies = [];
  List<Movie> _watchedMovies = [];
  List<Movie> _ratedMovies = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final uid = widget.userId ?? _repository.currentUserId;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final userData = await _repository.getUserData(uid);
      final watchTime = await _repository.getTotalWatchedTime(uid);
      final friends = await _repository.getFriendsCount(uid);
      final status = await _repository.getRelationshipStatus(uid);

      final favorites = await _repository.getFavoriteMovies(uid);
      final watchlist = await _repository.getWatchlistMovies(uid);
      final watched = await _repository.getWatchedMovies(uid);
      final rated = await _repository.getRatedMovies(uid);

      setState(() {
        _username = userData?['username'] ?? "Username";
        _avatarBase64 = userData?['avatarBase64'] ?? "";
        _joinDate = "Dec 2025"; // In real app, format timestamp
        _totalWatchTime = watchTime;
        _friendsCount = friends;
        _relationshipStatus = status;

        _favoriteMovies = favorites.map((e) => _mapToMovie(e)).toList();
        _watchlistMovies = watchlist.map((e) => _mapToMovie(e)).toList();
        _watchedMovies = watched.map((e) => _mapToMovie(e)).toList();
        _ratedMovies = rated.map((e) => _mapToMovie(e)).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Movie _mapToMovie(Map<String, dynamic> data) {
    return Movie(
      id: int.tryParse(data['movieId']?.toString() ?? '0') ?? 0,
      title: data['title'] ?? '',
      overview: data['overview'] ?? '',
      posterPath: data['poster'],
      voteAverage: (data['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: data['release_date'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _ProfileHeader(
                    username: _username,
                    avatarBase64: _avatarBase64,
                    joinDate: _joinDate,
                    friendsCount: _friendsCount,
                    isSelf: _relationshipStatus == 'self',
                    onEdit: () => Navigator.pushNamed(context, '/edit_profile'),
                  ),
                  const SizedBox(height: 24),
                  _WatchTimeCard(
                    totalWatchTime: _totalWatchTime,
                    watchedCount: _watchedMovies.length,
                  ),
                  if (_relationshipStatus != 'self') ...[
                    const SizedBox(height: 24),
                    _RelationshipButton(
                      status: _relationshipStatus,
                      onAction: (action) async {
                        final uid = widget.userId;
                        if (uid == null) return;
                        if (action == 'add')
                          await _repository.sendFriendRequest(uid);
                        if (action == 'accept')
                          await _repository.acceptFriendRequest(uid);
                        if (action == 'remove')
                          await _repository.removeFriend(uid);
                        _fetchData();
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildSection("Favorites", "Your top picks", _favoriteMovies),
                  _buildSection("Ratings", "Movies you've rated", _ratedMovies),
                  _buildSection(
                    "Watchlist",
                    "Movies to watch later",
                    _watchlistMovies,
                  ),
                  _buildSection(
                    "Watched",
                    "Your viewing history",
                    _watchedMovies,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _PremiumSectionTitle(
          title: title,
          subtitle: subtitle,
          onSeeMore: () {
            final uid = widget.userId ?? _repository.currentUserId;
            if (uid == null) return;
            if (title == "Ratings") {
              Navigator.pushNamed(context, '/ratings', arguments: uid);
            } else {
              Navigator.pushNamed(
                context,
                '/${title.toLowerCase()}',
                arguments: uid,
              );
            }
          },
        ),
        const SizedBox(height: 16),
        _PremiumMovieRow(movies: movies),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String username;
  final String avatarBase64;
  final String joinDate;
  final int friendsCount;
  final bool isSelf;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.username,
    required this.avatarBase64,
    required this.joinDate,
    required this.friendsCount,
    required this.isSelf,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF23133D),
            Color(0xFF0F0421),
            AppColors.movitoBackground,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSelf)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: onEdit,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPurple.withOpacity(0.3),
                ),
                child: ClipOval(
                  child: avatarBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(avatarBase64),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Since $joinDate",
                    style: const TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "$friendsCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WatchTimeCard extends StatelessWidget {
  final String totalWatchTime;
  final int watchedCount;

  const _WatchTimeCard({
    required this.totalWatchTime,
    required this.watchedCount,
  });

  @override
  Widget build(BuildContext context) {
    // totalWatchTime format: "0d 0h 0m"
    final parts = totalWatchTime.split(' ');
    final days = parts[0].replaceAll('d', '');
    final hours = parts[1].replaceAll('h', '');
    final minutes = parts[2].replaceAll('m', '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Time Spent on the Big Screen",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(value: days, label: "Days"),
              _StatItem(value: hours, label: "Hours"),
              _StatItem(value: minutes, label: "Minutes"),
              Container(width: 1, height: 50, color: Colors.white12),
              _StatItem(value: "$watchedCount", label: "Movies"),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

class _RelationshipButton extends StatelessWidget {
  final String status;
  final Function(String) onAction;

  const _RelationshipButton({required this.status, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (status == 'friend') {
      return _buildButton(
        "Remove Friend",
        Icons.person_remove,
        Colors.redAccent,
        () => onAction('remove'),
      );
    } else if (status == 'sent') {
      return _buildOutlined(
        "Cancel Request",
        Icons.close,
        () => onAction('cancel'),
      );
    } else if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              "Accept",
              Icons.check,
              Colors.green,
              () => onAction('accept'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOutlined(
              "Decline",
              Icons.close,
              () => onAction('decline'),
            ),
          ),
        ],
      );
    } else {
      return _buildButton(
        "Add Friend",
        Icons.person_add,
        AppColors.primaryPurple,
        () => onAction('add'),
      );
    }
  }

  Widget _buildButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlined(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          side: const BorderSide(color: AppColors.primaryPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _PremiumSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSeeMore;

  const _PremiumSectionTitle({
    required this.title,
    required this.subtitle,
    required this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.white60),
              ),
            ],
          ),
          TextButton(
            onPressed: onSeeMore,
            child: const Text(
              "See More",
              style: TextStyle(color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumMovieRow extends StatelessWidget {
  final List<Movie> movies;
  const _PremiumMovieRow({required this.movies});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final posterUrl = movie.posterPath != null
              ? "${AppConstants.imageBaseUrl}${movie.posterPath}"
              : null;

          return GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, '/details', arguments: movie.id),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: posterUrl != null
                          ? CachedNetworkImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              width: 140,
                            )
                          : Container(color: Colors.grey[800]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "⭐ ${movie.voteAverage}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
