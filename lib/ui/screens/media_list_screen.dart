import 'package:flutter/material.dart';
import '../../data/repositories/media_repository.dart';
import '../../utils/constants.dart';

class MediaListScreen extends StatefulWidget {
  final String title;
  final String collectionName;
  final String userId;

  const MediaListScreen({
    super.key,
    required this.title,
    required this.collectionName,
    required this.userId,
  });

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  final MediaRepository _repository = MediaRepository();
  List<MediaListItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final list = await _repository.getMediaList(
        widget.userId,
        widget.collectionName,
      );
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(String movieId) async {
    await _repository.removeFromMediaList(widget.collectionName, movieId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1330),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2A1B3D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : _items.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.67,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _MediaCard(
                  item: item,
                  isCurrentUser: widget.userId == _repository.currentUserId,
                  onRemove: () => _removeItem(item.movieId),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/details',
                    arguments: int.tryParse(item.movieId) ?? 0,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "Your ${widget.title.toLowerCase()} list is empty",
        style: const TextStyle(color: Colors.grey, fontSize: 18),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaListItem item;
  final bool isCurrentUser;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _MediaCard({
    required this.item,
    required this.isCurrentUser,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: isCurrentUser ? () => _showDeleteMenu(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.poster,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    item.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
              const Icon(Icons.favorite, color: Colors.white, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1330),
      builder: (context) => ListTile(
        leading: const Icon(Icons.delete, color: Colors.red),
        title: const Text(
          "Remove from list",
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          Navigator.pop(context);
          onRemove();
        },
      ),
    );
  }
}
