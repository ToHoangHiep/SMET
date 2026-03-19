import 'package:flutter/material.dart';
import 'mentor_course_detail_mobile.dart';
import 'mentor_create_course_mobile.dart';
import 'mentor_update_course_mobile.dart';
import '../mentor_dashboard/mentor_sidebar.dart';

class MentorCourseMobile extends StatefulWidget {
  const MentorCourseMobile({super.key});

  @override
  State<MentorCourseMobile> createState() => _MentorCourseMobileState();
}

class _MentorCourseMobileState extends State<MentorCourseMobile> {

  String selectedFilter = "All";

  final List<Map<String, String>> courses = [
    {
      "title": "Flutter for Beginners",
      "lessons": "10 Chương • 45 Bài học",
      "status": "Published"
    },
    {
      "title": "Advanced NodeJS",
      "lessons": "8 Chương • 30 Bài học",
      "status": "Draft"
    },
    {
      "title": "UI/UX Design Masterclass",
      "lessons": "12 Chương • 60 Bài học",
      "status": "Published"
    },
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      /// DRAWER - Dùng chung MentorSidebar
      drawer: Drawer(
        child: Container(
          width: 250,
          color: Colors.white,
          child: const MentorSidebar(selectedIndex: 1),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Bảng điều khiển Mentor",
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 18),
            ),
          )
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [

          /// TITLE
          const Text(
            "Quản lý khóa học",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          /// CREATE COURSE
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MentorCreateCourseMobile(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Tạo khóa học mới"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// SEARCH
          TextField(
            decoration: InputDecoration(
              hintText: "Tìm kiếm khóa học...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// FILTER
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                filterChip("All"),
                filterChip("Published"),
                filterChip("Draft"),
                filterChip("Archived"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// COURSE LIST
          ...courses.map((course) {
            return courseCard(
              course["title"]!,
              course["lessons"]!,
              course["status"]!,
            );
          }).toList(),
        ],
      ),

      /// BOTTOM NAVIGATION - Removed, using Drawer sidebar instead
    );
  }

  /// FILTER CHIP
  Widget filterChip(String label) {

    final bool active = selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (value) {
          setState(() {
            selectedFilter = label;
          });
        },
      ),
    );
  }

  /// COURSE CARD
  Widget courseCard(
      String title,
      String lessons,
      String status,
      ) {

    Color statusColor = Colors.grey;

    if (status == "Published") {
      statusColor = Colors.green;
    } else if (status == "Draft") {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// THUMBNAIL
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                /// LESSONS
                Text(
                  lessons,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    /// STATUS
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MentorCourseDetailMobile(
                              title: title,
                              mentorName: "Nguyễn Văn A",
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.visibility, size: 20),
                    ),

                    const SizedBox(width: 12),

                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MentorUpdateCourseMobile(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    GestureDetector(
                      onTap: () {

                        showDialog(
                          context: context,
                          builder: (context) {

                            return AlertDialog(
                              title: const Text("Xóa khóa học"),
                              content: const Text("Bạn có chắc muốn xóa khóa học này không?"),

                              actions: [

                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Hủy"),
                                ),

                                TextButton(
                                  onPressed: () {

                                    setState(() {
                                      courses.removeWhere((c) => c["title"] == title);
                                    });

                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Xóa",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                      },
                      child: const Icon(Icons.delete, size: 20, color: Colors.red),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}