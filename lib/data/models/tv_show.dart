class TvShowResponse {
  final int page;
  final List<TvShow> results;
  final int totalPages;
  final int totalResults;

  TvShowResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory TvShowResponse.fromJson(Map<String, dynamic> json) {
    return TvShowResponse(
      page: json['page'] ?? 0,
      results:
          (json['results'] as List?)?.map((e) => TvShow.fromJson(e)).toList() ??
          [],
      totalPages: json['total_pages'] ?? 0,
      totalResults: json['total_results'] ?? 0,
    );
  }
}

class TvShow {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double voteAverage;

  TvShow({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    required this.voteAverage,
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      id: json['id'],
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate: json['first_air_date'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TvShowDetails {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final String? lastAirDate;
  final double voteAverage;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<Season>? seasons;

  TvShowDetails({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.lastAirDate,
    required this.voteAverage,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.seasons,
    this.status,
    this.type,
    this.genres,
    this.networks,
    this.credits,
  });

  factory TvShowDetails.fromJson(Map<String, dynamic> json) {
    return TvShowDetails(
      id: json['id'],
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate: json['first_air_date'],
      lastAirDate: json['last_air_date'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
      status: json['status'],
      type: json['type'],
      genres: (json['genres'] as List?)?.map((e) => Genre.fromJson(e)).toList(),
      networks: (json['networks'] as List?)
          ?.map((e) => Network.fromJson(e))
          .toList(),
      seasons: (json['seasons'] as List?)
          ?.map((e) => Season.fromJson(e))
          .toList(),
      credits: json['credits'] != null
          ? TvCreditsResponse.fromJson(json['credits'])
          : null,
    );
  }

  final String? status;
  final String? type;
  final List<Genre>? genres;
  final List<Network>? networks;
  final TvCreditsResponse? credits;
}

class Genre {
  final int id;
  final String name;
  Genre({required this.id, required this.name});
  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: json['id'], name: json['name'] ?? '');
}

class Network {
  final int id;
  final String name;
  final String? logoPath;
  Network({required this.id, required this.name, this.logoPath});
  factory Network.fromJson(Map<String, dynamic> json) => Network(
    id: json['id'],
    name: json['name'] ?? '',
    logoPath: json['logo_path'],
  );
}

class TvCreditsResponse {
  final List<TvCast> cast;
  TvCreditsResponse({required this.cast});
  factory TvCreditsResponse.fromJson(Map<String, dynamic> json) =>
      TvCreditsResponse(
        cast:
            (json['cast'] as List?)?.map((e) => TvCast.fromJson(e)).toList() ??
            [],
      );
}

class TvCast {
  final int id;
  final String name;
  final String? profilePath;
  final String? character;
  TvCast({
    required this.id,
    required this.name,
    this.profilePath,
    this.character,
  });
  factory TvCast.fromJson(Map<String, dynamic> json) => TvCast(
    id: json['id'],
    name: json['name'] ?? '',
    profilePath: json['profile_path'],
    character: json['character'],
  );
}

class Season {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final int seasonNumber;
  final int episodeCount;

  Season({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    required this.seasonNumber,
    required this.episodeCount,
    this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      seasonNumber: json['season_number'] ?? 0,
      episodeCount: json['episode_count'] ?? 0,
      episodes: (json['episodes'] as List?)
          ?.map((e) => Episode.fromJson(e))
          .toList(),
    );
  }

  final List<Episode>? episodes;
}

class Episode {
  final int id;
  final String name;
  final String? overview;
  final int episodeNumber;
  final String? airDate;
  final String? stillPath;

  Episode({
    required this.id,
    required this.name,
    this.overview,
    required this.episodeNumber,
    this.airDate,
    this.stillPath,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      name: json['name'] ?? '',
      overview: json['overview'],
      episodeNumber: json['episode_number'] ?? 0,
      airDate: json['air_date'],
      stillPath: json['still_path'],
    );
  }
}
