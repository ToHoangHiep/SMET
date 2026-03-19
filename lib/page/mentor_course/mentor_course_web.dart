import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'mentor_course_detail_web.dart';
import 'mentor_create_course_web.dart';
import 'mentor_update_course_web.dart';
import '../mentor_dashboard/mentor_sidebar.dart';
import '../mentor_dashboard/mentor_dashboard.dart';
class MentorCourseWeb extends StatefulWidget {
  const MentorCourseWeb({super.key});

  @override
  State<MentorCourseWeb> createState() => _MentorCourseWebState();
}

class _MentorCourseWebState extends State<MentorCourseWeb> {
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
    {
      "title": "React from Zero",
      "lessons": "9 Chương • 40 Bài học",
      "status": "Archived"
    },
  ];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    int crossAxisCount = 3;

    if (width > 1600) {
      crossAxisCount = 4;
    } else if (width < 1200) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      body: Row(
        children: [

          /// SIDEBAR
          // const MentorSidebar(selectedIndex: 1),

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
                          "Quản lý khóa học",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// CREATE BUTTON
                        ElevatedButton.icon(
                          onPressed: () async {
                            final newCourse = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MentorCreateCourseWeb(),
                              ),
                            );

                            if (newCourse != null) {
                              setState(() {
                                courses.add({
                                  "title": newCourse["title"],
                                  "lessons": newCourse["lessons"],
                                  "status": newCourse["status"],
                                });
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Tạo khóa học mới"),
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

                        const SizedBox(height: 20),

                        /// SEARCH + FILTER
                        Row(
                          children: [

                            /// SEARCH
                            SizedBox(
                              width: 320,
                              child: TextField(
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
                            ),

                            const SizedBox(width: 20),

                            _filterChip("All"),
                            _filterChip("Published"),
                            _filterChip("Draft"),
                            _filterChip("Archived"),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// COURSE GRID
                        Expanded(
                          child: GridView.builder(
                            itemCount: courses.length,
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.35,
                            ),
                            itemBuilder: (context, index) {
                              return CourseCard(
                                title: courses[index]["title"]!,
                                lessons: courses[index]["lessons"]!,
                                status: courses[index]["status"]!,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// PAGINATION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [

                            Icon(Icons.chevron_left),

                            SizedBox(width: 10),

                            Text("1"),
                            SizedBox(width: 10),
                            Text("2"),
                            SizedBox(width: 10),
                            Text("3"),

                            SizedBox(width: 10),

                            Icon(Icons.chevron_right),
                          ],
                        )
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
      padding: const EdgeInsets.only(left: 10),
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
}

/// COURSE CARD
class CourseCard extends StatefulWidget {
  final String title;
  final String lessons;
  final String status;

  const CourseCard({
    super.key,
    required this.title,
    required this.lessons,
    required this.status,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {

  bool hover = false;

  @override
  Widget build(BuildContext context) {

    return MouseRegion(
      onEnter: (_) {
        setState(() => hover = true);
      },
      onExit: (_) {
        setState(() => hover = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: hover
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: hover ? 12 : 6,
              color: Colors.black.withOpacity(0.05),
            )
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// THUMBNAIL
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.lessons,
                style: const TextStyle(color: Colors.grey),
              ),

              const Spacer(),

              Row(
                children: [

                  Text(
                    widget.status,
                    style: TextStyle(
                      color: widget.status == "Published"
                          ? Colors.green
                          : widget.status == "Draft"
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: () {
                      context.go('/mentor/courses/${widget.title}');
                    },
                    child: const Icon(Icons.visibility, size: 18),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MentorUpdateCourseWeb(
                            title: widget.title,
                            lessons: widget.lessons,
                            status: widget.status,
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          // refresh UI nếu cần
                        });
                      }
                    },
                    child: const Icon(Icons.edit, size: 18),
                  ),

                  const SizedBox(width: 10),

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

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Đã xóa khóa học"),
                                    ),
                                  );

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
                    child: const Icon(Icons.delete, size: 18, color: Colors.red),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}