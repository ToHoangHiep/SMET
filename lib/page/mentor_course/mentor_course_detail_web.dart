import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'mentor_update_course_web.dart';

class MentorCourseDetailWeb extends StatefulWidget {
  final String title;
  final String mentorName;

  const MentorCourseDetailWeb({
    super.key,
    required this.title,
    required this.mentorName,
  });

  @override
  State<MentorCourseDetailWeb> createState() => _MentorCourseDetailWebState();
}

class _MentorCourseDetailWebState extends State<MentorCourseDetailWeb>
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
          onTap: () => context.go('/mentor/courses'),
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
        Flexible(
          child: Text(
            widget.title,
            style: const TextStyle(
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
                      Tab(text: "Thông tin chung"),
                      Tab(text: "Cấu trúc khóa học"),
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
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Tab 1: Thông tin chung
  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// COURSE OVERVIEW
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),

                const SizedBox(width: 20),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Bởi ${widget.mentorName}",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
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
                        icon: const Icon(Icons.edit),
                        label: const Text("Chỉnh sửa thông tin chung"),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// COURSE DETAILS
          Container(
            padding: const EdgeInsets.all(20),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
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
      padding: const EdgeInsets.all(30),
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

          const SizedBox(height: 20),

          /// MODULE 1
          _buildModule("Chương 1: Nguyên lý thị giác", [
            {
              "title": "1.1 Phân cấp thị giác",
              "status": "Công khai"
            },
            {
              "title": "1.2 Tương phản và Cân bằng",
              "status": "Bản nháp"
            }
          ]),

          const SizedBox(height: 20),

          _buildModule("Chương 2: Typography & Màu sắc", [
            {
              "title": "2.1 Ý nghĩa của màu sắc",
              "status": "Ẩn"
            }
          ]),
        ],
      ),
    );
  }

  Widget _buildModule(
      String moduleTitle, List<Map<String, String>> lessons) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(
                moduleTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {},
                    child: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {},
                    child: const Icon(Icons.delete, size: 20, color: Colors.red),
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
              title: Text(lesson["title"]!),
              subtitle: Text(
                lesson["status"]!,
                style: TextStyle(color: statusColor),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {},
                    child: const Icon(Icons.edit, size: 20),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {},
                    child: const Icon(Icons.visibility, size: 20),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {},
                    child: const Icon(Icons.delete, size: 20, color: Colors.red),
                  ),
                ],
              ),
            );
          }).toList(),

          const Divider(),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Thêm bài học mới"),
            ),
          )
        ],
      ),
    );
  }
}