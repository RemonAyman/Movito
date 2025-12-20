class MovieResponse {
  final List<Movie> results;

  MovieResponse({required this.results});

  factory MovieResponse.fromJson(Map<String, dynamic> json) {
    return MovieResponse(
      results: (json['results'] as List).map((i) => Movie.fromJson(i)).toList(),
    );
  }
}

class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final double voteAverage;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    required this.overview,
    required this.voteAverage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      overview: json['overview'],
      voteAverage: (json['vote_average'] as num).toDouble(),
    );
  }
}

class VideoResponse {
  final List<Video> results;

  VideoResponse({required this.results});

  factory VideoResponse.fromJson(Map<String, dynamic> json) {
    return VideoResponse(
      results: (json['results'] as List).map((i) => Video.fromJson(i)).toList(),
    );
  }
}

class Video {
  final String key;
  final String name;
  final String site;
  final String type;

  Video({
    required this.key,
    required this.name,
    required this.site,
    required this.type,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      key: json['key'],
      name: json['name'],
      site: json['site'],
      type: json['type'],
    );
  }
}

class CreditsResponse {
  final List<Cast> cast;

  CreditsResponse({required this.cast});

  factory CreditsResponse.fromJson(Map<String, dynamic> json) {
    return CreditsResponse(
      cast: (json['cast'] as List).map((i) => Cast.fromJson(i)).toList(),
    );
  }
}

class Cast {
  final String name;
  final String character;
  final String? profilePath;

  Cast({required this.name, required this.character, this.profilePath});

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      name: json['name'],
      character: json['character'],
      profilePath: json['profile_path'],
    );
  }
}
