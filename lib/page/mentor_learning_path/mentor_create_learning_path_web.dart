import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MentorCreateLearningPathWeb extends StatefulWidget {
  const MentorCreateLearningPathWeb({super.key});

  @override
  State<MentorCreateLearningPathWeb> createState() =>
      _MentorCreateLearningPathWebState();
}

class _MentorCreateLearningPathWebState
    extends State<MentorCreateLearningPathWeb> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String searchQuery = "";

  final List<Map<String, dynamic>> availableCourses = [
    {
      "title": "Cơ bản về SQL cho người mới",
      "mentor": "Minh Quang",
      "lessons": 12,
    },
    {
      "title": "Trực quan hóa dữ liệu với Tableau",
      "mentor": "Thu Trang",
      "lessons": 15,
    },
    {
      "title": "Lập trình Python cho phân tích",
      "mentor": "Bảo Nam",
      "lessons": 20,
    },
    {
      "title": "Thống kê ứng dụng trong Kinh doanh",
      "mentor": "Thúy Vy",
      "lessons": 10,
    },
  ];

  final List<Map<String, dynamic>> selectedCourses = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addCourse(Map<String, dynamic> course) {
    setState(() {
      selectedCourses.add(course);
    });
  }

  void _removeCourse(int index) {
    setState(() {
      selectedCourses.removeAt(index);
    });
  }

  double get totalHours {
    return selectedCourses.fold(
        0.0, (sum, course) => sum + (course["lessons"] as int) * 1.5);
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

        // Learning paths link
        InkWell(
          onTap: () => context.push('/mentor/learning-paths'),
          child: const Text(
            "Lộ trình học tập",
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
            "Tạo lộ trình học tập mới",
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

                // Tab / Header bar (single page, no tabs needed)
                Container(
                  margin: const EdgeInsets.only(top: 20, left: 30, right: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tạo lộ trình học tập mới",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text("Hủy"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Lưu lộ trình thành công!')),
                              );
                              context.pop();
                            },
                            icon: const Icon(Icons.save),
                            label: const Text("Lưu lộ trình"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff1a90ff),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Section 1: Thông tin cơ bản
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Thumbnail Upload
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Ảnh đại diện lộ trình",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Click để tải ảnh lên",
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 30),

                              /// Fields
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      label: "Tên lộ trình",
                                      controller: _titleController,
                                      hint:
                                          "Ví dụ: Trở thành Chuyên viên Phân tích Dữ liệu",
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      label: "Mô tả chi tiết",
                                      controller: _descriptionController,
                                      hint:
                                          "Nhập mô tả chi tiết về các kỹ năng sẽ đạt được...",
                                      maxLines: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// Section 2 & 3: Courses side by side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Available Courses
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.library_books,
                                            color: Color(0xff1a90ff), size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Khóa học hiện có",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffeef3ff),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            "${availableCourses.length} Khóa học",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff1a90ff),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Search
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff5f6fa),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextField(
                                        onChanged: (value) {
                                          setState(() {
                                            searchQuery =
                                                value.toLowerCase();
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          hintText: "Tìm kiếm khóa học...",
                                          prefixIcon: Icon(Icons.search,
                                              size: 20, color: Colors.grey),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 520,
                                      child: ListView.builder(
                                        itemCount: availableCourses
                                            .where((course) => course["title"]
                                                .toString()
                                                .toLowerCase()
                                                .contains(searchQuery))
                                            .length,
                                        itemBuilder: (context, index) {
                                          final filteredCourses =
                                              availableCourses
                                                  .where((course) => course[
                                                          "title"]
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains(searchQuery))
                                                  .toList();
                                          return _buildAvailableCourseItem(
                                              filteredCourses[index]);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 24),

                            /// Selected Courses (Order)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.reorder,
                                            color: Color(0xff1a90ff), size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Thứ tự hoàn thành",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Kéo thả để sắp xếp",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 520,
                                      child: selectedCourses.isEmpty
                                          ? _buildEmptyState()
                                          : ListView.builder(
                                              itemCount:
                                                  selectedCourses.length,
                                              itemBuilder: (context, index) {
                                                return _buildSelectedCourseItem(
                                                    index,
                                                    selectedCourses[index]);
                                              },
                                            ),
                                    ),
                                    if (selectedCourses.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xfff5f6fa),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Tổng thời gian dự kiến:",
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            Text(
                                              "${totalHours.toStringAsFixed(0)} giờ học",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff1a90ff),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffe0e0e0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffe0e0e0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff1a90ff)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableCourseItem(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image, color: Colors.grey[500]),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Mentor: ${course["mentor"]} · ${course["lessons"]} bài học",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Add button
          IconButton(
            onPressed: () => _addCourse(course),
            icon: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xff1a90ff),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "Chọn khóa học từ danh sách bên trái để mở rộng lộ trình",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCourseItem(int index, Map<String, dynamic> course) {
    final bool isFirst = index == 0;
    final bool isLast = index == selectedCourses.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number indicator with line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isFirst ? const Color(0xff1a90ff) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: isFirst ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 80,
                  color: Colors.grey[300],
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Course card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFirst ? const Color(0xffeef3ff) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFirst ? const Color(0xff1a90ff) : const Color(0xffe0e0e0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course["title"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isFirst
                                ? const Color(0xff1a90ff)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? const Color(0xff1a90ff).withValues(alpha: 0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isFirst ? "Bắt buộc" : "Tùy chọn",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isFirst
                                      ? const Color(0xff1a90ff)
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${(course["lessons"] * 1.5).toStringAsFixed(0)} giờ",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeCourse(index),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  Icon(
                    Icons.drag_indicator,
                    color: Colors.grey[300],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
