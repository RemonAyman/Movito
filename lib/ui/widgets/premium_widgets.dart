import 'package:flutter/material.dart';
import '../../data/models/movie.dart';
import '../../utils/constants.dart';
import 'movie_card.dart';

class PremiumSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSeeMore;

  const PremiumSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (onSeeMore != null)
            TextButton(
              onPressed: onSeeMore,
              child: const Text(
                "See More",
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumMovieRow extends StatelessWidget {
  final List<Movie> movies;
  final bool isLoading;
  final Function(Movie) onMovieTap;

  const PremiumMovieRow({
    super.key,
    required this.movies,
    required this.onMovieTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );
    }

    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            child: MovieCard(movie: movie, onClick: () => onMovieTap(movie)),
          );
        },
      ),
    );
  }
}
