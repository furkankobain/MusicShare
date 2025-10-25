import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/user_follow.dart';
import '../../../../shared/models/music_list.dart';
import '../../../../shared/services/playlist_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class EnhancedProfilePage extends ConsumerStatefulWidget {
  const EnhancedProfilePage({super.key});

  @override
  ConsumerState<EnhancedProfilePage> createState() => _EnhancedProfilePageState();
}

class _EnhancedProfilePageState extends ConsumerState<EnhancedProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _playlistCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPlaylistCount();
  }

  Future<void> _loadPlaylistCount() async {
    final userId = FirebaseBypassAuthService.currentUserId;
    if (userId != null) {
      final count = await PlaylistService.getPlaylistCount(userId);
      if (mounted) {
        setState(() {
          _playlistCount = count;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
          // App Bar with Cover Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Image
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  context.push('/settings');
                },
              ),
            ],
          ),

          // Profile Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[900]! : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: Text(
                        'U',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    'Kullanıcı Adı',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Müzik tutkunu 🎵 | Letterboxd\'un müzik versiyonu',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Puanlama', '0', isDark),
                      _buildStatItem('Takipçi', '0', isDark),
                      _buildStatItem('Takip', '0', isDark),
                      _buildStatItem('Liste', _playlistCount.toString(), isDark, onTap: () {
                        _tabController.animateTo(2); // Navigate to Lists tab
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/settings');
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Profili Düzenle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            context.push('/settings');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                          child: Icon(
                            Icons.share,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                tabs: const [
                  Tab(icon: Icon(Icons.star), text: 'Puanlar'),
                  Tab(icon: Icon(Icons.book), text: 'Günlük'),
                  Tab(icon: Icon(Icons.list), text: 'Listeler'),
                  Tab(icon: Icon(Icons.favorite), text: 'Favoriler'),
                ],
              ),
              isDark,
            ),
          ),
        ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRatingsTab(isDark),
            _buildDiaryTab(isDark),
            _buildListsTab(isDark),
            _buildFavoritesTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildRatingsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz puanlama yok',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Günlük boş',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListsTab(bool isDark) {
    return StreamBuilder<List<MusicList>>(
      stream: PlaylistService.getUserPlaylists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.playlist_play,
                  size: 64,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz liste yok',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/user-playlists');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Playlist Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final playlists = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: playlists.length + 1, // +1 for "See All" button
          itemBuilder: (context, index) {
            if (index == playlists.length) {
              // "See All" button
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () {
                      context.push('/user-playlists');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      'Tüm Playlistleri Gör',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
              );
            }

            final playlist = playlists[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: playlist.coverImage != null
                      ? Image.network(
                          playlist.coverImage!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaylistPlaceholder(isDark),
                        )
                      : _buildPlaylistPlaceholder(isDark),
                ),
                title: Text(
                  playlist.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getSourceIcon(playlist.source),
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.trackIds.length} şarkı',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                onTap: () {
                  context.push('/playlist-detail', extra: playlist);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistPlaceholder(bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: 28,
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'spotify':
        return Icons.album;
      case 'synced':
        return Icons.sync;
      default:
        return Icons.folder;
    }
  }

  Widget _buildFavoritesTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Favori yok',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverAppBarDelegate(this._tabBar, this.isDark);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
