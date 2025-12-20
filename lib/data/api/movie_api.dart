import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../../utils/constants.dart';

class MovieApi {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.tmdbBaseUrl));

  Future<MovieResponse> getLatestMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/now_playing',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'en-US',
          'page': page,
        },
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieResponse> getPopularMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/popular',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'en-US',
          'page': page,
        },
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieResponse> getTopRatedMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/top_rated',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'en-US',
          'page': page,
        },
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieResponse> getUpcomingMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/upcoming',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'en-US',
          'page': page,
        },
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieResponse> searchMovies(String query) async {
    try {
      final response = await _dio.get(
        'search/movie',
        queryParameters: {'api_key': AppConstants.tmdbApiKey, 'query': query},
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Movie> getMovieDetails(int movieId) async {
    try {
      final response = await _dio.get(
        'movie/$movieId',
        queryParameters: {'api_key': AppConstants.tmdbApiKey},
      );
      return Movie.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<VideoResponse> getMovieVideos(int movieId) async {
    try {
      final response = await _dio.get(
        'movie/$movieId/videos',
        queryParameters: {'api_key': AppConstants.tmdbApiKey},
      );
      return VideoResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<CreditsResponse> getMovieCredits(int movieId) async {
    try {
      final response = await _dio.get(
        'movie/$movieId/credits',
        queryParameters: {'api_key': AppConstants.tmdbApiKey},
      );
      return CreditsResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
