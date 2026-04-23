import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class LiveSessionsHubPage extends StatelessWidget {
  const LiveSessionsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SharedBreadcrumb(
              items: const [
                BreadcrumbItem(label: 'Trang chủ', route: '/employee/dashboard'),
                BreadcrumbItem(label: 'Buổi học trực tuyến'),
              ],
              primaryColor: const Color(0xFF137FEC),
              fontSize: 10,
              padding: EdgeInsets.zero,
            ),
            const Text(
              'Buổi học trực tuyến',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_camera_front_rounded,
                  size: 48,
                  color: Color(0xFF137FEC),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chọn khóa học để xem buổi live',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vui lòng chọn khóa học từ trang "Khóa học của tôi" để xem các buổi học trực tuyến.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/employee/my-courses'),
                  icon: const Icon(Icons.library_books),
                  label: const Text('Đi đến Khóa học của tôi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/employee/dashboard'),
                child: const Text('Quay về Trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
