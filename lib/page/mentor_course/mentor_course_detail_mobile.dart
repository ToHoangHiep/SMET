import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'mentor_update_course_web.dart';

class MentorCourseDetailMobile extends StatefulWidget {
  final String title;
  final String mentorName;

  const MentorCourseDetailMobile({
    super.key,
    required this.title,
    required this.mentorName,
  });

  @override
  State<MentorCourseDetailMobile> createState() =>
      _MentorCourseDetailMobileState();
}

class _MentorCourseDetailMobileState extends State<MentorCourseDetailMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            onTap: () => context.go('/mentor/courses'),
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
              widget.title,
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
                      Tab(text: "Thông tin chung"),
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
                // Tab 1: Thông tin chung
                _buildGeneralInfoTab(),

                // Tab 2: Cấu trúc khóa học
                _buildCourseStructureTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Thông tin chung
  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// COURSE OVERVIEW
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail - centered on mobile
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                // Mentor name
                Center(
                  child: Text(
                    "Bởi ${widget.mentorName}",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Edit button - full width on mobile
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MentorUpdateCourseWeb(
                            title: widget.title,
                            lessons: "10 Chương • 45 Bài học",
                            status: "Published",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Chỉnh sửa thông tin chung"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// COURSE DETAILS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chi tiết khóa học",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow("Số chương", "10"),
                _buildInfoRow("Số bài học", "45"),
                _buildInfoRow("Thời lượng", "12 giờ 30 phút"),
                _buildInfoRow("Trạng thái", "Đã xuất bản"),
                _buildInfoRow("Ngày tạo", "15/01/2026"),
                _buildInfoRow("Lần cập nhật cuối", "18/03/2026"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Cấu trúc khóa học
  Widget _buildCourseStructureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// STRUCTURE HEADER
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            ],
          ),

          const SizedBox(height: 16),

          /// MODULE 1
          _buildModule("Chương 1: Nguyên lý thị giác", [
            {"title": "1.1 Phân cấp thị giác", "status": "Công khai"},
            {"title": "1.2 Tương phản và Cân bằng", "status": "Bản nháp"}
          ]),

          const SizedBox(height: 16),

          _buildModule("Chương 2: Typography & Màu sắc", [
            {"title": "2.1 Ý nghĩa của màu sắc", "status": "Ẩn"}
          ]),
        ],
      ),
    );
  }

  Widget _buildModule(String moduleTitle, List<Map<String, String>> lessons) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          /// MODULE HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  moduleTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {},
                    child:
                        const Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {},
                    child:
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 10),
          const Divider(),

          /// LESSON LIST
          ...lessons.map((lesson) {
            Color statusColor = Colors.grey;

            if (lesson["status"] == "Công khai") {
              statusColor = Colors.green;
            } else if (lesson["status"] == "Bản nháp") {
              statusColor = Colors.orange;
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                lesson["title"]!,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                lesson["status"]!,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {},
                    child: const Icon(Icons.edit, size: 18),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {},
                    child: const Icon(Icons.visibility, size: 18),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {},
                    child:
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                  ),
                ],
              ),
            );
          }),

          const Divider(),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Thêm bài học mới"),
            ),
          )
        ],
      ),
    );
  }
}
