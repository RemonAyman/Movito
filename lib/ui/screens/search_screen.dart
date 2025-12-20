import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../data/api/movie_api.dart';
import '../../data/models/movie.dart';
import '../../data/models/tv_show.dart';
import '../../data/models/actor.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum SearchCategory { movies, tvShows, actors }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MovieApi _api = MovieApi();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _searchController = TextEditingController();

  SearchCategory _selectedCategory = SearchCategory.movies;
  List<Movie> _movieResults = [];
  List<TvShow> _tvResults = [];
  List<Actor> _actorResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    await prefs.setStringList('recentSearches', _recentSearches);
    setState(() {});
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    _saveRecentSearch(query);

    try {
      if (_selectedCategory == SearchCategory.movies) {
        final res = await _api.searchMovies(query);
        setState(() => _movieResults = res.results);
      } else if (_selectedCategory == SearchCategory.tvShows) {
        final res = await _api.searchTvShows(query);
        setState(() => _tvResults = res.results);
      } else {
        final res = await _api.searchActors(query);
        setState(() => _actorResults = res.results);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Search failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              if (val.finalResult) {
                _isListening = false;
                _search(val.recognizedWords);
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Search",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildCategoryFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onSubmitted: _search,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search movies, shows, stars...",
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
        suffixIcon: IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : Colors.white,
          ),
          onPressed: _listen,
        ),
        filled: true,
        fillColor: const Color(0xFF2A1B3D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _categoryChip("Movies", SearchCategory.movies),
        _categoryChip("TV Shows", SearchCategory.tvShows),
        _categoryChip("Actors", SearchCategory.actors),
      ],
    );
  }

  Widget _categoryChip(String label, SearchCategory category) {
    bool isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() {
        _selectedCategory = category;
        if (_searchController.text.isNotEmpty) _search(_searchController.text);
      }),
      backgroundColor: const Color(0xFF2A1B3D),
      selectedColor: AppColors.primaryPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildResults() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );

    if (_searchController.text.isEmpty &&
        _movieResults.isEmpty &&
        _tvResults.isEmpty &&
        _actorResults.isEmpty) {
      return _buildRecentSearches();
    }

    if (_selectedCategory == SearchCategory.movies) {
      return ListView.builder(
        itemCount: _movieResults.length,
        itemBuilder: (context, index) => _movieItem(_movieResults[index]),
      );
    } else if (_selectedCategory == SearchCategory.tvShows) {
      return ListView.builder(
        itemCount: _tvResults.length,
        itemBuilder: (context, index) => _tvItem(_tvResults[index]),
      );
    } else {
      return ListView.builder(
        itemCount: _actorResults.length,
        itemBuilder: (context, index) => _actorItem(_actorResults[index]),
      );
    }
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty)
      return const Center(
        child: Text("Start searching...", style: TextStyle(color: Colors.grey)),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Searches",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _recentSearches
              .map(
                (s) => InkWell(
                  onTap: () {
                    _searchController.text = s;
                    _search(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1B3D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _movieItem(Movie m) {
    return ListTile(
      onTap: () => Navigator.pushNamed(context, '/details', arguments: m.id),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: m.posterPath != null
            ? CachedNetworkImage(
                imageUrl: "https://image.tmdb.org/t/p/w200${m.posterPath}",
                width: 50,
                height: 75,
                fit: BoxFit.cover,
              )
            : Container(width: 50, height: 75, color: Colors.grey[800]),
      ),
      title: Text(
        m.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        m.releaseDate ?? "",
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _tvItem(TvShow t) {
    return ListTile(
      onTap: () => Navigator.pushNamed(context, '/tv_details', arguments: t.id),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: t.posterPath != null
            ? CachedNetworkImage(
                imageUrl: "https://image.tmdb.org/t/p/w200${t.posterPath}",
                width: 50,
                height: 75,
                fit: BoxFit.cover,
              )
            : Container(width: 50, height: 75, color: Colors.grey[800]),
      ),
      title: Text(
        t.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        t.firstAirDate ?? "",
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _actorItem(Actor a) {
    return ListTile(
      onTap: () =>
          Navigator.pushNamed(context, '/actor_details', arguments: a.id),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[800],
        backgroundImage: a.profilePath != null
            ? CachedNetworkImageProvider(
                "https://image.tmdb.org/t/p/w200${a.profilePath}",
              )
            : null,
        child: a.profilePath == null
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        a.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        a.knownForDepartment ?? "",
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
