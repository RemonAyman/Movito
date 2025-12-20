import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/api/movie_api.dart';
import '../../data/models/movie.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final MovieApi _api = MovieApi();
  Movie? _movie;
  String? _trailerKey;
  List<Cast> _cast = [];
  bool _isLoading = true;
  String? _errorMessage;

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

      setState(() {
        _movie = movie;
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
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
                Text(
                  "⭐ Rating: ${m.voteAverage}",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  m.overview,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (_trailerKey != null)
                  ElevatedButton.icon(
                    onPressed: _launchTrailer,
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text("Watch Trailer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                else
                  const Text(
                    "No trailer available",
                    style: TextStyle(color: Colors.white54),
                  ),
                const SizedBox(height: 24),
                const Text(
                  "Cast:",
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
                    itemCount: _cast.length,
                    itemBuilder: (context, index) {
                      final cast = _cast[index];
                      final profileUrl = cast.profilePath != null
                          ? "https://image.tmdb.org/t/p/w200${cast.profilePath}"
                          : null;
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: profileUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: profileUrl,
                                      width: 100,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 100,
                                      height: 120,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cast.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              cast.character,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
