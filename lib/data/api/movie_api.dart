import 'package:dio/dio.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';
import '../models/actor.dart';
import '../../utils/constants.dart';

class MovieApi {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.tmdbBaseUrl));

  // ============ Movies APIs ============

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

  Future<MovieResponse> searchMovies(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'search/movie',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'query': query,
          'language': 'en-US',
          'page': page,
        },
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
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'append_to_response': 'credits,videos,similar',
        },
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

  Future<MovieResponse> getSimilarMovies(int movieId) async {
    try {
      final response = await _dio.get(
        'movie/$movieId/similar',
        queryParameters: {'api_key': AppConstants.tmdbApiKey},
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ TV Shows APIs ============

  Future<TvShowResponse> getPopularTvShows({int page = 1}) async {
    try {
      final response = await _dio.get(
        'tv/popular',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'en-US',
          'page': page,
        },
      );
      return TvShowResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TvShowResponse> getTopRatedTvShows({int page = 1}) async {
    try {
      final response = await _dio.get(
        'tv/top_rated',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'en-US',
          'page': page,
        },
      );
      return TvShowResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TvShowResponse> getOnTheAirTvShows({int page = 1}) async {
    try {
      final response = await _dio.get(
        'tv/on_the_air',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'en-US',
          'page': page,
        },
      );
      return TvShowResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TvShowResponse> searchTvShows(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'search/tv',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'query': query,
          'language': 'en-US',
          'page': page,
        },
      );
      return TvShowResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TvShowDetails> getTvShowDetails(int tvId) async {
    try {
      final response = await _dio.get(
        'tv/$tvId',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'append_to_response': 'credits,videos,similar',
        },
      );
      return TvShowDetails.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Season> getSeasonDetails(int tvId, int seasonNumber) async {
    try {
      final response = await _dio.get(
        'tv/$tvId/season/$seasonNumber',
        queryParameters: {'api_key': AppConstants.tmdbApiKey},
      );
      return Season.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Actor APIs ============

  Future<ActorSearchResponse> searchActors(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'search/person',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'query': query,
          'language': 'en-US',
          'page': page,
        },
      );
      return ActorSearchResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ActorDetails> getActorDetails(int personId) async {
    try {
      final response = await _dio.get(
        'person/$personId',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'append_to_response': 'movie_credits,tv_credits',
        },
      );
      return ActorDetails.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============ Special Categories ============

  Future<MovieResponse> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'discover/movie',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'with_genres': genreId,
          'page': page,
          'sort_by': 'popularity.desc',
        },
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieResponse> getAnimeMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'discover/movie',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'with_genres': 16, // Animation
          'with_original_language': 'ja', // Japanese
          'page': page,
          'sort_by': 'popularity.desc',
        },
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieResponse> getArabicMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'discover/movie',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': 'ar',
          'with_original_language': 'ar',
          'region': 'EG',
          'page': page,
          'sort_by': 'popularity.desc',
        },
      );
      return MovieResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
