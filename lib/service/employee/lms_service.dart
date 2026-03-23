import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/learning_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/page/employee/course_detail/widgets/course_syllabus.dart';
import 'package:smet/page/employee/course_detail/widgets/course_reviews.dart';
import 'dart:developer';

// ============================================================
// LMS SERVICE — API thật cho Enrollment, Course, Lesson,
// Progress, Certificate, LiveSession, GlobalSearch
// ============================================================

class LmsService {
  // ============================================================
  // COURSE PROGRESS — GET /api/lms/enrollments/courses/{courseId}/progress
  // ============================================================

  static Future<LearningCourse> getCourseProgress(
    String courseId,
    String userId,
  ) async {
    try {
      final token = await AuthService.getToken();

      // 1. Lấy danh sách modules của khóa học
      final modulesUrl = Uri.parse("$baseUrl/lms/modules/course/$courseId");
      final modulesRes = await http.get(
        modulesUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET MODULES STATUS: ${modulesRes.statusCode}, courseId=$courseId");

      if (modulesRes.statusCode != 200) {
        throw Exception("Không thể tải danh sách module");
      }

      final modulesJson = jsonDecode(modulesRes.body) as List<dynamic>;
      final List<LearningModule> modules = [];

      // 2. Với mỗi module, lấy danh sách lessons và progress
      for (final m in modulesJson) {
        final moduleId = m['id'].toString();

        // Lấy lessons của module
        final lessonsUrl = Uri.parse("$baseUrl/lms/lessons/module/$moduleId");
        final lessonsRes = await http.get(
          lessonsUrl,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        List<Lesson> lessons = [];
        if (lessonsRes.statusCode == 200) {
          final lessonsJson = jsonDecode(lessonsRes.body) as List<dynamic>;
          lessons = lessonsJson.map((l) => _parseLesson(l)).toList();
        }

        modules.add(LearningModule(
          id: moduleId,
          title: m['title'] ?? '',
          isLocked: false,
          isCompleted: false,
          isExpanded: false,
          lessons: lessons,
        ));
      }

      // 3. Tính progress của từng module
      double totalProgress = 0;

      for (int i = 0; i < modules.length; i++) {
        final moduleId = modules[i].id;
        try {
          final progressUrl = Uri.parse("$baseUrl/lms/lessons/modules/$moduleId/progress");
          final progressRes = await http.get(
            progressUrl,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          );

          if (progressRes.statusCode == 200) {
            final progressValue = (jsonDecode(progressRes.body) as num).toDouble();
            final isCompleted = progressValue >= 1.0;
            totalProgress += progressValue;

            modules[i] = LearningModule(
              id: moduleId,
              title: modules[i].title,
              isLocked: modules[i].isLocked,
              isCompleted: isCompleted,
              isExpanded: modules[i].isExpanded,
              lessons: modules[i].lessons,
            );
          }
        } catch (_) {
          // Progress endpoint có thể chưa có → bỏ qua
        }
      }

      final courseProgress = modules.isEmpty ? 0.0 : (totalProgress / modules.length * 100);

      log("GET COURSE PROGRESS SUCCESS: courseId=$courseId, modules=${modules.length}, progress=$courseProgress%");

      return LearningCourse(
        id: courseId,
        title: '',
        courseId: courseId,
        progressPercent: courseProgress,
        modules: modules,
      );
    } catch (e) {
      log("LmsService.getCourseProgress failed: $e");
      rethrow;
    }
  }

  static Lesson _parseLesson(Map<String, dynamic> l) {
    return Lesson(
      id: l['id']?.toString() ?? '',
      title: l['title'] ?? '',
      moduleId: l['moduleId']?.toString() ?? l['module_id']?.toString() ?? '',
      durationMinutes: l['durationMinutes'] ?? l['duration_minutes'] ?? 0,
      isCompleted: l['isCompleted'] ?? l['completed'] ?? false,
      isCurrent: l['isCurrent'] ?? l['current'] ?? false,
    );
  }

  // ============================================================
  // LESSON CONTENTS — GET /api/lms/lessons/{lessonId}/contents
  // ============================================================

  static Future<LessonContent> getLessonDetail(String lessonId) async {
    try {
      final token = await AuthService.getToken();

      // 1. Lấy danh sách contents của lesson
      final url = Uri.parse("$baseUrl/lms/lessons/$lessonId/contents");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET LESSON CONTENTS STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> contentsJson = jsonDecode(response.body);
        log("GET LESSON CONTENTS SUCCESS: count=${contentsJson.length}");

        // Lấy content đầu tiên hoặc tạo rỗng
        final firstContent = contentsJson.isNotEmpty ? contentsJson.first as Map<String, dynamic> : null;

        return LessonContent(
          id: lessonId,
          title: firstContent?['title'] ?? 'Bài học',
          videoUrl: null,
          thumbnailUrl: firstContent?['thumbnailUrl']?.toString(),
          videoDurationSeconds: 0,
          currentPositionSeconds: 0,
          level: '',
          description: firstContent?['content'] ?? '',
          keyTakeaways: [],
          resources: [],
          discussions: [],
          transcript: null,
        );
      }

      log("GET LESSON CONTENTS FAILED: status=${response.statusCode}, body=${response.body}");
      throw Exception("Không thể tải nội dung bài học");
    } catch (e) {
      log("LmsService.getLessonDetail failed: $e");
      rethrow;
    }
  }

  // ============================================================
  // MARK LESSON COMPLETE — POST /api/lms/lessons/{lessonId}/complete
  // ============================================================

  static Future<bool> markLessonComplete(
    String lessonId,
    String userId,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/lessons/$lessonId/complete");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("MARK LESSON COMPLETE STATUS: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      log("MARK LESSON COMPLETE FAILED: status=${response.statusCode}, lessonId=$lessonId, body=${response.body}");
      return false;
    } catch (e) {
      log("LmsService.markLessonComplete failed: $e");
      return false;
    }
  }

