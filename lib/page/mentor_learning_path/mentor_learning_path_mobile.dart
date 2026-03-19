import 'package:flutter/material.dart';
import '../mentor_dashboard/mentor_sidebar.dart';
import 'mentor_create_learning_path_mobile.dart';

class MentorLearningPathMobile extends StatefulWidget {
  const MentorLearningPathMobile({super.key});

  @override
  State<MentorLearningPathMobile> createState() => _MentorLearningPathMobileState();
}

class _MentorLearningPathMobileState extends State<MentorLearningPathMobile> {
  String searchQuery = "";

  final List<Map<String, dynamic>> learningPaths = [
    {
      "title": "Thiết kế UI/UX Chuyên nghiệp 2024",
      "courses": "15 khóa học • 42 bài giảng",
      "status": "Đang mở",
      "statusColor": Colors.green,
      "students": ["avatar1", "avatar2"],
      "studentCount": 12,
      "lastUpdated": null,
    },
    {
      "title": "Lập trình Fullstack Web Developer",
      "courses": "24 khóa học • 120 bài giảng",
      "status": "Nháp",
      "statusColor": Colors.amber,
      "students": [],
      "studentCount": 0,
      "lastUpdated": "2 ngày trước",
    },
    {
      "title": "Data Science Foundation",
      "courses": "8 khóa học • 32 bài giảng",
      "status": "Đã đóng",
      "statusColor": Colors.grey,
      "students": [],
      "studentCount": 0,
      "lastUpdated": "Đã đóng tháng 12/2023",
      "isArchived": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7f8),

      /// DRAWER - Dùng chung MentorSidebar
      drawer: Drawer(
        child: Container(
          width: 250,
          color: Colors.white,
          child: const MentorSidebar(selectedIndex: 2),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Quản lý Lộ trình học tập",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          /// SEARCH AND CREATE BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// SEARCH
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffe0e0e0)),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm lộ trình học tập...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// CREATE BUTTON
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MentorCreateLearningPathMobile(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle),
                    label: const Text(
                      "Tạo lộ trình mới",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1a90ff),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// LIST SECTION
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Danh sách lộ trình (${learningPaths.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text("Lọc"),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xff1a90ff),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// LEARNING PATH CARDS
                ...learningPaths
                    .where((path) => path["title"].toString().toLowerCase().contains(searchQuery))
                    .map((path) => _buildLearningPathCard(path)),
              ],
            ),
          ),
        ],
      ),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff1a90ff),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree),
            label: "Lộ trình",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Học viên",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Cá nhân",
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPathCard(Map<String, dynamic> path) {
    final bool isArchived = path["isArchived"] ?? false;

    return Opacity(
      opacity: isArchived ? 0.75 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe0e0e0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// THUMBNAIL
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(
                    "https://via.placeholder.com/80",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: isArchived
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            /// CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE AND STATUS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          path["title"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isArchived ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (path["statusColor"] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          path["status"],
                          style: TextStyle(
                            color: path["statusColor"],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  /// COURSES INFO
                  Text(
                    path["courses"],
                    style: TextStyle(
                      color: isArchived ? Colors.grey : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// STUDENTS OR LAST UPDATED
                  if (path["students"].isNotEmpty) ...[
                    Row(
                      children: [
                        /// AVATARS
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "+${path["studentCount"]}",
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            children: [
                              Text(
                                "Chi tiết",
                                style: TextStyle(
                                  color: Color(0xff1a90ff),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Color(0xff1a90ff),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          path["lastUpdated"] ?? "",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            children: [
                              Text(
                                isArchived ? "Xem lại" : "Chi tiết",
                                style: TextStyle(
                                  color: isArchived ? Colors.grey : const Color(0xff1a90ff),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: isArchived ? Colors.grey : const Color(0xff1a90ff),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
