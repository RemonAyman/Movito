import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/chat_repository.dart';
import '../../utils/constants.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final ChatRepository _repository = ChatRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _groupName = "";
  String _searchText = "";
  List<Map<String, dynamic>> _friends = [];
  final Set<String> _selectedUids = {};
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final currentUid = _repository.currentUserId;
      final snapshot = await _db.collection('users').get();
      final list = snapshot.docs
          .where((doc) => doc.id != currentUid)
          .map((doc) => doc.data()..['uid'] = doc.id)
          .toList();
      setState(() {
        _friends = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroup() async {
    if (_groupName.isEmpty || _selectedUids.isEmpty) return;
    setState(() => _isCreating = true);
    try {
      final currentUid = _repository.currentUserId;
      final members = (_selectedUids.toList()..add(currentUid!));

      final docRef = await _db.collection('chats').add({
        'name': _groupName,
        'isGroup': true,
        'members': members,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unread': 0,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/chat_detail',
          arguments: docRef.id,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;
    final selectedFriends = _friends
        .where((f) => _selectedUids.contains(f['uid']))
        .toList();
    final filteredFriends = _friends.where((f) {
      final name = (f['username'] ?? "").toString().toLowerCase();
      return name.contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.movitoBackground,
      appBar: AppBar(
        title: const Text(
          'Create New Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B1330),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildGroupNameInput(),
          if (selectedFriends.isNotEmpty)
            _buildSelectedMembersRow(selectedFriends),
          _buildSearchInput(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: purple))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredFriends.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      final isSelected = _selectedUids.contains(friend['uid']);
                      return _FriendCard(
                        friend: friend,
                        isSelected: isSelected,
                        onClick: () {
                          setState(() {
                            if (isSelected)
                              _selectedUids.remove(friend['uid']);
                            else
                              _selectedUids.add(friend['uid']);
                          });
                        },
                      );
                    },
                  ),
          ),
          _buildCreateButton(purple),
        ],
      ),
    );
  }

  Widget _buildGroupNameInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1330),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryPurple, Color(0xFF6930C3)],
                ),
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _groupName = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter group name...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2A1B3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMembersRow(List<Map<String, dynamic>> selected) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Selected Members",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${selected.length}",
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selected.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final friend = selected[index];
                return _SelectedChip(
                  name: friend['username'] ?? "?",
                  avatarBase64: friend['avatarBase64'] ?? "",
                  onRemove: () =>
                      setState(() => _selectedUids.remove(friend['uid'])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (val) => setState(() => _searchText = val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search friends...",
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryPurple),
          filled: true,
          fillColor: const Color(0xFF1B1330),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(Color purple) {
    bool enabled =
        _groupName.isNotEmpty && _selectedUids.isNotEmpty && !_isCreating;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: enabled ? _createGroup : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          disabledBackgroundColor: purple.withOpacity(0.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isCreating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    "Create Group",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final String name;
  final String avatarBase64;
  final VoidCallback onRemove;

  const _SelectedChip({
    required this.name,
    required this.avatarBase64,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Stack(
            children: [
              _Avatar(avatarBase64: avatarBase64, name: name, size: 56),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Map<String, dynamic> friend;
  final bool isSelected;
  final VoidCallback onClick;

  const _FriendCard({
    required this.friend,
    required this.isSelected,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final name = friend['username'] ?? "User";
    final avatarBase64 = friend['avatarBase64'] ?? "";
    const purple = AppColors.primaryPurple;

    return InkWell(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A1B3D) : const Color(0xFF1B1330),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(avatarBase64: avatarBase64, name: name, size: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? purple : const Color(0xFF2A1B3D),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatarBase64;
  final String name;
  final double size;

  const _Avatar({
    required this.avatarBase64,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.primaryPurple;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [purple.withOpacity(0.3), const Color(0xFF2A1B3D)],
        ),
      ),
      child: ClipOval(
        child: avatarBase64.isNotEmpty
            ? Image.memory(base64Decode(avatarBase64), fit: BoxFit.cover)
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: purple,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}