  // ============================================================
  // UPDATE VIDEO PROGRESS — PUT /api/lms/lessons/{lessonId}/progress
  // ============================================================

  static Future<bool> updateVideoProgress(
    String lessonId,
    String userId,
    int position,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/lessons/$lessonId/progress");

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'userId': userId,
          'position': position,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      log("LmsService.updateVideoProgress failed: $e");
      return false;
    }
  }

  // ============================================================
  // DISCUSSIONS — GET /api/lms/lessons/{lessonId}/discussions
  // ============================================================

  static Future<List<Discussion>> getDiscussions(String lessonId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/lessons/$lessonId/discussions");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = data['data'] ?? data['content'] ?? [];
        } else {
          list = [];
        }
        return list.map((d) => Discussion(
          id: d['id']?.toString() ?? '',
          userName: d['userName'] ?? d['user_name'] ?? 'User',
          avatarUrl: d['avatarUrl']?.toString(),
          comment: d['comment'] ?? d['content'] ?? '',
          timeAgo: d['timeAgo'] ?? d['time_ago'] ?? '',
          replyCount: d['replyCount'] ?? d['reply_count'] ?? 0,
        )).toList();
      }
      return [];
    } catch (e) {
      log("LmsService.getDiscussions failed: $e");
      return [];
    }
  }

  // ============================================================
  // POST DISCUSSION — POST /api/lms/lessons/{lessonId}/discussions
  // ============================================================

  static Future<Discussion> postDiscussion(
    String lessonId,
    String userId,
    String comment,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/lessons/$lessonId/discussions");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'userId': userId,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Discussion(
          id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userName: data['userName'] ?? 'Bạn',
          avatarUrl: data['avatarUrl']?.toString(),
          comment: data['comment'] ?? comment,
          timeAgo: 'Vừa xong',
          replyCount: 0,
        );
      }
      log("POST DISCUSSION FAILED: status=${response.statusCode}, body=${response.body}");
      throw Exception("Không thể gửi bình luận");
    } catch (e) {
      log("LmsService.postDiscussion failed: $e");
      rethrow;
    }
  }

  // ============================================================
  // UTILITY
  // ============================================================

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // COURSE DETAIL — GET /api/lms/courses/{id}
  // ============================================================

  static Future<CourseDetail> getCourseDetail(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/courses/$courseId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET COURSE DETAIL STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseCourseDetail(data, courseId);
      } else {
        log("GET COURSE DETAIL FAILED: status=${response.statusCode}, courseId=$courseId, body=${response.body}");
        throw Exception("Không thể tải chi tiết khóa học");
      }
    } catch (e) {
      log("LmsService.getCourseDetail failed: $e");
      rethrow;
    }
  }

  // ============================================================
  // ENROLLMENT — Đăng ký / Rời khỏi khóa học
  // ============================================================

  /// Đăng ký khóa học — POST /api/lms/enrollments/courses/{courseId}
  static Future<bool> enrollCourse(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/enrollments/courses/$courseId");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // 200/201 = enrolled successfully, 400 with "Already enrolled" = already enrolled (OK)
      if (response.statusCode == 200 || response.statusCode == 201) {
        log("ENROLL COURSE SUCCESS: courseId=$courseId, status=${response.statusCode}, body=${response.body}");
        return true;
      }
      if (response.statusCode == 400) {
        final body = response.body;
        log("ENROLL COURSE 400: courseId=$courseId, body=$body");
        if (body.contains('Already enrolled') ||
            body.contains('already enrolled')) {
          return true; // Already enrolled — treat as success
        }
      }
      log("ENROLL COURSE FAILED: courseId=$courseId, status=${response.statusCode}, body=${response.body}");
      return false;
    } catch (e) {
      log("LmsService.enrollCourse using fallback: $e");
      return false;
    }
  }

  /// Rời khỏi khóa học — DELETE /api/lms/enrollments/courses/{courseId}
  static Future<bool> leaveCourse(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/enrollments/courses/$courseId");

      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("LEAVE COURSE RESPONSE: status=${response.statusCode}, courseId=$courseId, body=${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      log("LmsService.leaveCourse failed: $e");
      return false;
    }
  }

  /// Kiểm tra đã đăng ký chưa — GET /api/lms/courses/{courseId}/completion
  static Future<bool> isEnrolled(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/lms/courses/courses/$courseId/completion",
      );

      log("IS ENROLLED REQUEST: courseId=$courseId, url=$url");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("IS ENROLLED RESPONSE: status=${response.statusCode}, body=${response.body}, courseId=$courseId");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is bool) return data;
        return data is Map && data['completed'] == true;
      }
      log("IS ENROLLED FAILED: status=${response.statusCode}, courseId=$courseId");
      return false;
    } catch (e) {
      log("LmsService.isEnrolled: $e");
      return false;
    }
  }

  /// Lấy danh sách khóa học đã đăng ký — GET /api/lms/enrollments/my-courses
  static Future<List<EnrolledCourse>> getMyCourses({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/lms/enrollments/my-courses?page=$page&size=$size",
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> content;

        if (data is List) {
          // Backend trả thẳng một List
          content = data;
        } else if (data is Map) {
          // Backend trả paginated response — thử "content" trước, fallback sang "data"
          final rawContent = data['content'] ?? data['data'];
          if (rawContent is List) {
            content = rawContent;
          } else {
            log("GET MY COURSES PARSE ERROR: no valid list found in response, data=$data");
            return [];
          }
        } else {
          log("GET MY COURSES PARSE ERROR: unexpected response type, data=$data");
          return [];
        }

        log("GET MY COURSES SUCCESS: page=$page, size=$size, count=${content.length}");
        return content.map((c) => _parseEnrolledCourse(c as Map<String, dynamic>)).toList();
      }
      log("GET MY COURSES FAILED: status=${response.statusCode}, page=$page, body=${response.body}");
      return [];
    } catch (e) {
      log("LmsService.getMyCourses: $e");
      return [];
    }
  }

  // ============================================================
  // LESSON — Nội dung và hoàn thành bài học
  // ============================================================

  /// Hoàn thành bài học — POST /api/lms/enrollments/lessons/{lessonId}/complete
  static Future<bool> completeLesson(String lessonId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/lms/enrollments/lessons/$lessonId/complete",
      );

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("COMPLETE LESSON STATUS: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log("LmsService.completeLesson failed: $e");
      return false;
    }
  }

  /// Lấy nội dung bài học — GET /api/lms/lessons/{lessonId}/contents
  /// Backend trả về List<LessonContentResponse>
  static Future<LessonContent?> getLessonContent(String lessonId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/lessons/$lessonId/contents");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> contentsJson = jsonDecode(response.body);
        if (contentsJson.isEmpty) {
          return null;
        }

        final first = contentsJson.first as Map<String, dynamic>;
        return LessonContent(
          id: lessonId,
          title: first['title'] ?? 'Bài học',
          videoUrl: null,
          thumbnailUrl: first['thumbnailUrl']?.toString(),
          videoDurationSeconds: 0,
          currentPositionSeconds: 0,
          level: '',
          description: first['content'] ?? '',
          keyTakeaways: [],
          resources: [],
          discussions: [],
          transcript: null,
        );
      }
      log("GET LESSON CONTENT FAILED: status=${response.statusCode}, lessonId=$lessonId, body=${response.body}");
      return null;
    } catch (e) {
      log("LmsService.getLessonContent: $e");
      return null;
    }
  }

  // ============================================================
  // CERTIFICATE
  // ============================================================

  /// Lấy chứng chỉ của mình cho khóa — GET /api/lms/certificates/course/{courseId}
  static Future<CertificateInfo?> getMyCertificate(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/certificates/course/$courseId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log("GET MY CERTIFICATE SUCCESS: courseId=$courseId, code=${data['code']}");
        return _parseCertificate(data);
      }
      log("GET MY CERTIFICATE FAILED: status=${response.statusCode}, courseId=$courseId, body=${response.body}");
      return null;
    } catch (e) {
      log("LmsService.getMyCertificate: $e");
      return null;
    }
  }

  /// Verify chứng chỉ — GET /api/lms/certificates/verify/{code}
  static Future<CertificateInfo?> verifyCertificate(String code) async {
    try {
      final url = Uri.parse("$baseUrl/lms/certificates/verify/$code");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log("VERIFY CERTIFICATE SUCCESS: code=$code");
        return _parseCertificate(data);
      }
      log("VERIFY CERTIFICATE FAILED: status=${response.statusCode}, code=$code, body=${response.body}");
      return null;
    } catch (e) {
      log("LmsService.verifyCertificate: $e");
      return null;
    }
  }

  // ============================================================
  // LIVE SESSION
  // ============================================================

  /// Lấy buổi live của khóa — GET /api/lms/live-sessions/course/{courseId}
  static Future<List<LiveSessionInfo>> getLiveSessions(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/live-sessions/course/$courseId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        log("GET LIVE SESSIONS SUCCESS: courseId=$courseId, count=${list.length}");
        return list.map((s) => _parseLiveSession(s)).toList();
      }
      log("GET LIVE SESSIONS FAILED: status=${response.statusCode}, courseId=$courseId, body=${response.body}");
      return [];
    } catch (e) {
      log("LmsService.getLiveSessions: $e");
      return [];
    }
  }

  // ============================================================
  // GLOBAL SEARCH
  // ============================================================

  /// Tìm kiếm toàn hệ thống — GET /api/search?keyword=&page=&size=
  static Future<SearchResult> search(
    String keyword, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/search?keyword=${Uri.encodeComponent(keyword)}&page=$page&size=$size",
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coursesCount = (data['courses'] as List?)?.length ?? 0;
        final pathsCount = (data['learningPaths'] as List?)?.length ?? 0;
        log("SEARCH SUCCESS: keyword=$keyword, courses=$coursesCount, paths=$pathsCount");
        return _parseSearchResult(data);
      }
      log("SEARCH FAILED: status=${response.statusCode}, keyword=$keyword, body=${response.body}");
      return SearchResult(
        keyword: keyword,
        courses: [],
        learningPaths: [],
        totalResults: 0,
      );
    } catch (e) {
      log("LmsService.search: $e");
      return SearchResult(
        keyword: keyword,
        courses: [],
        learningPaths: [],
        totalResults: 0,
      );
    }
  }

  // ============================================================
  // LEARNING PATH (Employee view)
  // ============================================================

  /// Lấy lộ trình được gán — GET /api/lms/learning-paths?assignedToMe=true
  static Future<List<LearningPathInfo>> getMyLearningPaths({
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      var urlStr =
          "$baseUrl/lms/learning-paths?assignedToMe=true&page=$page&size=$size";
      if (keyword != null && keyword.isNotEmpty) {
        urlStr += "&keyword=${Uri.encodeComponent(keyword)}";
      }
      final url = Uri.parse(urlStr);

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List<dynamic>? ?? [];
        log("GET MY LEARNING PATHS SUCCESS: count=${content.length}, keyword=$keyword, page=$page");
        return content.map((lp) => _parseLearningPathInfo(lp)).toList();
      }
      log("GET MY LEARNING PATHS FAILED: status=${response.statusCode}, keyword=$keyword, body=${response.body}");
      return [];
    } catch (e) {
      log("LmsService.getMyLearningPaths: $e");
      return [];
    }
  }

  /// Chi tiết lộ trình — GET /api/lms/learning-paths/{id}
  static Future<LearningPathDetail?> getLearningPathDetail(String id) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/learning-paths/$id");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coursesCount = (data['courses'] as List?)?.length ?? 0;
        log("GET LEARNING PATH DETAIL SUCCESS: id=$id, title=${data['title']}, courses=$coursesCount");
        return _parseLearningPathDetail(data);
      }
      log("GET LEARNING PATH DETAIL FAILED: status=${response.statusCode}, id=$id, body=${response.body}");
      return null;
    } catch (e) {
      log("LmsService.getLearningPathDetail: $e");
      return null;
    }
  }

  // ============================================================
  // PARSING HELPERS
  // ============================================================

  static CourseDetail _parseCourseDetail(
    Map<String, dynamic> data,
    String courseId,
  ) {
    return CourseDetail(
      id: data['id']?.toString() ?? courseId,
      title: data['title'] ?? data['name'] ?? 'Khóa học',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? data['thumbnail'] ?? data['coverImage'],
      duration: _parseDuration(data['duration'] ?? data['estimatedHours']),
      level: data['level'] ?? 'Trung bình',
      rating: (data['rating'] ?? data['averageRating'] ?? 0).toDouble(),
      studentsCount: _formatCount(
        data['enrolledCount'] ?? data['studentCount'] ?? 0,
      ),
      isBestSeller: data['isBestSeller'] ?? data['featured'] ?? false,
      category: data['category'] ?? 'Kỹ thuật',
      videoHours: data['videoHours'] ?? data['totalVideoHours'] ?? 0,
      resources: data['resources'] ?? data['resourceCount'] ?? 0,
      hasCertificate:
          data['hasCertificate'] ?? data['certificateEnabled'] ?? true,
      enrolledCount: data['enrolledCount'] ?? data['studentCount'] ?? 0,
      instructor: _parseInstructor(data['mentor'] ?? data['instructor']),
      modules: _parseModules(data['modules'], data['syllabus']),
      reviews: _parseReviews(data['reviews']),
    );
  }

  static Instructor _parseInstructor(dynamic mentor) {
    if (mentor == null) {
      return const Instructor(name: 'Giảng viên', title: '', bio: '');
    }
    final m = mentor as Map<String, dynamic>;
    return Instructor(
      name: m['name'] ?? m['fullName'] ?? m['email'] ?? 'Giảng viên',
      title: m['title'] ?? m['position'] ?? '',
      avatarUrl: m['avatarUrl'] ?? m['avatar'],
      bio: m['bio'] ?? m['description'] ?? '',
      linkedInUrl: m['linkedIn'],
      websiteUrl: m['website'],
    );
  }

  static List<Module> _parseModules(dynamic modules, dynamic syllabus) {
    final items = (modules ?? syllabus) as List<dynamic>? ?? [];
    return items.map((m) {
      final item = m as Map<String, dynamic>;
      final lessons = (item['lessons'] as List<dynamic>?) ?? [];
      final lessonTitles =
          lessons
              .map((l) => l['title']?.toString() ?? l['name']?.toString() ?? '')
              .toList();
      return Module(
        title: item['title'] ?? item['name'] ?? 'Module',
        lessonCount: lessons.length,
        lessons: lessonTitles,
        isExpanded: false,
        onToggle: () {},
      );
    }).toList();
  }

  static List<Review> _parseReviews(dynamic reviews) {
    if (reviews == null) return [];
    final items = reviews as List<dynamic>;
    return items.map((r) {
      final item = r as Map<String, dynamic>;
      return Review(
        rating: item['rating'] ?? 5,
        comment: item['comment'] ?? item['content'] ?? '',
        userName: item['userName'] ?? item['reviewer'] ?? 'Học viên',
      );
    }).toList();
  }

  static String _parseDuration(dynamic duration) {
    if (duration == null) return '0 tuần';
    if (duration is int) return '$duration tuần';
    return duration.toString();
  }

  static String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k+';
    return '$count';
  }

  static EnrolledCourse _parseEnrolledCourse(Map<String, dynamic> c) {
    return EnrolledCourse(
      id: c['id']?.toString() ?? '',
      title: c['title'] ?? c['name'] ?? 'Khóa học',
      imageUrl: c['imageUrl'] ?? c['thumbnail'],
      progressPercent: (c['progress'] ?? c['progressPercent'] ?? 0).toDouble(),
      enrolledAt:
          DateTime.tryParse(c['enrolledAt'] ?? c['createdAt'] ?? '') ??
          DateTime.now(),
    );
  }

  static CertificateInfo _parseCertificate(Map<String, dynamic> data) {
    return CertificateInfo(
      id: data['id']?.toString() ?? '',
      code: data['code'] ?? data['certificateCode'] ?? '',
      courseName: data['courseName'] ?? data['course']?['title'] ?? '',
      userName: data['userName'] ?? data['user']?['name'] ?? '',
      issuedAt:
          DateTime.tryParse(data['issuedAt'] ?? data['createdAt'] ?? '') ??
          DateTime.now(),
      expiresAt:
          data['expiresAt'] != null
              ? DateTime.tryParse(data['expiresAt'])
              : null,
    );
  }

  static LiveSessionInfo _parseLiveSession(Map<String, dynamic> s) {
    return LiveSessionInfo(
      id: s['id']?.toString() ?? '',
      title: s['title'] ?? '',
      meetingUrl: s['meetingUrl'] ?? s['meeting_link'] ?? '',
      startTime:
          DateTime.tryParse(s['startTime'] ?? s['start_time'] ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(s['endTime'] ?? s['end_time'] ?? '') ??
          DateTime.now(),
    );
  }

  static SearchResult _parseSearchResult(Map<String, dynamic> data) {
    final courses =
        (data['courses'] as List<dynamic>?)?.map((c) {
          final item = c as Map<String, dynamic>;
          return SearchCourseItem(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? item['name'] ?? '',
            description: item['description'] ?? '',
            imageUrl: item['imageUrl'] ?? item['thumbnail'],
          );
        }).toList() ??
        [];

    final paths =
        (data['learningPaths'] as List<dynamic>?)?.map((lp) {
          final item = lp as Map<String, dynamic>;
          return SearchLearningPathItem(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? item['name'] ?? '',
            description: item['description'] ?? '',
            courseCount: item['courseCount'] ?? 0,
          );
        }).toList() ??
        [];

    return SearchResult(
      keyword: data['keyword'] ?? '',
      courses: courses,
      learningPaths: paths,
      totalResults: courses.length + paths.length,
    );
  }

  static LearningPathInfo _parseLearningPathInfo(Map<String, dynamic> lp) {
    return LearningPathInfo(
      id: lp['id']?.toString() ?? '',
      title: lp['title'] ?? lp['name'] ?? '',
      description: lp['description'] ?? '',
      courseCount: lp['courseCount'] ?? 0,
      progressPercent:
          (lp['progress'] ?? lp['progressPercent'] ?? 0).toDouble(),
    );
  }

  static LearningPathDetail _parseLearningPathDetail(Map<String, dynamic> lp) {
    final courses =
        (lp['courses'] as List<dynamic>?)?.map((c) {
          final item = c as Map<String, dynamic>;
          return LearningPathCourseItem(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? item['name'] ?? '',
            orderIndex: item['orderIndex'] ?? 0,
            isCompleted: item['isCompleted'] ?? false,
          );
        }).toList() ??
        [];

    return LearningPathDetail(
      id: lp['id']?.toString() ?? '',
      title: lp['title'] ?? '',
      description: lp['description'] ?? '',
      courses: courses,
    );
  }

}

