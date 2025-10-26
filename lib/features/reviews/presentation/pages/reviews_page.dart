import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/music_review.dart';
import '../../../../core/theme/app_theme.dart';
import 'review_detail_page.dart';

class ReviewsPage extends ConsumerStatefulWidget {
  const ReviewsPage({super.key});

  @override
  ConsumerState<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends ConsumerState<ReviewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text(
          'Reviews',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: const [
            Tab(text: 'Arkadaşlar'),
            Tab(text: 'Popüler'),
            Tab(text: 'Yeni'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsReviews(isDark),
          _buildPopularReviews(isDark),
          _buildRecentReviews(isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReviewDialog(context, isDark),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.edit),
        label: const Text('Review Yaz'),
      ),
    );
  }

  Widget _buildFriendsReviews(bool isDark) {
    final mockReviews = _getMockReviews();

    if (mockReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz review yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arkadaşlarınız review paylaştığında burada görünecek',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockReviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(mockReviews[index], isDark);
        },
      ),
    );
  }

  Widget _buildPopularReviews(bool isDark) {
    return _buildFriendsReviews(isDark);
  }

  Widget _buildRecentReviews(bool isDark) {
    return _buildFriendsReviews(isDark);
  }

  Widget _buildReviewCard(MusicReview review, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    review.username[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          children: [
                            Text(
                              review.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (review.rating != null) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    index < review.rating! ? Icons.star : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(review.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // TODO: Show options menu
                  },
                ),
              ],
            ),
          ),

          // Music Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.trackName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.artists,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_outline,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Review Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              review.reviewText,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
          ),

          // Tags
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: review.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Like/Dislike combined (MusicBoard style)
                _buildLikeDislikeButton(review, isDark),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: review.replyCount.toString(),
                  onTap: () {
                    _showReviewDetail(review, isDark);
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Paylaş',
                  onTap: () {
                    _shareReview(review);
                  },
                  isDark: isDark,
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  label: '',
                  onTap: () {
                    _bookmarkReview(review);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeDislikeButton(MusicReview review, bool isDark) {
    // Mock current user ID (in real app, get from auth service)
    const currentUserId = 'current_user';
    
    final isLiked = review.likedBy.contains(currentUserId);
    final isDisliked = review.dislikedBy.contains(currentUserId);
    final netScore = review.likeCount - review.dislikeCount;
    final scoreColor = netScore > 0 
        ? Colors.green 
        : netScore < 0 
            ? Colors.red 
            : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              // TODO: Implement like toggle
              setState(() {
                // Mock implementation
              });
            },
            child: Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: isLiked ? AppTheme.primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            netScore.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              // TODO: Implement dislike toggle
              setState(() {
                // Mock implementation
              });
            },
            child: Icon(
              isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
              size: 18,
              color: isDisliked ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReviewDetail(MusicReview review, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDetailPage(review: review),
      ),
    );
  }

  void _shareReview(MusicReview review) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${review.username} kullanıcısının review\'ını paylaş')),
    );
  }

  void _bookmarkReview(MusicReview review) {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review kaydedildi')),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  void _showCreateReviewDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Yaz'),
        content: const Text('Review yazma özelliği yakında eklenecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  List<MusicReview> _getMockReviews() {
    // Mock data
    return List.generate(5, (index) {
      return MusicReview(
        id: 'review_$index',
        userId: 'user_$index',
        username: 'Kullanıcı ${index + 1}',
        trackId: 'track_$index',
        trackName: 'Şarkı Adı ${index + 1}',
        artists: 'Sanatçı Adı',
        rating: (index % 5) + 1,
        reviewText: index == 0
            ? 'Bu şarkı gerçekten harika! Özellikle melodisi ve sözleri çok etkileyici. Her dinlediğimde farklı bir his katıyor bana. Kesinlikle herkesin dinlemesi gereken bir parça.'
            : index == 1
            ? 'İlk defa dinlediğimde pek anlamadım ama zamanla gelişti. Şimdi favorilerimden biri. Ritim ve enstrümantasyon mükemmel.'
            : 'Harika bir parça! ${index + 1}/5 ⭐',
        tags: index == 0
            ? ['favorilerim', 'duygusal', 'dinlenmeli']
            : index == 1
            ? ['yaz', 'enerjik']
            : [],
        likeCount: (index + 1) * 12,
        dislikeCount: index * 2,
        likedBy: index == 0 ? ['current_user', 'user_1'] : ['user_1'],
        dislikedBy: index == 1 ? ['current_user'] : [],
        replyCount: (index + 1) * 3,
        createdAt: DateTime.now().subtract(Duration(hours: index * 2)),
        updatedAt: DateTime.now().subtract(Duration(hours: index * 2)),
      );
    });
  }
}
