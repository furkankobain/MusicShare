import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/feed_service.dart';

class AddReviewPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final String itemType; // 'track', 'album', or 'artist'

  const AddReviewPage({
    super.key,
    required this.item,
    required this.itemType,
  });

  @override
  ConsumerState<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends ConsumerState<AddReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String get _itemName => widget.item['name'] as String? ?? 'Unknown';
  
  String? get _itemImageUrl {
    if (widget.itemType == 'track') {
      final album = widget.item['album'] as Map<String, dynamic>?;
      final images = album?['images'] as List?;
      return images?.isNotEmpty == true ? images![0]['url'] as String? : null;
    } else {
      final images = widget.item['images'] as List?;
      return images?.isNotEmpty == true ? images![0]['url'] as String? : null;
    }
  }

  String get _itemSubtitle {
    if (widget.itemType == 'track' || widget.itemType == 'album') {
      final artists = widget.item['artists'] as List?;
      return artists?.isNotEmpty == true
          ? artists!.map((a) => a['name']).join(', ')
          : 'Unknown Artist';
    }
    return 'Artist';
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticService.mediumImpact();

    try {
      final userId = FirebaseBypassAuthService.isSignedIn ? 'user123' : null;
      final username = 'User';

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Save review
      await FirebaseFirestore.instance.collection('reviews').add({
        'userId': userId,
        'username': username ?? 'Anonymous',
        'itemId': widget.item['id'],
        'itemName': _itemName,
        'itemType': widget.itemType,
        'itemImageUrl': _itemImageUrl,
        'artistName': widget.itemType != 'artist' ? _itemSubtitle : null,
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      // Create activity for feed
      await FeedService.createActivity(
        type: 'review',
        contentId: widget.item['id'] as String,
        contentData: {
          'name': _itemName,
          'type': widget.itemType,
          'imageUrl': _itemImageUrl,
          'subtitle': _itemSubtitle,
        },
        reviewText: _reviewController.text.trim(),
        rating: _rating,
        isPublic: true,
      );

      if (mounted) {
        HapticService.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review posted successfully! 🎉'),
            backgroundColor: Color(0xFFFF5E5E),
          ),
        );
        context.pop();
      }
    } catch (e) {
      print('Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
        title: const Text('Write a Review'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitReview,
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Color(0xFFFF5E5E),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(widget.itemType == 'artist' ? 40 : 12),
                      image: _itemImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_itemImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _itemImageUrl == null
                        ? Icon(
                            widget.itemType == 'track'
                                ? Icons.music_note
                                : (widget.itemType == 'album' ? Icons.album : Icons.person),
                            color: Colors.grey[600],
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _itemName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _itemSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5E5E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.itemType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5E5E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Rating section
            Text(
              'Your Rating',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  return GestureDetector(
                    onTap: () {
                      HapticService.lightImpact();
                      setState(() => _rating = starValue);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _rating >= starValue ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFF5E5E),
                        size: 48,
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_rating > 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _rating == 5
                        ? 'Masterpiece! 🎉'
                        : _rating >= 4
                            ? 'Great! 👍'
                            : _rating >= 3
                                ? 'Good 👌'
                                : _rating >= 2
                                    ? 'Okay 😐'
                                    : 'Not for me 👎',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5E5E),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Review text
            Text(
              'Your Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 8,
              maxLength: 500,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Share your thoughts about this ${widget.itemType}...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF5E5E),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E5E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Post Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
