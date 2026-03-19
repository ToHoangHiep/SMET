import 'package:flutter/material.dart';
import '../mentor_dashboard/mentor_sidebar.dart';
import 'mentor_create_learning_path_web.dart';

class MentorLearningPathWeb extends StatefulWidget {
  const MentorLearningPathWeb({super.key});

  @override
  State<MentorLearningPathWeb> createState() => _MentorLearningPathWebState();
}

class _MentorLearningPathWebState extends State<MentorLearningPathWeb> {
  String searchQuery = "";
  String selectedFilter = "All";

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
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      body: Row(
        children: [
          /// SIDEBAR
          // const MentorSidebar(selectedIndex: 2),

          /// MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                /// TOPBAR
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Bảng điều khiển Mentor",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person),
                      )
                    ],
                  ),
                ),

                /// CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TITLE
                        const Text(
                          "Quản lý Lộ trình học tập",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// SEARCH + CREATE BUTTON
                        Row(
                          children: [
                            /// SEARCH
                            SizedBox(
                              width: 350,
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value.toLowerCase();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: "Tìm kiếm lộ trình học tập...",
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            /// CREATE BUTTON
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MentorCreateLearningPathWeb(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_circle),
                              label: const Text("Tạo lộ trình mới"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            const Spacer(),

                            /// FILTER BUTTON
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.filter_list),
                              label: const Text("Lọc"),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xff1a90ff),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// FILTER CHIPS
                        Row(
                          children: [
                            _filterChip("All"),
                            _filterChip("Đang mở"),
                            _filterChip("Nháp"),
                            _filterChip("Đã đóng"),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// PATH COUNT
                        Text(
                          "Danh sách lộ trình (${learningPaths.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// LEARNING PATH GRID
                        Expanded(
                          child: GridView.builder(
                            itemCount: learningPaths.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: width > 1400 ? 3 : 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.5,
                            ),
                            itemBuilder: (context, index) {
                              return _buildLearningPathCard(learningPaths[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedFilter == label,
        onSelected: (value) {
          setState(() {
            selectedFilter = label;
          });
        },
      ),
    );
  }

  Widget _buildLearningPathCard(Map<String, dynamic> path) {
    final bool isArchived = path["isArchived"] ?? false;

    return Opacity(
      opacity: isArchived ? 0.75 : 1.0,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// THUMBNAIL
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage("https://via.placeholder.com/300x100"),
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

            const SizedBox(height: 12),

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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

            const Spacer(),

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
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      children: [
                        Text(
                          "Chi tiết",
                          style: TextStyle(fontSize: 12),
                        ),
                        Icon(Icons.chevron_right, size: 16),
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
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        Text(
                          isArchived ? "Xem lại" : "Chi tiết",
                          style: TextStyle(
                            fontSize: 12,
                            color: isArchived ? Colors.grey : Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: isArchived ? Colors.grey : Colors.white,
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
    );
  }
}
