import 'package:flutter/material.dart';
import '../../data/api/movie_api.dart';
import '../../data/models/tv_show.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TvShowDetailScreen extends StatefulWidget {
  final int tvId;
  const TvShowDetailScreen({super.key, required this.tvId});

  @override
  State<TvShowDetailScreen> createState() => _TvShowDetailScreenState();
}

class _TvShowDetailScreenState extends State<TvShowDetailScreen> {
  final MovieApi _api = MovieApi();
  TvShowDetails? _tvShow;
  bool _isLoading = true;
  String? _errorMessage;
  Season? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final tvShow = await _api.getTvShowDetails(widget.tvId);
      setState(() {
        _tvShow = tvShow;
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

  Future<void> _loadSeason(int seasonNumber) async {
    try {
      final season = await _api.getSeasonDetails(widget.tvId, seasonNumber);
      setState(() => _selectedSeason = season);
      _showEpisodesDialog();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading season: $e")));
    }
  }

  void _showEpisodesDialog() {
    if (_selectedSeason == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1330),
        title: Text(
          _selectedSeason!.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _selectedSeason!.episodes?.length ?? 0,
            itemBuilder: (context, index) {
              final ep = _selectedSeason!.episodes![index];
              return ListTile(
                leading: Text(
                  "${ep.episodeNumber}",
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(
                  ep.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: ep.overview != null
                    ? Text(
                        ep.overview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.movitoBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );
    }

    if (_errorMessage != null || _tvShow == null) {
      return Scaffold(
        backgroundColor: AppColors.movitoBackground,
        body: Center(
          child: Text(
            "Error: $_errorMessage",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final t = _tvShow!;
    final backdrop = t.backdropPath != null
        ? "https://image.tmdb.org/t/p/original${t.backdropPath}"
        : null;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(t, backdrop),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAndRating(t),
                  const SizedBox(height: 20),
                  _buildOverview(t),
                  const SizedBox(height: 24),
                  _buildInfo(t),
                  const SizedBox(height: 32),
                  _buildSeasons(t),
                  const SizedBox(height: 32),
                  _buildCast(t),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TvShowDetails t, String? backdrop) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            image: backdrop != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(backdrop),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.black26,
          ),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.movitoBackground],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(backgroundColor: Colors.black26),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndRating(TvShowDetails t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              t.voteAverage.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 16),
            Text(
              "${t.numberOfSeasons} Seasons • ${t.numberOfEpisodes} Episodes",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverview(TvShowDetails t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.overview ?? "No overview available",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(TvShowDetails t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Information",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _infoRow("Status", t.status ?? "Unknown"),
        _infoRow("Type", t.type ?? "Unknown"),
        _infoRow("First Air Date", t.firstAirDate ?? "Unknown"),
        _infoRow(
          "Genres",
          t.genres?.map((g) => g.name).join(", ") ?? "Unknown",
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasons(TvShowDetails t) {
    final seasons = t.seasons ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Seasons",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: seasons.length,
            itemBuilder: (context, index) {
              final s = seasons[index];
              final poster = s.posterPath != null
                  ? "https://image.tmdb.org/t/p/w200${s.posterPath}"
                  : null;
              return GestureDetector(
                onTap: () => _loadSeason(s.seasonNumber),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: poster != null
                            ? CachedNetworkImage(
                                imageUrl: poster,
                                height: 160,
                                fit: BoxFit.cover,
                              )
                            : Container(height: 160, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${s.episodeCount} Episodes",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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

  Widget _buildCast(TvShowDetails t) {
    final cast = t.credits?.cast ?? [];
    if (cast.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cast",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final c = cast[index];
              final profile = c.profilePath != null
                  ? "https://image.tmdb.org/t/p/w200${c.profilePath}"
                  : null;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/actor_details',
                  arguments: c.id,
                ),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: profile != null
                            ? CachedNetworkImageProvider(profile)
                            : null,
                        child: profile == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          overflow: TextOverflow.ellipsis,
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
}
