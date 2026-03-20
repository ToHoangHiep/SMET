import 'package:smet/model/learning_model.dart';

/// ============================================================
/// LEARNING SERVICE - API giả lập cho Learning Workspace
/// 
/// [LƯU Ý QUAN TRỌNG]
/// - Tất cả dữ liệu trong file này là MOCKUP DATA
/// - Khi có API thật, chỉ cần thay đổi các method bên dưới
/// - GIỮ NGUYÊ CẤU TRÚC method để tránh break code
/// ============================================================

class LearningService {
  // ============================================================
  // CONFIG - Cấu hình API
  // ============================================================
  
  // Base URL cho API - thay đổi khi có server thật
  // static const String baseUrl = 'http://api-smets.fptzone.site/api';
  
  // Timeout config
  // static const Duration timeout = Duration(seconds: 30);

  // ============================================================
  // API METHODS - Các method gọi API
  // ============================================================

  /// Lấy thông tin khóa học đang học
  /// [courseId] - ID của khóa học
  /// [userId] - ID của người dùng
  /// 
  /// [API THẬT]: GET /api/courses/{courseId}/progress?userId={userId}
  static Future<LearningCourse> getCourseProgress(String courseId, String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // TODO: Replace with real API call
    // final response = await http.get(
    //   Uri.parse('$baseUrl/courses/$courseId/progress?userId=$userId'),
    // );
    // if (response.statusCode == 200) {
    //   return LearningCourse.fromJson(jsonDecode(response.body));
    // }
    
    // Return mock data
    return _mockCourseProgress(courseId);
  }

  /// Lấy chi tiết bài học
  /// [lessonId] - ID của bài học
  /// 
  /// [API THẬT]: GET /api/lessons/{lessonId}
  static Future<LessonContent> getLessonDetail(String lessonId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // TODO: Replace with real API call
    // final response = await http.get(
    //   Uri.parse('$baseUrl/lessons/$lessonId'),
    // );
    // if (response.statusCode == 200) {
    //   return LessonContent.fromJson(jsonDecode(response.body));
    // }
    
    return _mockLessonContent(lessonId);
  }

  /// Đánh dấu bài học hoàn thành
  /// [lessonId] - ID của bài học
  /// [userId] - ID của người dùng
  /// 
  /// [API THẬT]: POST /api/lessons/{lessonId}/complete
  static Future<bool> markLessonComplete(String lessonId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // TODO: Replace with real API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/lessons/$lessonId/complete'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'userId': userId}),
    // );
    // return response.statusCode == 200;
    
    return true;
  }

  /// Cập nhật tiến trình video
  /// [lessonId] - ID của bài học
  /// [userId] - ID của người dùng
  /// [position] - Vị trí hiện tại (giây)
  /// 
  /// [API THẬT]: PUT /api/lessons/{lessonId}/progress
  static Future<bool> updateVideoProgress(String lessonId, String userId, int position) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // TODO: Replace with real API call
    // final response = await http.put(
    //   Uri.parse('$baseUrl/lessons/$lessonId/progress'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'userId': userId,
    //     'position': position,
    //   }),
    // );
    // return response.statusCode == 200;
    
