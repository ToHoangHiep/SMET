import 'package:flutter/material.dart';

class CourseReviews extends StatelessWidget {
  final List<Review> reviews;
  final VoidCallback? onSeeAll;

  const CourseReviews({
    super.key,
    required this.reviews,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
        // Reviews Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewCard(review);
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
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
                index < review.rating ? Icons.star : Icons.star_outline,
                size: 16,
                color: const Color(0xFFFBBF24),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Comment
          Text(
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
          const Spacer(),
          // User
          Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0),
                  image: review.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(review.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: review.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Name
              Text(
                review.userName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Review {
  final double rating;
  final String comment;
  final String userName;
  final String? avatarUrl;

  const Review({
    required this.rating,
    required this.comment,
    required this.userName,
    this.avatarUrl,
  });
}
