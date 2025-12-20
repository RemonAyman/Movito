import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/api/movie_api.dart';
import '../../data/models/movie.dart';
import '../../utils/constants.dart';
import '../widgets/movie_card.dart';
import '../widgets/premium_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieApi _api = MovieApi();
  final TextEditingController _searchController = TextEditingController();

  List<Movie> _popularMovies = [];
  List<Movie> _upcomingMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _searchResults = [];

  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final popular = await _api.getPopularMovies();
      final upcoming = await _api.getUpcomingMovies();
      final topRated = await _api.getTopRatedMovies();

      setState(() {
        _popularMovies = popular.results;
        _upcomingMovies = upcoming.results;
        _topRatedMovies = topRated.results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final results = await _api.searchMovies(query);
      setState(() {
        _searchResults = results.results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      body: _isLoading && _popularMovies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSearchBox(),
                    ),
                  ),
                  if (_isSearching)
                    _buildSearchResults()
                  else if (_errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            "Error: $_errorMessage",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (_popularMovies.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _FeaturedMovieSection(
                          movie: _popularMovies.first,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: "Coming Soon",
                        subtitle: "Get ready for these releases",
                        movies: _upcomingMovies,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: "Trending Now",
                        subtitle: "What everyone's watching",
                        movies: _popularMovies,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        title: "Top Rated",
                        subtitle: "Top rated of all time",
                        movies: _topRatedMovies,
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a0933),
            Color(0xFF0d1b3d),
            AppColors.movitoBackground,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "MOVITO",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your Premium Entertainment Hub",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple,
                  AppColors.accentOrange,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search for a movie...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _handleSearch,
          ),
        ),
        if (_isSearching)
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.close, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final movie = _searchResults[index];
          return MovieCard(
            movie: movie,
            onClick: () =>
                Navigator.pushNamed(context, '/details', arguments: movie.id),
          );
        }, childCount: _searchResults.length),
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required String subtitle,
    required List<Movie> movies,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    String cat = "popular";
                    if (title == "Coming Soon") cat = "upcoming";
                    if (title == "Top Rated") cat = "top_rated";
                    Navigator.pushNamed(
                      context,
                      '/see_more',
                      arguments: {'title': title, 'category': cat},
                    );
                  },
                  child: const Text(
                    "See More",
                    style: TextStyle(color: AppColors.accentOrange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
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
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/details',
                    arguments: movie.id,
                  ),
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
                          style: const TextStyle(
                            color: Colors.white70,
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
      ),
    );
  }
}

class _FeaturedMovieSection extends StatelessWidget {
  final Movie movie;
  const _FeaturedMovieSection({required this.movie});

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.posterPath != null
        ? "https://image.tmdb.org/t/p/original${movie.posterPath}"
        : null;

    return Container(
      height: 550,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background blur
            if (posterUrl != null)
              CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),

            // Content
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: posterUrl != null
                          ? CachedNetworkImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.grey[800]),
                    ),
                  ),
                ),

                // Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.cardBackground.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "FEATURED",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/details',
                          arguments: movie.id,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Watch Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 46),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
