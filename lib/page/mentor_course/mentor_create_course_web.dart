import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MentorCreateCourseWeb extends StatefulWidget {
  const MentorCreateCourseWeb({super.key});

  @override
  State<MentorCreateCourseWeb> createState() => _MentorCreateCourseWebState();
}

class _MentorCreateCourseWebState extends State<MentorCreateCourseWeb>
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
    titleController = TextEditingController();
    subtitleController = TextEditingController();
    descriptionController = TextEditingController();
    youtubeController = TextEditingController();
    meetController = TextEditingController();
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
    return Row(
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
                Icon(Icons.arrow_back, size: 20, color: Color(0xff1a90ff)),
                SizedBox(width: 4),
                Text(
                  "Quay lại",
                  style: TextStyle(
                    color: Color(0xff1a90ff),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Separator
        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),

        const SizedBox(width: 16),

        // Courses link
        InkWell(
          onTap: () => context.push('/mentor/courses'),
          child: const Text(
            "Khóa học",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Separator
        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),

        const SizedBox(width: 16),

        // Current page title
        const Flexible(
          child: Text(
            "Tạo khóa học mới",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Row(
        children: [
          /// MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // Breadcrumb
                Padding(
                  padding: const EdgeInsets.only(
                    top: 30,
                    left: 30,
                    right: 30,
                  ),
                  child: _buildBreadcrumb(context),
                ),

                // Tab bar
                Container(
                  margin: const EdgeInsets.only(top: 20, left: 30, right: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: "Thông tin khóa học"),
                      Tab(text: "Cấu trúc khóa học"),
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
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Tab 1: Thông tin khóa học
  Widget _buildCourseInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// FORM CONTAINER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// COVER IMAGE
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.photo_camera),
                      label: const Text("Thay đổi ảnh bìa"),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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

          const SizedBox(height: 24),

          /// ACTION BUTTONS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Đã lưu khóa học"),
                      ),
                    );
                    context.pop();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Lưu khóa học"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1a90ff),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
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
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Danh sách chương",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text("Thêm Chương"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1a90ff),
                  foregroundColor: Colors.white,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
