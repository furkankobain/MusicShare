import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/track_card.dart';

class DiscoverSearchPage extends ConsumerStatefulWidget {
  const DiscoverSearchPage({super.key});

  @override
  ConsumerState<DiscoverSearchPage> createState() => _DiscoverSearchPageState();
}

class _DiscoverSearchPageState extends ConsumerState<DiscoverSearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isSearching = false;
  List<Map<String, dynamic>> _musicResults = [];
  List<Map<String, dynamic>> _reviewResults = [];
  List<Map<String, dynamic>> _listResults = [];
  List<Map<String, dynamic>> _userResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);

    try {
      // Search music (tracks + albums + artists)
      final musicResults = await EnhancedSpotifyService.search(
        query: query,
        types: ['track', 'album', 'artist'],
        limit: 20,
      );

      if (mounted) {
        final tracks = (musicResults['tracks']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final albums = (musicResults['albums']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final artists = (musicResults['artists']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        setState(() {
          _musicResults = [...tracks, ...albums, ...artists];
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ModernDesignSystem.darkBackground : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Search music, artists, albums, users...',
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _musicResults.clear();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isNotEmpty) {
              _performSearch(value);
            }
          },
          onSubmitted: _performSearch,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ModernDesignSystem.accentPurple,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          indicatorColor: ModernDesignSystem.accentPurple,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Music'),
            Tab(text: 'Reviews'),
            Tab(text: 'Lists'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMusicTab(isDark),
          _buildReviewsTab(isDark),
          _buildListsTab(isDark),
          _buildUsersTab(isDark),
        ],
      ),
    );
  }

  Widget _buildMusicTab(bool isDark) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Start typing to search music...', Icons.music_note, isDark);
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_musicResults.isEmpty) {
      return _buildEmptyState('No results found', Icons.search_off, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _musicResults.length,
      itemBuilder: (context, index) {
        final item = _musicResults[index];
        final type = item['type'] as String?;

        if (type == 'track') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TrackCard(track: item),
          );
        } else if (type == 'album') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AlbumCard(album: item),
          );
        } else if (type == 'artist') {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: item['images'] != null && (item['images'] as List).isNotEmpty
                  ? NetworkImage((item['images'] as List)[0]['url'])
                  : null,
              child: item['images'] == null || (item['images'] as List).isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              item['name'] ?? 'Unknown Artist',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Artist',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            onTap: () => context.push('/artist/${item['id']}'),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    return _buildEmptyState('Reviews search coming soon...', Icons.rate_review, isDark);
  }

  Widget _buildListsTab(bool isDark) {
    return _buildEmptyState('Lists search coming soon...', Icons.list, isDark);
  }

  Widget _buildUsersTab(bool isDark) {
    return _buildEmptyState('Users search coming soon...', Icons.people, isDark);
  }

  Widget _buildEmptyState(String message, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
