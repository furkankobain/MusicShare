import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/modern_design_system.dart';
import '../../shared/models/music_list.dart';

class SmartPlaylistsPage extends StatefulWidget {
  const SmartPlaylistsPage({super.key});

  @override
  State<SmartPlaylistsPage> createState() => _SmartPlaylistsPageState();
}

class _SmartPlaylistsPageState extends State<SmartPlaylistsPage> {
  bool _isLoading = true;
  List<SmartPlaylist> _smartPlaylists = [];

  @override
  void initState() {
    super.initState();
    _generateSmartPlaylists();
  }

  Future<void> _generateSmartPlaylists() async {
    setState(() => _isLoading = true);

    // Simulate generation
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _smartPlaylists = [
        // Mood-based playlists
        SmartPlaylist(
          id: 'mood_energetic',
          title: '⚡ Enerjik',
          description: 'Yüksek enerjili ve tempolu şarkılar',
          icon: Icons.flash_on,
          color: Colors.orange,
          trackCount: 32,
          criteria: 'Enerji > 80, Tempo > 120 BPM',
          type: SmartPlaylistType.mood,
        ),
        SmartPlaylist(
          id: 'mood_chill',
          title: '😌 Sakin',
          description: 'Rahatlatıcı ve huzur veren şarkılar',
          icon: Icons.spa,
          color: Colors.blue,
          trackCount: 28,
          criteria: 'Enerji < 40, Tempo < 100 BPM',
          type: SmartPlaylistType.mood,
        ),
        SmartPlaylist(
          id: 'mood_happy',
          title: '😊 Mutlu',
          description: 'Pozitif ve neşeli şarkılar',
          icon: Icons.sentiment_satisfied_alt,
          color: Colors.yellow.shade700,
          trackCount: 25,
          criteria: 'Valence > 70, Danceability > 60',
          type: SmartPlaylistType.mood,
        ),
        SmartPlaylist(
          id: 'mood_focus',
          title: '🎯 Konsantrasyon',
          description: 'Çalışma ve odaklanma için',
          icon: Icons.headphones,
          color: Colors.purple,
          trackCount: 40,
          criteria: 'Instrumentalness > 50, Speech < 20',
          type: SmartPlaylistType.mood,
        ),

        // Genre-based playlists
        SmartPlaylist(
          id: 'genre_rock',
          title: '🎸 Rock Koleksiyonu',
          description: 'Tüm rock şarkıların',
          icon: Icons.music_note,
          color: Colors.red,
          trackCount: 45,
          criteria: 'Genre: Rock, Alternative Rock, Hard Rock',
          type: SmartPlaylistType.genre,
        ),
        SmartPlaylist(
          id: 'genre_pop',
          title: '🎤 Pop Favorileri',
          description: 'En sevilen pop şarkılar',
          icon: Icons.stars,
          color: Colors.pink,
          trackCount: 38,
          criteria: 'Genre: Pop, Dance Pop, Electropop',
          type: SmartPlaylistType.genre,
        ),
        SmartPlaylist(
          id: 'genre_hiphop',
          title: '🎧 Hip Hop & Rap',
          description: 'Hip hop ve rap koleksiyonu',
          icon: Icons.graphic_eq,
          color: Colors.deepPurple,
          trackCount: 30,
          criteria: 'Genre: Hip Hop, Rap, Trap',
          type: SmartPlaylistType.genre,
        ),

        // Decade-based playlists
        SmartPlaylist(
          id: 'decade_90s',
          title: '📼 90\'lar Nostalji',
          description: '1990-1999 arası çıkan şarkılar',
          icon: Icons.history,
          color: Colors.teal,
          trackCount: 35,
          criteria: 'Release Date: 1990-1999',
          type: SmartPlaylistType.decade,
        ),
        SmartPlaylist(
          id: 'decade_2000s',
          title: '💿 2000\'ler',
          description: '2000-2009 arası çıkan şarkılar',
          icon: Icons.album,
          color: Colors.green,
          trackCount: 42,
          criteria: 'Release Date: 2000-2009',
          type: SmartPlaylistType.decade,
        ),
        SmartPlaylist(
          id: 'decade_2010s',
          title: '📱 2010\'lar',
          description: '2010-2019 arası çıkan şarkılar',
          icon: Icons.queue_music,
          color: Colors.indigo,
          trackCount: 50,
          criteria: 'Release Date: 2010-2019',
          type: SmartPlaylistType.decade,
        ),

        // Activity-based
        SmartPlaylist(
          id: 'activity_workout',
          title: '💪 Spor',
          description: 'Antrenman için motivasyon',
          icon: Icons.fitness_center,
          color: Colors.red.shade700,
          trackCount: 30,
          criteria: 'Tempo > 140 BPM, Energy > 80',
          type: SmartPlaylistType.activity,
        ),
        SmartPlaylist(
          id: 'activity_party',
          title: '🎉 Parti',
          description: 'Parti ve eğlence için',
          icon: Icons.celebration,
          color: Colors.deepOrange,
          trackCount: 35,
          criteria: 'Danceability > 70, Energy > 75',
          type: SmartPlaylistType.activity,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? ModernDesignSystem.darkBackground
          : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Akıllı Çalma Listeleri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark
            ? ModernDesignSystem.darkBackground
            : ModernDesignSystem.lightBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateSmartPlaylists,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showInfoDialog(context, isDark),
            tooltip: 'Bilgi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _generateSmartPlaylists,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Otomatik Oluşturulan Listeler',
                      style: TextStyle(
                        fontSize: ModernDesignSystem.fontSizeL,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mood Section
                    _buildSection('Ruh Hali', SmartPlaylistType.mood, isDark),
                    const SizedBox(height: 24),

                    // Genre Section
                    _buildSection('Türler', SmartPlaylistType.genre, isDark),
                    const SizedBox(height: 24),

                    // Decade Section
                    _buildSection('Dönemler', SmartPlaylistType.decade, isDark),
                    const SizedBox(height: 24),

                    // Activity Section
                    _buildSection('Aktiviteler', SmartPlaylistType.activity, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, SmartPlaylistType type, bool isDark) {
    final playlists = _smartPlaylists.where((p) => p.type == type).toList();

    if (playlists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ModernDesignSystem.fontSizeXL,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            return _buildPlaylistCard(playlists[index], isDark);
          },
        ),
      ],
    );
  }

  Widget _buildPlaylistCard(SmartPlaylist playlist, bool isDark) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to playlist detail or generate actual playlist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${playlist.title} oluşturuluyor...'),
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {},
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              playlist.color.withValues(alpha: 0.8),
              playlist.color.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
          boxShadow: [
            BoxShadow(
              color: playlist.color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                playlist.icon,
                size: 120,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    playlist.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                  const Spacer(),
                  Text(
                    playlist.title,
                    style: const TextStyle(
                      fontSize: ModernDesignSystem.fontSizeL,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.trackCount} şarkı',
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeS,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.description,
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeXS,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akıllı Çalma Listeleri'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Akıllı çalma listeleri, dinleme alışkanlıklarınıza ve müzik kütüphanenize göre otomatik olarak oluşturulur.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildInfoItem('🎭 Ruh Hali', 'Şarkıların enerji ve tempo değerlerine göre'),
              _buildInfoItem('🎵 Türler', 'Sevdiğiniz müzik türlerine göre'),
              _buildInfoItem('📅 Dönemler', 'Şarkıların çıkış tarihlerine göre'),
              _buildInfoItem('🏃 Aktiviteler', 'Farklı aktiviteler için optimize edilmiş'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum SmartPlaylistType {
  mood,
  genre,
  decade,
  activity,
}

class SmartPlaylist {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int trackCount;
  final String criteria;
  final SmartPlaylistType type;

  SmartPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.trackCount,
    required this.criteria,
    required this.type,
  });
}
