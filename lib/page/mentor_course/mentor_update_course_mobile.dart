import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MentorUpdateCourseMobile extends StatefulWidget {
  final String? title;
  final String? lessons;
  final String? status;

  const MentorUpdateCourseMobile({
    super.key,
    this.title,
    this.lessons,
    this.status,
  });

  @override
  State<MentorUpdateCourseMobile> createState() =>
      _MentorUpdateCourseMobileState();
}

class _MentorUpdateCourseMobileState extends State<MentorUpdateCourseMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController titleController;
  late TextEditingController subtitleController;
  late TextEditingController descriptionController;
  late TextEditingController youtubeController;
  late TextEditingController meetController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    titleController = TextEditingController(text: widget.title ?? "Flutter for Beginners");
    subtitleController = TextEditingController(text: "Learn Flutter from scratch");
    descriptionController = TextEditingController(
        text: "This course teaches Flutter from basic to advanced");
    youtubeController = TextEditingController(text: "https://youtube.com/...");
    meetController = TextEditingController(text: "https://meet.google.com/...");
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    subtitleController.dispose();
    descriptionController.dispose();
    youtubeController.dispose();
    meetController.dispose();
    super.dispose();
  }

  /// Build breadcrumb navigation with back button
  Widget _buildBreadcrumb(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xfff5f6fa),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18, color: Color(0xff1a90ff)),
                  SizedBox(width: 4),
                  Text(
                    "Quay lại",
                    style: TextStyle(
                      color: Color(0xff1a90ff),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Separator
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),

          const SizedBox(width: 8),

          // Courses link
          InkWell(
            onTap: () => context.push('/mentor/courses'),
            child: const Text(
              "Khóa học",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Separator
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),

          const SizedBox(width: 8),

          // Current page title
          Flexible(
            child: Text(
              "Cập nhật khóa học",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Column(
        children: [
          // Header with breadcrumb
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 16,
              right: 16,
            ),
            color: Colors.white,
            child: Column(
              children: [
                _buildBreadcrumb(context),
                const SizedBox(height: 12),
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f6fa),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xff1a90ff),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xff1a90ff),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "Thông tin khóa học"),
                      Tab(text: "Cấu trúc khóa học"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Thông tin khóa học
                _buildCourseInfoTab(),

                // Tab 2: Cấu trúc khóa học
                _buildStructureTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Thông tin khóa học
  Widget _buildCourseInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// FORM CONTAINER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// COVER IMAGE
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.photo_camera, size: 20),
                      label: const Text(
                        "Thay đổi ảnh bìa",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// COURSE NAME
                _buildField(
                  label: "Tên khóa học",
                  controller: titleController,
                  hintText: "Nhập tên khóa học",
                ),

                /// SUBTITLE
                _buildField(
                  label: "Phụ đề",
                  controller: subtitleController,
                  hintText: "Tóm tắt giá trị khóa học",
                ),

                /// DESCRIPTION
                _buildField(
                  label: "Mô tả khóa học",
                  controller: descriptionController,
                  hintText: "Chi tiết nội dung khóa học",
                  maxLines: 4,
                ),

                /// YOUTUBE
                _buildField(
                  label: "Link YouTube bài giảng",
                  controller: youtubeController,
                  hintText: "https://youtube.com/...",
                  icon: Icons.play_circle,
                ),

                /// MEET
                _buildField(
                  label: "Link Google Meet",
                  controller: meetController,
                  hintText: "https://meet.google.com/...",
                  icon: Icons.video_call,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// ACTION BUTTONS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đã cập nhật khóa học"),
                        ),
                      );
                      context.pop();
                    },
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text("Cập nhật khóa học"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1a90ff),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Hủy"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Cấu trúc khóa học
  Widget _buildStructureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Danh sách chương",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Thêm Chương"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1a90ff),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Chưa có chương nào. Nhấn \"Thêm Chương\" để bắt đầu.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
