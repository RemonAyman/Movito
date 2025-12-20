import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/api/movie_api.dart';
import '../../data/models/movie.dart';
import '../../data/repositories/media_repository.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final MovieApi _api = MovieApi();
  final MediaRepository _mediaRepo = MediaRepository();
  Movie? _movie;
  String? _trailerKey;
  List<Cast> _cast = [];
  List<Movie> _similarMovies = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _isFavorite = false;
  bool _isInWatchlist = false;
  bool _isWatched = false;
  double _userRating = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final movie = await _api.getMovieDetails(widget.movieId);
      final videos = await _api.getMovieVideos(widget.movieId);
      final credits = await _api.getMovieCredits(widget.movieId);
      final similar = await _api.getSimilarMovies(widget.movieId);

      if (_mediaRepo.currentUserId != null) {
        final uid = _mediaRepo.currentUserId!;
        final favs = await _mediaRepo.getMediaList(uid, 'favorites');
        final watchlist = await _mediaRepo.getMediaList(uid, 'watchlist');
        final watched = await _mediaRepo.getMediaList(uid, 'watched');
        final rating = await _mediaRepo.getRating(
          uid,
          widget.movieId.toString(),
        );

        setState(() {
          _isFavorite = favs.any(
            (item) => item.movieId == widget.movieId.toString(),
          );
          _isInWatchlist = watchlist.any(
            (item) => item.movieId == widget.movieId.toString(),
          );
          _isWatched = watched.any(
            (item) => item.movieId == widget.movieId.toString(),
          );
          _userRating = rating?.rating ?? 0.0;
        });
      }

      setState(() {
        _movie = movie;
        _similarMovies = similar.results;
        _trailerKey = videos.results
            .firstWhere(
              (v) => v.site == "YouTube" && v.type == "Trailer",
              orElse: () => videos.results.isNotEmpty
                  ? videos.results.first
                  : Video(key: "", name: "", site: "", type: ""),
            )
            .key;
        if (_trailerKey == "") _trailerKey = null;
        _cast = credits.cast.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final movie = _movie!;
    final item = MediaListItem(
      movieId: movie.id.toString(),
      title: movie.title,
      poster: "${AppConstants.imageBaseUrl}${movie.posterPath}",
      rating: 0,
      voteAverage: movie.voteAverage,
    );
    if (_isFavorite) {
      await _mediaRepo.removeFromMediaList('favorites', item.movieId);
    } else {
      await _mediaRepo.addToMediaList('favorites', item);
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _toggleWatchlist() async {
    final movie = _movie!;
    final item = MediaListItem(
      movieId: movie.id.toString(),
      title: movie.title,
      poster: "${AppConstants.imageBaseUrl}${movie.posterPath}",
      rating: 0,
      voteAverage: movie.voteAverage,
    );
    if (_isInWatchlist) {
      await _mediaRepo.removeFromMediaList('watchlist', item.movieId);
    } else {
      await _mediaRepo.addToMediaList('watchlist', item);
    }
    setState(() => _isInWatchlist = !_isInWatchlist);
  }

  Future<void> _toggleWatched() async {
    final movie = _movie!;
    final item = MediaListItem(
      movieId: movie.id.toString(),
      title: movie.title,
      poster: "${AppConstants.imageBaseUrl}${movie.posterPath}",
      rating: 0,
      voteAverage: movie.voteAverage,
    );
    if (_isWatched) {
      await _mediaRepo.removeFromMediaList('watched', item.movieId);
    } else {
      await _mediaRepo.addToMediaList('watched', item);
    }
    setState(() => _isWatched = !_isWatched);
  }

  Future<void> _setRating(double rating) async {
    final movie = _movie!;
    final item = RatingItem(
      movieId: movie.id.toString(),
      title: movie.title,
      poster: "${AppConstants.imageBaseUrl}${movie.posterPath}",
      rating: rating,
      voteAverage: movie.voteAverage,
      review: "",
      ratedDate: DateTime.now().millisecondsSinceEpoch,
    );
    await _mediaRepo.addRating(item);
    setState(() => _userRating = rating);
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareSheet(movie: _movie!),
    );
  }

  void _launchTrailer() async {
    if (_trailerKey != null) {
      final url = Uri.parse("https://www.youtube.com/watch?v=$_trailerKey");
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.movitoBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _movie == null) {
      return Scaffold(
        backgroundColor: AppColors.movitoBackground,
        body: Center(
          child: Text(
            "Error: ${_errorMessage ?? "Movie not found"}",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final m = _movie!;
    final posterUrl = m.posterPath != null
        ? "${AppConstants.imageBaseUrl}${m.posterPath}"
        : null;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.movitoBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: posterUrl != null
                  ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey[800]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildActionRow(),
                const SizedBox(height: 16),
                _buildRatingSection(),
                const SizedBox(height: 24),
                Text(
                  m.overview,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (_trailerKey != null)
                  _buildTrailerButton()
                else
                  const Text(
                    "No trailer available",
                    style: TextStyle(color: Colors.white54),
                  ),
                const SizedBox(height: 24),
                _buildCastList(),
                const SizedBox(height: 24),
                _buildSimilarMovies(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
          label: "Fav",
          color: _isFavorite ? Colors.red : Colors.white,
          onTap: _toggleFavorite,
        ),
        _ActionButton(
          icon: _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
          label: "Watchlist",
          color: _isInWatchlist ? Colors.blue : Colors.white,
          onTap: _toggleWatchlist,
        ),
        _ActionButton(
          icon: _isWatched ? Icons.check_circle : Icons.check_circle_outline,
          label: "Watched",
          color: _isWatched ? Colors.green : Colors.white,
          onTap: _toggleWatched,
        ),
        _ActionButton(
          icon: Icons.share,
          label: "Share",
          color: Colors.white,
          onTap: _showShareSheet,
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        const Text(
          "Your Rating",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        RatingBar.builder(
          initialRating: _userRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 10,
          itemSize: 24,
          itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
          itemBuilder: (context, _) =>
              const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: _setRating,
        ),
      ],
    );
  }

  Widget _buildTrailerButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Colors.red, Color(0xFFB71C1C)]),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _launchTrailer,
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text(
          "Watch Trailer",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCastList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cast",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _cast.length,
            itemBuilder: (context, index) {
              final cast = _cast[index];
              final profileUrl = cast.profilePath != null
                  ? "https://image.tmdb.org/t/p/w200${cast.profilePath}"
                  : null;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/actor_details',
                  arguments: cast.id,
                ),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: profileUrl != null
                            ? CachedNetworkImageProvider(profileUrl)
                            : null,
                        child: profileUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cast.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarMovies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Similar Movies",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _similarMovies.length,
            itemBuilder: (context, index) {
              final m = _similarMovies[index];
              final poster = m.posterPath != null
                  ? "https://image.tmdb.org/t/p/w200${m.posterPath}"
                  : null;
              return GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/details',
                  arguments: m.id,
                ),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: poster != null
                        ? CachedNetworkImage(
                            imageUrl: poster,
                            fit: BoxFit.cover,
                          )
                        : Container(color: Colors.grey[800]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ShareSheet extends StatefulWidget {
  final Movie movie;
  const _ShareSheet({required this.movie});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final MediaRepository _repo = MediaRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final uid = _repo.currentUserId;
    if (uid == null) return;
    final snapshot = await _db
        .collection('chats')
        .where('members', arrayContains: uid)
        .get();

    final List<Map<String, dynamic>> temp = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final id = doc.id;
      final isGroup = data['isGroup'] ?? false;
      final members = List<String>.from(data['members'] ?? []);

      String name = "Chat";
      String? avatar;

      if (isGroup) {
        name = data['name'] ?? "Group";
      } else {
        final otherId = members.firstWhere((m) => m != uid, orElse: () => "");
        if (otherId.isNotEmpty) {
          final userDoc = await _db.collection('users').doc(otherId).get();
          name = userDoc.data()?['username'] ?? "User";
          avatar = userDoc.data()?['avatarBase64'];
        }
      }
      temp.add({'id': id, 'name': name, 'avatar': avatar, 'isGroup': isGroup});
    }

    setState(() {
      _chats = temp;
      _isLoading = false;
    });
  }

  Future<void> _shareTo(String chatId) async {
    final uid = _repo.currentUserId;
    final movie = widget.movie;

    final msgData = {
      'text': '🎬 Shared a movie',
      'senderId': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'movieId': movie.id.toString(),
      'movieTitle': movie.title,
      'moviePoster': "${AppConstants.imageBaseUrl}${movie.posterPath}",
      'movieRating': movie.voteAverage,
      'isSharedMovie': true,
    };

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(msgData);
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': '🎬 Shared: ${movie.title}',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _chats
        .where(
          (c) => c['name'].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          ),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1330),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Share Movie",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _searchText = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search chats...",
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.primaryPurple,
              ),
              filled: true,
              fillColor: const Color(0xFF2A1B3D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final chat = filtered[index];
                      return ListTile(
                        onTap: () => _shareTo(chat['id']),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryPurple.withOpacity(
                            0.2,
                          ),
                          backgroundImage: chat['avatar'] != null
                              ? MemoryImage(base64Decode(chat['avatar']))
                              : null,
                          child: chat['avatar'] == null
                              ? Icon(
                                  chat['isGroup'] ? Icons.group : Icons.person,
                                  color: AppColors.primaryPurple,
                                )
                              : null,
                        ),
                        title: Text(
                          chat['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          chat['isGroup'] ? "Group Chat" : "Private Chat",
                          style: const TextStyle(color: Colors.grey),
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