    return true;
  }

  /// Lấy danh sách thảo luận
  /// [lessonId] - ID của bài học
  /// 
  /// [API THẬT]: GET /api/lessons/{lessonId}/discussions
  static Future<List<Discussion>> getDiscussions(String lessonId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // TODO: Replace with real API call
    return _mockDiscussions();
  }

  /// Gửi bình luận
  /// [lessonId] - ID của bài học
  /// [userId] - ID của người dùng
  /// [comment] - Nội dung bình luận
  /// 
  /// [API THẬT]: POST /api/lessons/{lessonId}/discussions
  static Future<Discussion> postDiscussion(String lessonId, String userId, String comment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // TODO: Replace with real API call
    return Discussion(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      userName: 'Bạn',
      comment: comment,
      timeAgo: 'Vừa xong',
      replyCount: 0,
    );
  }

  // ============================================================
  // MOCK DATA - Dữ liệu mẫu
  // ============================================================

  static LearningCourse _mockCourseProgress(String courseId) {
    return LearningCourse(
      id: courseId,
      title: 'SMETS Fundamentals',
      courseId: 'smets-001',
      progressPercent: 25,
      modules: [
        LearningModule(
          id: 'mod_1',
          title: 'Introduction',
          isLocked: false,
          isCompleted: false,
          isExpanded: true,
          lessons: [
            const Lesson(
              id: 'lesson_1_1',
              title: '1.1 Welcome to SMETS',
              moduleId: 'mod_1',
              durationMinutes: 12,
              isCompleted: true,
              isCurrent: false,
            ),
            const Lesson(
              id: 'lesson_1_2',
              title: '1.2 Workspace Overview',
              moduleId: 'mod_1',
              durationMinutes: 15,
              isCompleted: true,
              isCurrent: true, // Current lesson
            ),
          ],
        ),
        LearningModule(
          id: 'mod_2',
          title: 'Core Principles',
          isLocked: false,
          isCompleted: false,
          isExpanded: false,
          lessons: [
            const Lesson(
              id: 'lesson_2_1',
              title: '2.1 SMETS Architecture',
              moduleId: 'mod_2',
              durationMinutes: 20,
              isCompleted: false,
              isCurrent: false,
            ),
            const Lesson(
              id: 'lesson_2_2',
              title: '2.2 Data Synchronization',
              moduleId: 'mod_2',
              durationMinutes: 18,
              isCompleted: false,
              isCurrent: false,
            ),
            const Lesson(
              id: 'lesson_2_3',
              title: '2.3 Grid Integration',
              moduleId: 'mod_2',
              durationMinutes: 22,
              isCompleted: false,
              isCurrent: false,
            ),
          ],
        ),
        LearningModule(
          id: 'mod_3',
          title: 'Advanced SMETS',
          isLocked: true,
          isCompleted: false,
          isExpanded: false,
          lessons: [
            const Lesson(
              id: 'lesson_3_1',
              title: '3.1 Advanced Configuration',
              moduleId: 'mod_3',
              durationMinutes: 25,
              isCompleted: false,
              isCurrent: false,
            ),
            const Lesson(
              id: 'lesson_3_2',
              title: '3.2 Troubleshooting',
              moduleId: 'mod_3',
              durationMinutes: 30,
              isCompleted: false,
              isCurrent: false,
            ),
          ],
        ),
        LearningModule(
          id: 'mod_4',
          title: 'Final Assessment',
          isLocked: true,
          isCompleted: false,
          isExpanded: false,
          lessons: [
            const Lesson(
              id: 'lesson_4_1',
              title: 'Final Exam',
              moduleId: 'mod_4',
              durationMinutes: 60,
              isCompleted: false,
              isCurrent: false,
            ),
          ],
        ),
      ],
    );
  }

  static LessonContent _mockLessonContent(String lessonId) {
    return LessonContent(
      title: '1.1 Welcome to SMETS',
      thumbnailUrl: 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=800',
      videoDurationSeconds: 765, // 12:45
      currentPositionSeconds: 262, // 04:22
      level: 'Cơ bản',
      description: 'Chào mừng đến với SMETS Learning Workspace. Trong module giới thiệu này, chúng ta sẽ khám phá các nền tảng cốt lõi của khung Smart Metering và Energy Technical Systems. Bài học này sẽ là cửa ngõ để bạn hiểu cách dữ liệu năng lượng được đồng bộ hóa trong các kiến trúc lưới điện hiện đại.',
      keyTakeaways: [
        'Hiểu lịch sử và sự phát triển của tiêu chuẩn SMETS',
        'Xác định các bên liên quan chính trong vòng đời đồng bộ hóa năng lượng',
        'Tìm hiểu cách điều hướng tài liệu kỹ thuật được cung cấp trong các module sau',
      ],
      resources: const [
        LessonResource(
          id: 'res_1',
          title: 'SMETS_Guide_V1.pdf',
          type: 'pdf',
          fileSize: '2.4 MB',
        ),
        LessonResource(
          id: 'res_2',
          title: 'Official Documentation',
          type: 'link',
          url: 'https://example.com/docs',
        ),
        LessonResource(
          id: 'res_3',
          title: 'Installation Guide',
          type: 'pdf',
          fileSize: '1.8 MB',
        ),
      ],
      discussions: _mockDiscussions(),
      transcript: '''
Welcome to the SMETS Learning Workspace.

In this introductory module, we'll explore the core foundations of the Smart Metering and Energy Technical Systems framework.

[Transcript continues...]
''',
      nextLesson: const Lesson(
        id: 'lesson_1_2',
        title: '1.2 Workspace Overview & Navigation',
        moduleId: 'mod_1',
        durationMinutes: 15,
        isCompleted: false,
        isCurrent: false,
      ),
    );
  }

  static List<Discussion> _mockDiscussions() {
    return const [
      Discussion(
        id: 'disc_1',
        userName: 'Nguyễn Văn A',
        comment: 'Bài giảng rất hay và dễ hiểu! Cảm ơn thầy.',
        timeAgo: '2 giờ trước',
        replyCount: 3,
      ),
      Discussion(
        id: 'disc_2',
        userName: 'Trần Thị B',
        comment: 'Cho hỏi phần SMETS architecture có tài liệu chi tiết không ạ?',
        timeAgo: '5 giờ trước',
        replyCount: 2,
      ),
      Discussion(
        id: 'disc_3',
        userName: 'Lê Văn C',
        comment: 'Rất hữu ích cho công việc của tôi. Đã áp dụng được vào dự án.',
        timeAgo: '1 ngày trước',
        replyCount: 0,
      ),
    ];
  }

  // ============================================================
  // HELPER METHODS - Các hàm hỗ trợ
  // ============================================================

  /// Format thời gian từ giây sang mm:ss
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Format số thành chuỗi có định dạng
  static String formatFileSize(String? size) {
    return size ?? '';
  }
}
