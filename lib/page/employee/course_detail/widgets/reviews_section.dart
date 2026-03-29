import 'package:flutter/material.dart';

/// Refactor từ course_reviews.dart
/// - Thêm Rating Overview với bar chart (Coursera style)
/// - Hiển thị tổng quan rating + phân bố sao
class ReviewsSection extends StatelessWidget {
  final List<ReviewItem> reviews;
  final double averageRating;
  final VoidCallback? onSeeAll;

  const ReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đánh giá học viên',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF137FEC),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Rating Overview ───
        _RatingOverview(
          averageRating: averageRating,
          totalReviews: reviews.length,
          reviews: reviews,
        ),
        const SizedBox(height: 24),

        // ─── Review cards grid ───
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: reviews.length > 4 ? 4 : reviews.length,
          itemBuilder: (context, index) {
            return _ReviewCard(review: reviews[index]);
          },
        ),
      ],
    );
  }
}

class _RatingOverview extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final List<ReviewItem> _reviews;

  const _RatingOverview({
    required this.averageRating,
    required this.totalReviews,
    required List<ReviewItem> reviews,
  }) : _reviews = reviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // ─── Left: Big rating number ───
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildStars(averageRating),
              const SizedBox(height: 6),
              Text(
                '$totalReviews đánh giá',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(width: 32),

          // ─── Right: Bar chart ───
          Expanded(
            child: Column(
              children: [
                _RatingBar(stars: 5, percent: _calcPercent(5)),
                const SizedBox(height: 6),
                _RatingBar(stars: 4, percent: _calcPercent(4)),
                const SizedBox(height: 6),
                _RatingBar(stars: 3, percent: _calcPercent(3)),
                const SizedBox(height: 6),
                _RatingBar(stars: 2, percent: _calcPercent(2)),
                const SizedBox(height: 6),
                _RatingBar(stars: 1, percent: _calcPercent(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final fill = (rating - index).clamp(0.0, 1.0);
        return Icon(
          fill >= 1
              ? Icons.star
              : fill >= 0.5
              ? Icons.star_half
              : Icons.star_outline,
          size: 18,
          color: const Color(0xFFFBBF24),
        );
      }),
    );
  }

  double _calcPercent(int star) {
    if (_reviews.isEmpty) return 0;
    final count = _reviews.where((r) => r.rating.round() == star).length;
    return count / totalReviews;
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final double percent;

  const _RatingBar({required this.stars, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$stars',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 12, color: Color(0xFFFBBF24)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(percent * 100).round()}%',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewItem review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating.round() ? Icons.star : Icons.star_outline,
                size: 14,
                color: const Color(0xFFFBBF24),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Comment
          Expanded(
            child: Text(
              '"${review.comment}"',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // User
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0),
                  image:
                      review.avatarUrl != null
                          ? DecorationImage(
                            image: NetworkImage(review.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    review.avatarUrl == null
                        ? const Icon(
                          Icons.person,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        )
                        : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Re-export ReviewItem để reuse ───
class ReviewItem {
  final double rating;
  final String comment;
  final String userName;
  final String? avatarUrl;

  const ReviewItem({
    required this.rating,
    required this.comment,
    required this.userName,
    this.avatarUrl,
  });
}
