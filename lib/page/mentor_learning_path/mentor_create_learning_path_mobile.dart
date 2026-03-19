import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MentorCreateLearningPathMobile extends StatefulWidget {
  const MentorCreateLearningPathMobile({super.key});

  @override
  State<MentorCreateLearningPathMobile> createState() =>
      _MentorCreateLearningPathMobileState();
}

class _MentorCreateLearningPathMobileState
    extends State<MentorCreateLearningPathMobile> {
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

          // Learning paths link
          InkWell(
            onTap: () => context.push('/mentor/learning-paths'),
            child: const Text(
              "Lộ trình học tập",
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
          const Flexible(
            child: Text(
              "Tạo lộ trình học tập mới",
              style: TextStyle(
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
                // Action buttons bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Tạo lộ trình học tập mới",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text(
                            "Hủy",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Lưu lộ trình thành công!')),
                            );
                            context.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1a90ff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            "Lưu",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Section 1: Thông tin cơ bản
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Thumbnail
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 36, color: Colors.grey[400]),
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

                        const SizedBox(height: 16),

                        /// Tên lộ trình
                        _buildTextField(
                          label: "Tên lộ trình",
                          controller: _titleController,
                          hint:
                              "Ví dụ: Trở thành Chuyên viên Phân tích Dữ liệu",
                        ),

                        const SizedBox(height: 12),

                        /// Mô tả chi tiết
                        _buildTextField(
                          label: "Mô tả chi tiết",
                          controller: _descriptionController,
                          hint:
                              "Nhập mô tả chi tiết về các kỹ năng sẽ đạt được...",
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Section 2: Khóa học hiện có
                  Container(
                    padding: const EdgeInsets.all(16),
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
                                color: Color(0xff1a90ff), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Khóa học hiện có",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xffeef3ff),
                                borderRadius: BorderRadius.circular(4),
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

                        const SizedBox(height: 12),

                        /// Search
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xfff5f6fa),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: "Tìm kiếm khóa học...",
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.grey, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// Course list
                        ...availableCourses
                            .where((course) => course["title"]
                                .toString()
                                .toLowerCase()
                                .contains(searchQuery))
                            .map((course) =>
                                _buildAvailableCourseItem(course)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Section 3: Thứ tự hoàn thành
                  Container(
                    padding: const EdgeInsets.all(16),
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
                                color: Color(0xff1a90ff), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Thứ tự hoàn thành",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (selectedCourses.isEmpty)
                          _buildEmptyState()
                        else
                          ...selectedCourses.asMap().entries.map((entry) {
                            return _buildSelectedCourseItem(
                                entry.key, entry.value);
                          }),

                        if (selectedCourses.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xfff5f6fa),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Tổng thời gian dự kiến:",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                                Text(
                                  "${totalHours.toStringAsFixed(0)} giờ học",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1a90ff),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
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
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image, color: Colors.grey[500], size: 24),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Mentor: ${course["mentor"]} · ${course["lessons"]} bài học",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_circle_outline,
                size: 36, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              "Chọn khóa học từ danh sách trên để thêm vào lộ trình",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number indicator
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      isFirst ? const Color(0xff1a90ff) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: isFirst ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[300],
                ),
            ],
          ),

          const SizedBox(width: 10),

          // Course card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFirst ? const Color(0xffeef3ff) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isFirst ? const Color(0xff1a90ff) : const Color(0xffe0e0e0),
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
                            fontSize: 13,
                            color: isFirst
                                ? const Color(0xff1a90ff)
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? const Color(0xff1a90ff).withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isFirst ? "Bắt buộc" : "Tùy chọn",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isFirst
                                      ? const Color(0xff1a90ff)
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.schedule,
                              size: 11,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${(course["lessons"] * 1.5).toStringAsFixed(0)} giờ",
                              style: TextStyle(
                                fontSize: 9,
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
                      size: 18,
                    ),
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
