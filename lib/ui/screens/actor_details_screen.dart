import 'package:flutter/material.dart';
import '../../data/api/movie_api.dart';
import '../../data/models/actor.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ActorDetailsScreen extends StatefulWidget {
  final int actorId;
  const ActorDetailsScreen({super.key, required this.actorId});

  @override
  State<ActorDetailsScreen> createState() => _ActorDetailsScreenState();
}

class _ActorDetailsScreenState extends State<ActorDetailsScreen> {
  final MovieApi _api = MovieApi();
  ActorDetails? _actor;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final actor = await _api.getActorDetails(widget.actorId);
      setState(() {
        _actor = actor;
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

    if (_errorMessage != null || _actor == null) {
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

    final a = _actor!;
    final profileUrl = a.profilePath != null
        ? "https://image.tmdb.org/t/p/w500${a.profilePath}"
        : null;

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(a, profileUrl),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPersonalInfo(a),
                  const SizedBox(height: 24),
                  _buildBiography(a),
                  const SizedBox(height: 32),
                  _buildKnownFor(a),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ActorDetails a, String? profileUrl) {
    return Stack(
      children: [
        Container(
          height: 500,
          width: double.infinity,
          decoration: BoxDecoration(
            image: profileUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(profileUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey[900],
          ),
        ),
        Container(
          height: 500,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                AppColors.movitoBackground.withOpacity(0.7),
                AppColors.movitoBackground,
              ],
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
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (a.knownForDepartment != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a.knownForDepartment!,
                    style: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(ActorDetails a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Personal Info",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (a.birthday != null) _infoRow("Birthday", a.birthday!),
        if (a.placeOfBirth != null) _infoRow("Place of Birth", a.placeOfBirth!),
        if (a.popularity != null)
          _infoRow("Popularity", a.popularity!.toStringAsFixed(1)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiography(ActorDetails a) {
    if (a.biography == null || a.biography!.isEmpty)
      return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Biography",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          a.biography!,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildKnownFor(ActorDetails a) {
    final movies = a.movieCredits ?? [];
    if (movies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Known For",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final m = movies[index];
              final poster = m.posterPath != null
                  ? "https://image.tmdb.org/t/p/w200${m.posterPath}"
                  : null;
              return GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/details', arguments: m.id),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: poster != null
                            ? CachedNetworkImage(
                                imageUrl: poster,
                                height: 180,
                                fit: BoxFit.cover,
                              )
                            : Container(height: 180, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
}
