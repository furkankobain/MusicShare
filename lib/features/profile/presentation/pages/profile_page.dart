import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/enhanced_auth_service.dart';
import '../../../music/presentation/pages/my_ratings_page.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, ref),
            
            const SizedBox(height: 24),
            
            // Stats Section
            _buildStatsSection(context),
            
            const SizedBox(height: 24),
            
            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: Column(
                children: [
                  _buildMenuSection(context, 'Kütüphane', [
                    _buildMenuItem(
                      context,
                      icon: Icons.favorite,
                      title: 'Liked Songs',
                      subtitle: '89 songs',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.album,
                      title: 'My Albums',
                      subtitle: '43 albums',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.playlist_play,
                      title: 'Çalma Listeleri',
                      subtitle: '12 playlists',
                      onTap: () {},
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection(context, 'Aktivite', [
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      title: 'Listening History',
                      subtitle: 'View your music journey',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.star,
                      title: 'Puanlamalarım',
                      subtitle: 'Tüm müzik puanlamalarınız',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyRatingsPage(),
                        ),
                      ),
                    ),
      _buildMenuItem(
        context,
        icon: Icons.analytics,
        title: 'İstatistiklerim',
        subtitle: 'Dinleme istatistiklerinizi görün',
        onTap: () => Navigator.pushNamed(context, '/statistics'),
      ),
      _buildMenuItem(
        context,
        icon: Icons.settings,
        title: 'Ayarlar',
        subtitle: 'Uygulama ayarlarını yönetin',
        onTap: () => Navigator.pushNamed(context, '/settings'),
      ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection(context, 'Sosyal', [
                    _buildMenuItem(
                      context,
                      icon: Icons.people,
                      title: 'Takip Edilenler',
                      subtitle: '45 friends',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.group,
                      title: 'Takipçiler',
                      subtitle: '128 followers',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.share,
                      title: 'Share Profile',
                      subtitle: 'Invite friends',
                      onTap: () {},
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection(context, 'Ayarlar', [
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications,
                      title: 'Bildirimler',
                      subtitle: 'Bildirim ayarlarınızı yönetin',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsPage(),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip,
                      title: 'Privacy',
                      subtitle: 'Control your data',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.help,
                      title: 'Help & Support',
                      subtitle: 'Get assistance',
                      onTap: () {},
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          StreamBuilder(
            stream: EnhancedAuthService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Text(
                user?.displayName ?? 'Music Lover',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
          
          const SizedBox(height: 4),
          
          // Username
          StreamBuilder(
            stream: EnhancedAuthService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Text(
                user?.email ?? '@musiclover123',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bio
          Text(
            'Passionate about discovering new music and sharing my thoughts with the world. 🎵',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          
          // Edit Profile Button
          Container(
            width: 160,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Profili Düzenle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Songs',
              value: '247',
              icon: Icons.music_note,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Albums',
              value: '43',
              icon: Icons.album,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Reviews',
              value: '23',
              icon: Icons.edit,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await EnhancedAuthService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
