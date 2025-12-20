import 'package:flutter/material.dart';
import '../../data/api/movie_api.dart';
import '../../data/models/movie.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SeeMoreScreen extends StatefulWidget {
  final String title;
  final String category; // 'popular', 'upcoming', 'top_rated'
  const SeeMoreScreen({super.key, required this.title, required this.category});

  @override
  State<SeeMoreScreen> createState() => _SeeMoreScreenState();
}

class _SeeMoreScreenState extends State<SeeMoreScreen> {
  final MovieApi _api = MovieApi();
  List<Movie> _movies = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      MovieResponse res;
      if (widget.category == 'popular') {
        res = await _api.getPopularMovies(page: _currentPage);
      } else if (widget.category == 'upcoming') {
        res = await _api.getUpcomingMovies(page: _currentPage);
      } else if (widget.category == 'top_rated') {
        res = await _api.getTopRatedMovies(page: _currentPage);
      } else {
        throw "Unknown category";
      }

      setState(() {
        _movies.addAll(res.results);
        _currentPage++;
        _isLoading = false;
        if (_currentPage > res.totalPages) _hasMore = false;
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A1B3D),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_movies.isEmpty && _isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    if (_errorMessage != null && _movies.isEmpty)
      return Center(
        child: Text(
          "Error: $_errorMessage",
          style: const TextStyle(color: Colors.white),
        ),
      );
    if (_movies.isEmpty)
      return const Center(
        child: Text("No movies found", style: TextStyle(color: Colors.grey)),
      );

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _fetchMovies();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.67,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: _movies.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _movies.length) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            );
          }
          final m = _movies[index];
          return _movieCard(m);
        },
      ),
    );
  }

  Widget _movieCard(Movie m) {
    final posterUrl = m.posterPath != null
        ? "https://image.tmdb.org/t/p/w200${m.posterPath}"
        : null;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/details', arguments: m.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF2A1B3D),
        ),
        clipBehavior: Clip.antiAlias,
        child: posterUrl != null
            ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover)
            : Container(color: Colors.grey[800]),
      ),
    );
  }
}
