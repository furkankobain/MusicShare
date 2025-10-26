import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../reviews/presentation/pages/reviews_page.dart';
import '../../../albums/presentation/pages/albums_page.dart';
import '../../../discover/presentation/pages/enhanced_discover_page.dart';
import '../../../../shared/widgets/spotify/spotify_connect_button.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/spotify_service.dart';
import '../../../../shared/models/play_history.dart';

class MusicShareHomePage extends ConsumerStatefulWidget {
  const MusicShareHomePage({super.key});

  @override
  ConsumerState<MusicShareHomePage> createState() => _MusicShareHomePageState();
}

class _MusicShareHomePageState extends ConsumerState<MusicShareHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _turkeyTopTracks = [];
  List<Map<String, dynamic>> _turkeyTopAlbums = [];
  List<PlayHistory> _recentlyPlayed = [];
  bool _isLoadingTracks = true;
  bool _isLoadingAlbums = true;
  bool _isLoadingRecent = true;

  final List<String> _tabs = ['Şarkılar', 'Reviews', 'Albümler', 'Aktivite'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadTurkeyData();
  }

  Future<void> _loadTurkeyData() async {
    // Load Turkey top tracks
    if (mounted) {
      setState(() => _isLoadingTracks = true);
    }
    try {
      final tracks = await EnhancedSpotifyService.getTurkeyTopTracks();
      if (mounted) {
        setState(() {
          _turkeyTopTracks = tracks;
          _isLoadingTracks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTracks = false);
      }
    }
    
    // Load Turkey top albums
    if (mounted) {
      setState(() => _isLoadingAlbums = true);
    }
    try {
      final albums = await EnhancedSpotifyService.getTurkeyTopAlbums();
      if (mounted) {
        setState(() {
          _turkeyTopAlbums = albums;
          _isLoadingAlbums = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAlbums = false);
      }
    }

    // Load recently played
    if (mounted) {
      setState(() => _isLoadingRecent = true);
    }
    try {
      final tracks = await SpotifyService.getRecentlyPlayed(limit: 10);
      if (mounted) {
        setState(() {
          _recentlyPlayed = tracks.map((track) => PlayHistory.fromSpotify(track)).toList();
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
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
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              title: Row(
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    context.push('/search');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Notifications
                  },
                ),
              ],
            ),
            // Tab Bar - Letterboxd Style
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                ),
                isDark,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSongsTab(isDark),
            const ReviewsPage(),
            const AlbumsPage(),
            const EnhancedDiscoverPage(),
          ],
        ),
      ),
    );
  }

  // ŞARKILAR TAB - İlk sekme
  Widget _buildSongsTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Son Dinlenenler
            _buildSectionHeader(
              'Son Dinlenenler',
              isDark,
              onSeeAll: () {
                context.push('/recently-played');
              },
            ),
            const SizedBox(height: 12),
            _buildRecentlyPlayedSection(isDark),
            
            const SizedBox(height: 32),
            
            // Haftanın Popüler Şarkıları
            _buildSectionHeader(
              'Haftanın Popüler Şarkıları',
              isDark,
              onSeeAll: () {
                context.push('/turkey-top-tracks');
              },
            ),
            const SizedBox(height: 12),
            _buildPopularSongsSection(isDark),
            
            const SizedBox(height: 32),
            
            // Takip Ettiğim Kişilerin Aktiviteleri
            _buildSectionHeader(
              'Takip Ettiğim Kişiler',
              isDark,
              onSeeAll: () {
                context.push('/feed');
              },
            ),
            const SizedBox(height: 12),
            _buildFollowingActivitiesSection(isDark),
            
            const SizedBox(height: 32),
            
            // Popüler Albümler
            _buildSectionHeader(
              'Türkiye\'de Popüler Albümler',
              isDark,
              onSeeAll: () {
                context.push('/turkey-top-albums');
              },
            ),
            const SizedBox(height: 12),
            _buildPopularAlbumsSection(isDark),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title, bool isDark, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tümü',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Popüler Şarkılar Bölümü
  Widget _buildPopularSongsSection(bool isDark) {
    if (_isLoadingTracks) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    final tracksToShow = _turkeyTopTracks.take(10).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tracksToShow.length,
        itemBuilder: (context, index) {
          final track = tracksToShow[index];
          final artistName = (track['artists'] as List?)?.isNotEmpty == true
              ? track['artists'][0]['name']
              : 'Unknown Artist';
          final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
              ? track['album']['images'][0]['url']
              : null;
          
          return _buildSongCard(
            track,
            track['name'] ?? 'Unknown Track',
            artistName,
            isDark,
            rankBadge: '${index + 1}',
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  // Takip Edilen Kişilerin Aktiviteleri
  Widget _buildFollowingActivitiesSection(bool isDark) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildActivityCard(
            'Kullanıcı ${index + 1}',
            'Şarkı dinledi',
            'Şarkı Adı - Sanatçı',
            isDark,
          );
        },
      ),
    );
  }

  // Popüler Albümler Bölümü
  Widget _buildPopularAlbumsSection(bool isDark) {
    if (_isLoadingAlbums) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    final albumsToShow = _turkeyTopAlbums.take(10).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albumsToShow.length,
        itemBuilder: (context, index) {
          final album = albumsToShow[index];
          final artistName = (album['artists'] as List?)?.isNotEmpty == true
              ? album['artists'][0]['name']
              : 'Unknown Artist';
          final imageUrl = (album['images'] as List?)?.isNotEmpty == true
              ? album['images'][0]['url']
              : null;
          
          return _buildAlbumCard(
            album['name'] ?? 'Unknown Album',
            artistName,
            isDark,
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  // Şarkı Kartı
  Widget _buildSongCard(Map<String, dynamic> track, String title, String artist, bool isDark, {String? rankBadge, String? imageUrl}) {
    return GestureDetector(
      onTap: () {
        context.push('/track-detail', extra: track);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kapak ve Sıralama Badge
          Stack(
            children: [
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Icon(
                        Icons.music_note,
                        size: 50,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      )
                    : null,
              ),
              if (rankBadge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rankBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artist,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        ),
      ),
    );
  }

  // Son Dinlenenler Bölümü
  Widget _buildRecentlyPlayedSection(bool isDark) {
    if (_isLoadingRecent) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_recentlyPlayed.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 40,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Spotify\'ı bağlayın ve dinleme geçmişinizi görün',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recentlyPlayed.length,
        itemBuilder: (context, index) {
          final track = _recentlyPlayed[index];
          return _buildRecentlyPlayedCard(track, isDark);
        },
      ),
    );
  }

  // Son Dinlenenler Kartı
  Widget _buildRecentlyPlayedCard(PlayHistory track, bool isDark) {
    return GestureDetector(
      onTap: () {
        context.push('/track-detail', extra: {
          'trackId': track.trackId,
          'trackName': track.trackName,
          'artistName': track.artistName,
        });
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            // Album Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.albumImageUrl != null
                  ? Image.network(
                      track.albumImageUrl!,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderCover(isDark),
                    )
                  : _buildPlaceholderCover(isDark),
            ),
            const SizedBox(width: 12),
            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.trackName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artistName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        track.relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${track.formattedDuration}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(bool isDark) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        size: 32,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
    );
  }

  // Aktivite Kartı
  Widget _buildActivityCard(String username, String action, String content, bool isDark) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  username[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      action,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('0', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(width: 12),
              Icon(Icons.comment_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('0', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  // Albüm Kartı
  Widget _buildAlbumCard(String title, String artist, bool isDark, {String? imageUrl}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(
                    Icons.album,
                    size: 50,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artist,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '4.5',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _StickyTabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
