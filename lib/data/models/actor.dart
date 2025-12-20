class ActorSearchResponse {
  final List<Actor> results;

  ActorSearchResponse({required this.results});

  factory ActorSearchResponse.fromJson(Map<String, dynamic> json) {
    return ActorSearchResponse(
      results:
          (json['results'] as List?)?.map((e) => Actor.fromJson(e)).toList() ??
          [],
    );
  }
}

class Actor {
  final int id;
  final String name;
  final String? profilePath;
  final String? knownForDepartment;

  Actor({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownForDepartment,
  });

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      id: json['id'],
      name: json['name'] ?? '',
      profilePath: json['profile_path'],
      knownForDepartment: json['known_for_department'],
    );
  }
}

class ActorDetails {
  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? placeOfBirth;
  final String? profilePath;
  final double? popularity;

  ActorDetails({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    this.profilePath,
    this.popularity,
    this.knownForDepartment,
    this.movieCredits,
  });

  factory ActorDetails.fromJson(Map<String, dynamic> json) {
    return ActorDetails(
      id: json['id'],
      name: json['name'] ?? '',
      biography: json['biography'],
      birthday: json['birthday'],
      placeOfBirth: json['place_of_birth'],
      profilePath: json['profile_path'],
      popularity: (json['popularity'] as num?)?.toDouble(),
      knownForDepartment: json['known_for_department'],
      movieCredits: (json['movie_credits']?['cast'] as List?)
          ?.map((e) => MovieCredit.fromJson(e))
          .toList(),
    );
  }

  final String? knownForDepartment;
  final List<MovieCredit>? movieCredits;
}

class MovieCredit {
  final int id;
  final String title;
  final String? posterPath;
  final double voteAverage;
  final String? character;
  final String? releaseDate;

  MovieCredit({
    required this.id,
    required this.title,
    this.posterPath,
    required this.voteAverage,
    this.character,
    this.releaseDate,
  });

  factory MovieCredit.fromJson(Map<String, dynamic> json) {
    return MovieCredit(
      id: json['id'],
      title: json['title'] ?? '',
      posterPath: json['poster_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      character: json['character'],
      releaseDate: json['release_date'],
    );
  }
}
