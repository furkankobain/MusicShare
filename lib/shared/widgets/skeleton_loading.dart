import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shape;
  final EdgeInsetsGeometry padding;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: ShapeDecoration(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          shape: shape,
        ),
      ),
    );
  }
}

/// Conversation tile skeleton
class ConversationSkeletonTile extends StatelessWidget {
  const ConversationSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          SkeletonLoading(
            width: 56,
            height: 56,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
          ),
          const SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(width: 120, height: 16),
                const SizedBox(height: 8),
                SkeletonLoading(width: double.infinity, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time skeleton
          SkeletonLoading(width: 40, height: 14),
        ],
      ),
    );
  }
}

/// Track list skeleton
class TrackListSkeletonItem extends StatelessWidget {
  const TrackListSkeletonItem({super.key});

  @override\n  Widget build(BuildContext context) {\n    final isDark = Theme.of(context).brightness == Brightness.dark;\n\n    return Container(\n      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n      decoration: BoxDecoration(\n        color: isDark ? Colors.grey[850] : Colors.white,\n        borderRadius: BorderRadius.circular(12),\n        border: Border.all(\n          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,\n        ),\n      ),\n      child: Padding(\n        padding: const EdgeInsets.all(12),\n        child: Row(\n          children: [\n            // Album cover skeleton\n            SkeletonLoading(\n              width: 50,\n              height: 50,\n              shape: const RoundedRectangleBorder(\n                borderRadius: BorderRadius.all(Radius.circular(8)),\n              ),\n            ),\n            const SizedBox(width: 12),\n            // Track info skeleton\n            Expanded(\n              child: Column(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  SkeletonLoading(width: 150, height: 14),\n                  const SizedBox(height: 6),\n                  SkeletonLoading(width: 100, height: 12),\n                ],\n              ),\n            ),\n          ],\n        ),\n      ),\n    );\n  }\n}\n\n/// Search result skeleton\nclass SearchResultSkeletonItem extends StatelessWidget {\n  const SearchResultSkeletonItem({super.key});\n\n  @override\n  Widget build(BuildContext context) {\n    final isDark = Theme.of(context).brightness == Brightness.dark;\n\n    return Container(\n      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n      child: Row(\n        children: [\n          // Thumbnail skeleton\n          SkeletonLoading(\n            width: 60,\n            height: 60,\n            shape: const RoundedRectangleBorder(\n              borderRadius: BorderRadius.all(Radius.circular(8)),\n            ),\n          ),\n          const SizedBox(width: 12),\n          // Info skeleton\n          Expanded(\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                SkeletonLoading(width: 180, height: 16),\n                const SizedBox(height: 6),\n                SkeletonLoading(width: 120, height: 12),\n                const SizedBox(height: 6),\n                SkeletonLoading(width: 80, height: 12),\n              ],\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\n/// Profile stats skeleton\nclass ProfileStatsSkeletonItem extends StatelessWidget {\n  const ProfileStatsSkeletonItem({super.key});\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      padding: const EdgeInsets.all(16),\n      child: Column(\n        children: [\n          // Stats row skeleton\n          Row(\n            mainAxisAlignment: MainAxisAlignment.spaceEvenly,\n            children: List.generate(\n              3,\n              (index) => Column(\n                children: [\n                  SkeletonLoading(width: 50, height: 20),\n                  const SizedBox(height: 6),\n                  SkeletonLoading(width: 40, height: 12),\n                ],\n              ),\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\n/// Generic list skeleton\nclass ListSkeleton extends StatelessWidget {\n  final int itemCount;\n  final Widget Function(BuildContext) itemBuilder;\n\n  const ListSkeleton({\n    super.key,\n    this.itemCount = 5,\n    required this.itemBuilder,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    return ListView.builder(\n      itemCount: itemCount,\n      itemBuilder: (context, index) => itemBuilder(context),\n    );\n  }\n}