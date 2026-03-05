import 'package:flutter/material.dart';
import 'mentor_create_course_web.dart';
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
          Container(
            width: 240,
            color: Colors.white,
            child: Column(
              children: [

                const SizedBox(height: 30),

                const Icon(Icons.school, size: 40, color: Colors.blue),

                const SizedBox(height: 10),

                const Text(
                  "SMETS",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                _menuItem(Icons.dashboard, "Tổng quan"),
                _menuItem(Icons.menu_book, "Khóa học", selected: true),
                _menuItem(Icons.people, "Học viên"),
                _menuItem(Icons.message, "Tin nhắn"),
                _menuItem(Icons.settings, "Cài đặt"),

              ],
            ),
          ),

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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MentorCreateCourseWeb(),
                              ),
                            );
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

  static Widget _menuItem(IconData icon, String text,
      {bool selected = false}) {
    return Container(
      color: selected ? const Color(0xffeef3ff) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.blue : Colors.grey),
        title: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.blue : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {},
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

                  const Icon(Icons.visibility, size: 18),

                  const SizedBox(width: 10),

                  const Icon(Icons.edit, size: 18),

                  const SizedBox(width: 10),

                  const Icon(Icons.delete, size: 18, color: Colors.red),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}