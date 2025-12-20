import 'package:flutter/material.dart';
import '../../data/models/movie.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onClick;

  const MovieCard({super.key, required this.movie, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final imageUrl = movie.posterPath != null
        ? "${AppConstants.imageBaseUrl}${movie.posterPath}"
        : null;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.cardBackground,
      shape: RoundedCornerShape(12),
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, size: 50),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "⭐ ${movie.voteAverage}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for RoundedCornerShape which is missing in my manual typing
class RoundedCornerShape extends RoundedRectangleBorder {
  RoundedCornerShape(double radius)
    : super(borderRadius: BorderRadius.circular(radius));
}