// ============================================================
// DATA CLASSES — Dùng chung cho LMS
// ============================================================

class EnrolledCourse {
  final String id;
  final String title;
  final String? imageUrl;
  final double progressPercent;
  final DateTime enrolledAt;

  EnrolledCourse({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.progressPercent,
    required this.enrolledAt,
  });
}

class CertificateInfo {
  final String id;
  final String code;
  final String courseName;
  final String userName;
  final DateTime issuedAt;
  final DateTime? expiresAt;

  CertificateInfo({
    required this.id,
    required this.code,
    required this.courseName,
    required this.userName,
    required this.issuedAt,
    this.expiresAt,
  });
}

class LiveSessionInfo {
  final String id;
  final String title;
  final String meetingUrl;
  final DateTime startTime;
  final DateTime endTime;

  LiveSessionInfo({
    required this.id,
    required this.title,
    required this.meetingUrl,
    required this.startTime,
    required this.endTime,
  });
}

class SearchResult {
  final String keyword;
  final List<SearchCourseItem> courses;
  final List<SearchLearningPathItem> learningPaths;
  final int totalResults;

  SearchResult({
    required this.keyword,
    required this.courses,
    required this.learningPaths,
    required this.totalResults,
  });
}

class SearchCourseItem {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;

  SearchCourseItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
  });
}

class SearchLearningPathItem {
  final String id;
  final String title;
  final String description;
  final int courseCount;

  SearchLearningPathItem({
    required this.id,
    required this.title,
    required this.description,
    required this.courseCount,
  });
}

class LearningPathInfo {
  final String id;
  final String title;
  final String description;
  final int courseCount;
  final double progressPercent;

  LearningPathInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.courseCount,
    required this.progressPercent,
  });
}

class LearningPathDetail {
  final String id;
  final String title;
  final String description;
  final List<LearningPathCourseItem> courses;

  LearningPathDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.courses,
  });
}

class LearningPathCourseItem {
  final String id;
  final String title;
  final int orderIndex;
  final bool isCompleted;

  LearningPathCourseItem({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.isCompleted,
  });
}
