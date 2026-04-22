import 'dart:convert';
import 'dart:math' hide log;
import 'package:http/http.dart' as http;
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/learning_path_model.dart' as lpm;
import 'package:smet/service/employee/quiz_service.dart';
import 'dart:developer';

// ============================================================
// LMS SERVICE — API thật cho Enrollment, Course, Lesson,
// Progress, Certificate, LiveSession, GlobalSearch
// ============================================================

class LmsService {
  // ============================================================
  // COURSE PROGRESS
  // Theo rule: KHONG tu tinh progress o FE, luon lay tu backend
  // API: GET /courses/{courseId} tra ve progress (0-100%)
  // API: GET /lessons/modules/{moduleId}/progress tra ve module progress (0.0-1.0)
  // ============================================================

  static Future<LearningCourse> getCourseProgress(
    String courseId,
    String userId,
  ) async {
    try {
      final token = await AuthService.getToken();

      // 1. Lay course detail tu backend - chua progress, enrollmentStatus, modules
      final courseUrl = Uri.parse("$baseUrl/lms/courses/$courseId");
      final courseRes = await http.get(
        courseUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (courseRes.statusCode != 200) {
        throw Exception("Khong the tai chi tiet khoa hoc");
      }

      final courseData = jsonDecode(courseRes.body) as Map<String, dynamic>;
      final courseProgress = (courseData['progress'] ?? 0).toDouble();

      // 2. Lay module progress tu backend + quiz cua tung module (goi song song)
      final modulesJson = courseData['modules'] as List<dynamic>? ?? [];

      // Goi quiz API cho tat ca module cung luc
      final List<String?> moduleIds = modulesJson.map<String?>((m) => m['id']?.toString()).toList();
      final List<QuizInfo?> moduleQuizzes = await Future.wait(
        moduleIds.map((id) => id != null ? QuizService.getQuizByModule(id) : Future.value(null)),
      );

      final List<LearningModule> modules = [];
      for (int i = 0; i < modulesJson.length; i++) {
        final m = modulesJson[i];
        final moduleId = m['id'].toString();

        // Lay lessons cua module
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

        // Lay module progress tu API
        double moduleProgress = 0.0;
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
            moduleProgress = (jsonDecode(progressRes.body) as num).toDouble();
          }
        } catch (_) {}

        // Quiz info tu API
        final quizInfo = moduleQuizzes[i];
        final quizId = quizInfo?.id;
        bool quizPassed = false;
        bool hasQuizAttempts = false;
        if (quizId != null) {
          final history = await QuizService.getAttemptHistory(quizId);
          hasQuizAttempts = history.isNotEmpty;
          quizPassed = history.any((h) => h.passed);
        }

        modules.add(LearningModule(
          id: moduleId,
          title: m['title'] ?? '',
          isLocked: m['isLocked'] == true || m['isLocked'] == 'true',
          // Module completed = progress 100% VÀ quiz passed (nếu có quiz)
          isCompleted: moduleProgress >= 1.0 && (quizId == null || quizPassed),
          isExpanded: false,
          lessons: lessons,
          quizId: quizId,
          quizPassed: quizPassed,
          hasQuizAttempts: hasQuizAttempts,
          progress: moduleProgress,
        ));
      }

      log("GET COURSE PROGRESS SUCCESS: courseId=$courseId, progress=$courseProgress%");

      // Parse enrollmentStatus từ backend — đã bao gồm quiz trong phép tính COMPLETED
      final enrollmentStatus = courseData['enrollmentStatus']?.toString() ?? 'NOT_STARTED';

      return LearningCourse(
        id: courseId,
        title: courseData['title'] ?? '',
        courseId: courseId,
        progressPercent: courseProgress,
        modules: modules,
        mentorId: courseData['mentorId'] ?? 0,
        mentorName: courseData['mentorName'] ?? 'Giảng viên',
        enrollmentStatus: enrollmentStatus,
      );
    } catch (e) {
      log("LmsService.getCourseProgress failed: $e");
      rethrow;
    }
  }

  static Lesson _parseLesson(Map<String, dynamic> l) {
    LessonType lessonType = LessonType.video;

    final contents = l['contents'] as List<dynamic>?;
    if (contents != null && contents.isNotEmpty) {
      final firstContent = contents.first as Map<String, dynamic>?;
      final typeStr = (firstContent?['type']?.toString() ?? 'VIDEO').toUpperCase();
      if (typeStr == 'TEXT') {
        lessonType = LessonType.text;
      } else if (typeStr == 'LINK') {
        lessonType = LessonType.link;
      } else if (typeStr == 'VIDEO') {
        lessonType = LessonType.video;
      }
    }

    return Lesson(
      id: l['id']?.toString() ?? '',
      title: l['title'] ?? '',
      moduleId: l['moduleId']?.toString() ?? l['module_id']?.toString() ?? '',
      durationMinutes: l['durationMinutes'] ?? l['duration_minutes'] ?? 0,
      isCompleted: l['isCompleted'] ?? l['completed'] ?? false,
      isCurrent: l['isCurrent'] ?? l['current'] ?? false,
      lessonType: lessonType,
    );
  }

  /// Extract YouTube video ID from various input formats
  /// Input: full YouTube URL, short URL, or already-extracted ID
  /// Output: YouTube video ID or null
  static String? _extractYouTubeId(Map<String, dynamic>? content) {
    if (content == null) return null;

    // If backend already set a thumbnailUrl (YouTube hqdefault), use content as ID directly
    String? contentValue = content['content']?.toString();
    if (contentValue == null || contentValue.isEmpty) return null;

    // Check if content is already a plain YouTube ID (11 chars)
    final isPlainId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(contentValue);
    if (isPlainId) {
      log("YouTube video ID extracted: $contentValue");
      return contentValue;
    }

    // Extract from full URL
    // youtu.be/ID
    if (contentValue.contains('youtu.be/')) {
      String id = contentValue.substring(contentValue.lastIndexOf('/') + 1);
      log("YouTube video ID from youtu.be: $id");
      return id;
    }

    // watch?v=ID
    if (contentValue.contains('v=')) {
      String id = contentValue.substring(contentValue.indexOf('v=') + 2);
      int amp = id.indexOf('&');
      if (amp != -1) id = id.substring(0, amp);
      log("YouTube video ID from watch?v=: $id");
      return id;
    }

    // embed/ID
    if (contentValue.contains('/embed/')) {
      String id = contentValue.substring(contentValue.lastIndexOf('/embed/') + 7);
      log("YouTube video ID from embed: $id");
      return id;
    }

    return null;
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
          youtubeVideoId: _extractYouTubeId(firstContent),
          thumbnailUrl: firstContent?['thumbnailUrl']?.toString() ?? firstContent?['thumbnail_url']?.toString(),
          videoDurationSeconds: firstContent?['videoDurationSeconds'] ?? firstContent?['duration'] ?? 0,
          currentPositionSeconds: firstContent?['currentPositionSeconds'] ?? 0,
          level: firstContent?['level'] ?? '',
          description: firstContent?['content'] ?? '',
          content: firstContent?['content']?.toString(),
          contentType: firstContent?['type']?.toString(),
          keyTakeaways: (firstContent?['keyTakeaways'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          resources: (firstContent?['resources'] as List<dynamic>?)?.map((r) => LessonResource(
            id: r['id']?.toString() ?? '',
            title: r['title'] ?? '',
            type: r['type'] ?? 'link',
            url: r['url']?.toString(),
            fileSize: r['fileSize']?.toString(),
          )).toList() ?? [],
          discussions: [],
          transcript: firstContent?['transcript']?.toString(),
          isCompleted: firstContent?['isCompleted'] ?? firstContent?['completed'] ?? false,
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
  // CHAT / DISCUSSION — GET /api/chat/messages
  // Maps backend ChatMessageResponse to Discussion model.
  // Backend returns: id(Long), senderId(Long), content(String), createdAt(LocalDateTime)
  // ============================================================

  /// Returns (messages, totalCount). totalCount = -1 if pagination info unavailable.
  static Future<(List<Discussion>, int)> getChatMessages(
    String lessonId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/chat/messages?lessonId=$lessonId&page=$page&size=$size",
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("GET CHAT MESSAGES STATUS: ${response.statusCode}, lessonId=$lessonId");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> list;
        int totalCount = 0;

        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = data['content'] ?? data['data'] ?? [];
          totalCount = (data['totalElements'] ?? data['totalElements'] ?? list.length) as int;
        } else {
          list = [];
        }

        final currentUser = await AuthService.getCurrentUser();
        final currentUserId = currentUser.id;

        final discussions = list.map((m) {
          final senderId = m['senderId'] is int
              ? m['senderId'] as int
              : int.tryParse(m['senderId']?.toString() ?? '0') ?? 0;
          final isCurrentUser = senderId == currentUserId;

          DateTime createdAt;
          try {
            createdAt = DateTime.parse(m['createdAt']?.toString() ?? '');
          } catch (_) {
            createdAt = DateTime.now();
          }

          return Discussion(
            id: m['id'] is int
                ? m['id'] as int
                : int.tryParse(m['id']?.toString() ?? '0') ?? 0,
            senderId: senderId,
            senderName: isCurrentUser
                ? (currentUser.fullName.isNotEmpty
                    ? currentUser.fullName
                    : 'Bạn')
                : (m['senderName']?.toString() ?? m['senderName'] ?? 'Người dùng'),
            senderAvatarUrl:
                isCurrentUser ? currentUser.avatarUrl : m['senderAvatarUrl'],
            content: m['content']?.toString() ?? '',
            createdAt: createdAt,
            replyCount: 0,
          );
        }).toList();

        return (discussions, totalCount);
      }

      log("GET CHAT MESSAGES FAILED: status=${response.statusCode}, lessonId=$lessonId, body=${response.body}");
      return (<Discussion>[], 0);
    } catch (e) {
      log("LmsService.getChatMessages failed: $e");
      return (<Discussion>[], 0);
    }
  }

  // ============================================================
  // SEND CHAT MESSAGE — POST /api/chat/send
  // Backend expects: lessonId(Long), content(String), clientMessageId(String)
  // ============================================================

  static Future<Discussion?> sendChatMessage(
    String lessonId,
    String content,
  ) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/chat/send?lessonId=$lessonId");

      final clientMessageId =
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'content': content,
          'clientMessageId': clientMessageId,
        }),
      );

      log("SEND CHAT MESSAGE STATUS: ${response.statusCode}, lessonId=$lessonId");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final currentUser = await AuthService.getCurrentUser();
        return Discussion(
          id: -1, // Backend doesn't return the created message; use -1 as temp
          senderId: currentUser.id,
          senderName:
              currentUser.fullName.isNotEmpty ? currentUser.fullName : 'Bạn',
          senderAvatarUrl: currentUser.avatarUrl,
          content: content,
          createdAt: DateTime.now(),
          replyCount: 0,
        );
      }

      log("SEND CHAT MESSAGE FAILED: status=${response.statusCode}, lessonId=$lessonId, body=${response.body}");
      return null;
    } catch (e) {
      log("LmsService.sendChatMessage failed: $e");
      return null;
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

  /// Trích xuất metadata phân trang từ HTTP headers của Spring Data Pageable.
  /// Spring trả các header: X-Total-Count, X-Total-Pages, X-Page-Number, X-Page-Size
  static _PaginationMeta _parsePaginationFromHeaders(
    Map<String, String> headers,
    int requestedPage,
    int requestedSize,
    int listLength,
  ) {
    final totalElements = int.tryParse(headers['x-total-count'] ?? '')
        ?? int.tryParse(headers['X-Total-Count'] ?? '')
        ?? int.tryParse(headers['total-elements'] ?? '')
        ?? int.tryParse(headers['Total-Count'] ?? '')
        ?? (headers['content-range'] != null
            ? int.tryParse(headers['content-range']!.split('/').last)
            : null)
        ?? listLength;

    final totalPages = int.tryParse(headers['x-total-pages'] ?? '')
        ?? int.tryParse(headers['X-Total-Pages'] ?? '')
        ?? int.tryParse(headers['total-pages'] ?? '')
        ?? int.tryParse(headers['Total-Pages'] ?? '')
        ?? (totalElements > 0 ? (totalElements / requestedSize).ceil() : 1);

    final pageNumber = int.tryParse(headers['x-page-number'] ?? '')
        ?? int.tryParse(headers['X-Page-Number'] ?? '')
        ?? requestedPage;

    return _PaginationMeta(
      totalElements: totalElements,
      totalPages: totalPages,
      pageNumber: pageNumber,
    );
  }

  // ============================================================
  // COURSE DETAIL — GET /api/lms/courses/{id}
  // ============================================================

  static Future<CourseDetail> getCourseDetail(String courseId) async {
    try {
      final token = await AuthService.getToken();
      // === DEBUG: log token và user ID từ frontend ===
      log(">>> [DEBUG] getCourseDetail — token=${token != null ? token.substring(0, min(30, token.length)) + '...' : 'NULL'}");
      // Decode JWT payload để lấy user ID (base64 decode phần giữa)
      if (token != null) {
        final parts = token.split('.');
        if (parts.length >= 2) {
          try {
            String b64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
            while (b64.length % 4 != 0) b64 += '=';
            final payload = utf8.decode(base64Decode(b64));
            final decoded = jsonDecode(payload);
            log(">>> [DEBUG] JWT payload — userId=${decoded['userId'] ?? decoded['sub'] ?? decoded['id'] ?? 'UNKNOWN'}, email=${decoded['email'] ?? 'UNKNOWN'}");
          } catch (_) {
            log(">>> [DEBUG] JWT decode failed");
          }
        }
      }
      // === END DEBUG ===
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
        // DEBUG: log raw enrolled field from backend
        log(">>> API RESPONSE: enrolled=${data['enrolled']}, enrollmentStatus=${data['enrollmentStatus']}, progress=${data['progress']}");
        return _parseCourseDetail(data, courseId);
      } else {
        log("GET COURSE DETAIL FAILED: status=${response.statusCode}, courseId=$courseId, body=${response.body}");
        // Neu 200 nhung body co enrolled: true → van lay duoc data
        // Neu khong phai 200 → throw de fallback xu ly
        throw Exception("[$response.statusCode] Khong the tai chi tiet khoa hoc");
      }
    } catch (e) {
      log("LmsService.getCourseDetail failed: $e");
      rethrow;
    }
  }

  // ============================================================
  // ENROLLMENT — Dang ky / Roi khoa hoc
  // ============================================================

  /// Kiem tra da dang ky chua — GET /api/lms/courses/{courseId}/enrollment
  static Future<bool> enrollCourse(String courseId) async {
    try {
      final token = await AuthService.getToken();
      // === DEBUG: log token và user ID trước khi enroll ===
      log(">>> [DEBUG] enrollCourse — token=${token != null ? token.substring(0, min(30, token.length)) + '...' : 'NULL'}");
      if (token != null) {
        final parts = token.split('.');
        if (parts.length >= 2) {
          try {
            String b64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
            while (b64.length % 4 != 0) b64 += '=';
            final payload = utf8.decode(base64Decode(b64));
            final decoded = jsonDecode(payload);
            log(">>> [DEBUG] enrollCourse JWT — userId=${decoded['userId'] ?? decoded['sub'] ?? decoded['id'] ?? 'UNKNOWN'}");
          } catch (_) {
            log(">>> [DEBUG] enrollCourse JWT decode failed");
          }
        }
      }
      // === END DEBUG ===
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
        log(">>> [DEBUG] enrollCourse SUCCESS — courseId=$courseId, status=${response.statusCode}, body=${response.body}");
        return true;
      }
      if (response.statusCode == 400) {
        final body = response.body;
        log(">>> [DEBUG] enrollCourse 400 — courseId=$courseId, body=$body");
        if (body.contains('Already enrolled') ||
            body.contains('already enrolled')) {
          log(">>> [DEBUG] enrollCourse — 'Already enrolled' detected, treating as success");
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

  /// Kiểm tra đã đăng ký chưa — GET /api/lms/courses/{courseId}/enrollment
  static Future<bool> isEnrolled(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse(
        "$baseUrl/lms/courses/$courseId/enrollment",
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
        return data is Map && data['enrolled'] == true;
      }
      log("IS ENROLLED FAILED: status=${response.statusCode}, courseId=$courseId");
      return false;
    } catch (e) {
      log("LmsService.isEnrolled: $e");
      return false;
    }
  }

  /// Lấy danh sách khóa học đã đăng ký — GET /api/lms/enrollments/my-courses
  static Future<PageResponse<EnrolledCourse>> getMyCourses({
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

        List<EnrolledCourse> parseCourses(List<dynamic> list) {
          return list.map((c) => _parseEnrolledCourse(c as Map<String, dynamic>)).toList();
        }

        List<EnrolledCourse> courses;
        if (data is List) {
          courses = parseCourses(data);
        } else if (data is Map) {
          final Map<String, dynamic> typedData = Map<String, dynamic>.from(data);
          final parsed = PageResponse.fromJson(typedData, _parseEnrolledCourse);
          courses = parsed.content;
        } else {
          log("GET MY COURSES PARSE ERROR: unexpected response type, data=$data");
          return PageResponse(
            content: [], totalElements: 0, totalPages: 0,
            number: 0, size: size, first: true, last: true,
          );
        }

        final totalElements = data is Map ? (data['totalElements'] ?? courses.length) : courses.length;
        final tp = data is Map ? (data['totalPages'] ?? 1) : 1;

        return PageResponse(
          content: courses,
          totalElements: totalElements is int ? totalElements : courses.length,
          totalPages: tp is int ? tp : 1,
          number: page,
          size: size,
          first: page == 0,
          last: page >= (tp is int ? tp : 1) - 1,
        );
      }
      log("GET MY COURSES FAILED: status=${response.statusCode}, page=$page");
      return PageResponse(
        content: [], totalElements: 0, totalPages: 0,
        number: 0, size: size, first: true, last: true,
      );
    } catch (e) {
      log("LmsService.getMyCourses: $e");
      return PageResponse(
        content: [], totalElements: 0, totalPages: 0,
        number: 0, size: size, first: true, last: true,
      );
    }
  }

  // ============================================================
  // COURSE CATALOG — Lấy tất cả khóa học (public/employee)
  // ============================================================

  /// Lấy danh sách tất cả khóa học — GET /api/lms/courses
  static Future<PageResponse<CatalogCourse>> getCourses({
    String? keyword,
    String? departmentId,
    String? status,
    bool? isMine,
    String? enrollmentStatus,
    int page = 0,
    int size = 12,
  }) async {
    try {
      final token = await AuthService.getToken();

      var urlStr = "$baseUrl/lms/courses?page=$page&size=$size";
      if (keyword != null && keyword.isNotEmpty) {
        urlStr += "&keyword=${Uri.encodeComponent(keyword)}";
      }
      if (departmentId != null && departmentId.isNotEmpty) {
        urlStr += "&departmentId=$departmentId";
      }
      if (status != null && status.isNotEmpty) {
        urlStr += "&status=$status";
      }
      if (isMine != null) {
        urlStr += "&isMine=$isMine";
      }
      if (enrollmentStatus != null && enrollmentStatus.isNotEmpty) {
        urlStr += "&enrollmentStatus=$enrollmentStatus";
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

        // Trường hợp 1: backend trả Map với field "data" chứa list
        if (data is Map) {
          final Map<String, dynamic> typedData = Map<String, dynamic>.from(data);

          // Nếu field "data" bên trong Map là List (backend trả {data: [...]})
          if (typedData['data'] is List) {
            final rawList = typedData['data'] as List<dynamic>;
            final totalElements = rawList.length;
            final totalPages = totalElements > 0 ? (totalElements / size).ceil() : 1;
            int parseInt(dynamic v) {
              if (v == null) return 0;
              if (v is int) return v;
              if (v is double) return v.toInt();
              if (v is String) return int.tryParse(v) ?? 0;
              return 0;
            }
            return PageResponse(
              content: rawList
                  .map((e) => _parseCatalogCourse(e as Map<String, dynamic>))
                  .toList(),
              totalElements: typedData.containsKey('totalElements')
                  ? parseInt(typedData['totalElements'])
                  : totalElements,
              totalPages: typedData.containsKey('totalPages')
                  ? parseInt(typedData['totalPages'])
                  : totalPages,
              number: parseInt(typedData['page'] ?? typedData['number']),
              size: typedData.containsKey('size')
                  ? parseInt(typedData['size'])
                  : size,
              first: typedData['first'] ?? (page == 0),
              last: typedData['last'] ?? (page >= totalPages - 1),
            );
          }

          // Ngược lại dùng fromJson bình thường
          return PageResponse.fromJson(typedData, _parseCatalogCourse);

        // Trường hợp 2: backend trả List thuần (hoàn toàn không có metadata)
        } else if (data is List) {
          final parsed = _parsePaginationFromHeaders(
              response.headers, page, size, data.length);
          return PageResponse(
            content: data
                .map((c) => _parseCatalogCourse(c as Map<String, dynamic>))
                .toList(),
            totalElements: parsed.totalElements,
            totalPages: parsed.totalPages,
            number: page,
            size: size,
            first: page == 0,
            last: page >= parsed.totalPages - 1,
          );
        }

        log("GET COURSES PARSE ERROR: unexpected response type");
        return PageResponse(
          content: [], totalElements: 0, totalPages: 0,
          number: 0, size: size, first: true, last: true,
        );
      }
      log("GET COURSES FAILED: status=${response.statusCode}, keyword=$keyword");
      return PageResponse(
        content: [], totalElements: 0, totalPages: 0,
        number: 0, size: size, first: true, last: true,
      );
    } catch (e) {
      log("LmsService.getCourses: $e");
      return PageResponse(
        content: [], totalElements: 0, totalPages: 0,
        number: 0, size: size, first: true, last: true,
      );
    }
  }

  static CatalogCourse _parseCatalogCourse(Map<String, dynamic> c) {
    return CatalogCourse(
      id: c['id']?.toString() ?? '',
      title: c['title'] ?? 'Khóa học',
      description: c['description'] ?? '',
      mentorId: c['mentorId']?.toString(),
      mentorName: c['mentorName'] ?? '',
      departmentId: c['departmentId']?.toString(),
      departmentName: c['departmentName'],
      moduleCount: c['moduleCount'] ?? 0,
      lessonCount: c['lessonCount'] ?? 0,
      status: c['status'] ?? 'PUBLISHED',
      deadlineStatus: c['deadlineStatus'],
      deadlineType: c['deadlineType'],
      defaultDeadlineDays: c['defaultDeadlineDays'],
      fixedDeadline: c['fixedDeadline'],
      enrolled: c['enrolled'] ?? false,
      enrollmentStatus: c['enrollmentStatus']?.toString(),
    );
  }

  // ============================================================
  // LESSON — Nội dung và hoàn thành bài học
  // ============================================================

  /// Hoàn thành bài học — POST /api/lms/lessons/{lessonId}/complete
  static Future<bool> completeLesson(String lessonId) async {
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

      log("COMPLETE LESSON url=$url status=${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      log("COMPLETE LESSON FAILED: status=${response.statusCode}, lessonId=$lessonId, body=${response.body}");
      return false;
    } catch (e) {
      log("LmsService.completeLesson failed: $e");
      return false;
    }
  }

  /// Hoàn thành khóa học — POST /api/lms/enrollments/courses/{courseId}/complete
  /// Backend sẽ set enrollmentStatus = COMPLETED nếu progress = 100%.
  static Future<bool> completeCourse(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/enrollments/courses/$courseId/complete");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("COMPLETE COURSE url=$url status=${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("COMPLETE COURSE SUCCESS: courseId=$courseId");
        return true;
      }
      log("COMPLETE COURSE FAILED: status=${response.statusCode}, courseId=$courseId, body=${response.body}");
      return false;
    } catch (e) {
      log("LmsService.completeCourse failed: $e");
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
          youtubeVideoId: _extractYouTubeId(first),
          thumbnailUrl: first['thumbnailUrl']?.toString() ?? first['thumbnail_url']?.toString(),
          videoDurationSeconds: first['videoDurationSeconds'] ?? first['duration'] ?? 0,
          currentPositionSeconds: first['currentPositionSeconds'] ?? 0,
          level: first['level'] ?? '',
          description: first['content'] ?? '',
          content: first['content']?.toString(),
          contentType: first['type']?.toString(),
          keyTakeaways: (first['keyTakeaways'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          resources: (first['resources'] as List<dynamic>?)?.map((r) => LessonResource(
            id: r['id']?.toString() ?? '',
            title: r['title'] ?? '',
            type: r['type'] ?? 'link',
            url: r['url']?.toString(),
            fileSize: r['fileSize']?.toString(),
          )).toList() ?? [],
          discussions: [],
          transcript: first['transcript']?.toString(),
          isCompleted: first['isCompleted'] ?? first['completed'] ?? false,
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
  static Future<({CertificateInfo? cert, String? error})> getMyCertificate(String courseId) async {
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
        final bodyStr = response.body.trim();
        try {
          if (!bodyStr.startsWith('{') && !bodyStr.startsWith('[')) {
            log("GET MY CERTIFICATE: non-JSON response: $bodyStr");
            return (cert: null, error: 'Phản hồi không hợp lệ từ server');
          }
          final data = jsonDecode(bodyStr) as Map<String, dynamic>;
          log("GET MY CERTIFICATE SUCCESS: courseId=$courseId, code=${data['verificationCode']}");
          return (cert: _parseCertificate(data), error: null);
        } catch (e) {
          if (e is FormatException || e.toString().contains('Unexpected token')) {
            final cert = _parseCertificateFallback(bodyStr);
            if (cert != null) {
              log("GET MY CERTIFICATE: recovered via fallback parse, code=${cert.code}");
              return (cert: cert, error: null);
            }
          }
          log("GET MY CERTIFICATE PARSE ERROR: $e, body=$bodyStr");
          return (cert: null, error: 'Không thể đọc dữ liệu chứng chỉ');
        }
      }

      // Xử lý lỗi HTTP với body chứa message từ backend
      String errorMsg = 'Không thể tải chứng chỉ (HTTP ${response.statusCode})';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['message'] != null) {
          errorMsg = body['message'].toString();
        }
      } catch (_) {}

      // Khi backend trả "Course not completed", xây dựng thông báo chi tiết
      // bằng cách lấy dữ liệu enrollment thực tế từ API
      if (errorMsg.toLowerCase().contains('course not completed') ||
          errorMsg.toLowerCase().contains('not completed') ||
          errorMsg.toLowerCase().contains('chưa hoàn thành')) {
        final detailedError = await _buildCourseNotCompletedError(courseId);
        if (detailedError != null) {
          errorMsg = detailedError;
        }
      }

      log("GET MY CERTIFICATE FAILED: status=${response.statusCode}, courseId=$courseId, body=${response.body}");
      return (cert: null, error: errorMsg);
    } catch (e) {
      log("LmsService.getMyCertificate: $e");
      return (cert: null, error: 'Lỗi kết nối: $e');
    }
  }

  /// Gọi course detail để lấy enrollment status thực tế,
  /// rồi xây dựng thông báo lỗi chi tiết giúp user biết còn gì chưa hoàn thành.
  static Future<String?> _buildCourseNotCompletedError(String courseId) async {
    try {
      final course = await getCourseDetail(courseId);
      final status = course.enrollmentStatus.toUpperCase();
      final progress = course.progress.toDouble();

      if (status == 'COMPLETED' || progress >= 100) {
        return 'Khóa học đã hoàn thành trên hệ thống. '
            'Vui lòng chờ hệ thống cấp chứng chỉ hoặc liên hệ quản trị viên.';
      }

      final remaining = (100 - progress).clamp(0, 100).toInt();

      String hint = 'Vui lòng hoàn thành nốt $remaining% nội dung còn lại để nhận chứng chỉ.';

      // Kiểm tra course detail có modules không — nếu có thì user cần xem đủ nội dung
      if (course.moduleCount > 0 && course.modules.isNotEmpty) {
        final totalLessons = course.modules.fold<int>(
          0,
          (sum, m) => sum + m.lessonCount,
        );
        if (totalLessons > 0) {
          hint = 'Vui lòng hoàn thành nốt $remaining% nội dung còn lại '
              '($totalLessons bài học) để nhận chứng chỉ.';
        }
      }

      return 'Bạn chưa đủ điều kiện nhận chứng chỉ.\n'
          'Tiến độ hiện tại: ${progress.toInt()}%.\n'
          '$hint';
    } catch (e) {
      log("_buildCourseNotCompletedError failed: $e");
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
        try {
          final data = jsonDecode(response.body);
          log("VERIFY CERTIFICATE SUCCESS: code=$code");
          return _parseCertificate(data);
        } catch (e) {
          // JSON có thể bị truncate do circular reference
          final cert = _parseCertificateFallback(response.body);
          if (cert != null) {
            log("VERIFY CERTIFICATE: recovered via fallback, code=$code");
            return cert;
          }
          log("VERIFY CERTIFICATE PARSE ERROR: $e, code=$code");
          return null;
        }
      }
      log("VERIFY CERTIFICATE FAILED: status=${response.statusCode}, code=$code, body=${response.body}");
      return null;
    } catch (e) {
      log("LmsService.verifyCertificate: $e");
      return null;
    }
  }

  /// Tải chứng chỉ PDF — GET /api/lms/certificates/verify/{code}/pdf
  static Future<List<int>?> downloadCertificatePdf(String code) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/certificates/verify/$code/pdf");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/pdf",
        },
      );

      log("DOWNLOAD CERTIFICATE PDF STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      log("DOWNLOAD CERTIFICATE PDF FAILED: status=${response.statusCode}");
      return null;
    } catch (e) {
      log("LmsService.downloadCertificatePdf failed: $e");
      return null;
    }
  }

  /// Tải chứng chỉ PDF theo courseId — GET /api/lms/certificates/course/{courseId}/pdf
  static Future<List<int>?> downloadCertificateByCourseId(String courseId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/certificates/course/$courseId/pdf");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/pdf",
        },
      );

      log("DOWNLOAD CERTIFICATE BY COURSE ID STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      log("DOWNLOAD CERTIFICATE BY COURSE ID FAILED: status=${response.statusCode}, body=${response.body}");
      return null;
    } catch (e) {
      log("LmsService.downloadCertificateByCourseId failed: $e");
      return null;
    }
  }

  /// Mở chứng chỉ PDF trong tab mới — GET /api/lms/certificates/course/{courseId}/pdf
  /// Trả về URL để web mở bằng window.open()
  static String getCertificatePdfUrl(String courseId) {
    return "$baseUrl/lms/certificates/course/$courseId/pdf";
  }

  /// Mở chứng chỉ PDF public trong tab mới — GET /api/lms/certificates/verify/{code}/pdf
  static String getCertificateVerifyPdfUrl(String code) {
    return "$baseUrl/lms/certificates/verify/$code/pdf";
  }

  // ============================================================
  // GET ALL CERTIFICATES (WORKAROUND)
  // Backend hiện không có endpoint GET /certificates.
  // Workaround: lấy enrollment đã COMPLETED → gọi /course/{courseId} cho từng khóa.
  // ============================================================
  static Future<List<CertificateInfo>> getAllMyCertificates() async {
    try {
      // 1. Lấy tất cả enrollment của user
      final enrollmentsResult = await getMyCourses(page: 0, size: 1000);

      // 2. Lọc chỉ lấy khóa đã hoàn thành
      final completedCourses = enrollmentsResult.content
          .where((e) => e.status == EnrollmentStatus.completed)
          .toList();

      log("GET ALL CERTIFICATES: ${completedCourses.length} completed courses found");

      if (completedCourses.isEmpty) return [];

      // 3. Gọi certificate endpoint cho từng khóa song song
      final List<CertificateInfo> certificates = [];
      final results = await Future.wait(
        completedCourses.map((e) => getMyCertificate(e.id)),
      );

      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result.cert != null) {
          certificates.add(result.cert!);
          log("GET ALL CERTIFICATES: courseId=${completedCourses[i].id} → cert found, code=${result.cert!.code}");
        } else {
          log("GET ALL CERTIFICATES: courseId=${completedCourses[i].id} → no cert (${result.error})");
        }
      }

      log("GET ALL CERTIFICATES: total=${certificates.length} certificates");
      return certificates;
    } catch (e) {
      log("LmsService.getAllMyCertificates failed: $e");
      return [];
    }
  }

  // ============================================================
  // MY CERTIFICATES (LIST) — GET /api/lms/certificates/my
  // ============================================================

  static Future<PageResponse<CertificateInfo>> getMyCertificates({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/certificates/my?page=$page&size=$size");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final bodyStr = response.body.trim();
        if (!bodyStr.startsWith('{') && !bodyStr.startsWith('[')) {
          log("GET MY CERTIFICATES: non-JSON response: $bodyStr");
          return PageResponse(
            content: [], totalElements: 0, totalPages: 0,
            number: page, size: size, first: true, last: true,
          );
        }
        final data = jsonDecode(bodyStr) as Map<String, dynamic>;
        final result = PageResponse.fromJson(data, _parseCertificate);
        log("GET MY CERTIFICATES SUCCESS: page=$page, total=${result.totalElements}");
        return result;
      }
      log("GET MY CERTIFICATES FAILED: status=${response.statusCode}, body=${response.body}");
      return PageResponse(
        content: [], totalElements: 0, totalPages: 0,
        number: page, size: size, first: true, last: true,
      );
    } catch (e) {
      log("LmsService.getMyCertificates: $e");
      return PageResponse(
        content: [], totalElements: 0, totalPages: 0,
        number: page, size: size, first: true, last: true,
      );
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
  // JOIN LIVE SESSION
  // Backend: GET /api/lms/live-sessions/{sessionId}/join
  // Returns the Google Meet URL if session is live and user is enrolled.
  // Throws on error (403 = not enrolled, 400 = session not started/ended).
  // ============================================================
  static Future<String> joinSession(String sessionId) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("$baseUrl/lms/live-sessions/$sessionId/join");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        // Backend returns raw string (the meeting URL)
        final body = response.body.trim();
        // Remove surrounding quotes if present (some servers return quoted strings)
        if (body.startsWith('"') && body.endsWith('"')) {
          return jsonDecode(body) as String;
        }
        return body;
      }

      // Parse error message from response body
      String errorMsg = 'Không thể tham gia buổi live';
      try {
        final body = jsonDecode(response.body);
        errorMsg = body['message'] ?? body['error'] ?? response.body;
      } catch (_) {
        errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
      }

      if (response.statusCode == 403) {
        throw Exception('Bạn chưa đăng ký khóa học này. Vui lòng đăng ký trước.');
      }
      if (response.statusCode == 400) {
        throw Exception(errorMsg);
      }
      throw Exception(errorMsg);
    } catch (e) {
      log("LmsService.joinSession: $e");
      rethrow;
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
        final content = (data['data'] ?? data['content']) as List<dynamic>? ?? [];
        log("GET MY LEARNING PATHS SUCCESS: count=${content.length}, keyword=$keyword, page=$page");

        // ── Fetch enrollments to compute real progress ──────────────────────────
        final enrollmentsResult = await getMyCourses(page: 0, size: 1000);
        final Map<String, EnrolledCourse> enrollmentMap = {
          for (final e in enrollmentsResult.content) e.id: e,
        };
        // ───────────────────────────────────────────────────────────────────────

        return content.map((lp) {
          final base = _parseLearningPathInfo(lp);
          return _enrichLearningPathInfo(base, enrollmentMap);
        }).toList();
      }
      log("GET MY LEARNING PATHS FAILED: status=${response.statusCode}, keyword=$keyword, body=${response.body}");
      return [];
    } catch (e) {
      log("LmsService.getMyLearningPaths: $e");
      return [];
    }
  }

  /// Tính progressPercent thực tế cho LearningPathInfo từ enrollment data.
  /// progress = trung bình progressPercent của các khóa trong lộ trình
  /// mà user đã enroll.
  static LearningPathInfo _enrichLearningPathInfo(
    LearningPathInfo base,
    Map<String, EnrolledCourse> enrollmentMap,
  ) {
    final enrolledCourses = base.courses.where((c) {
      return enrollmentMap.containsKey(c.courseId.value.toString());
    }).toList();

    if (enrolledCourses.isEmpty) {
      // Không có khóa nào được enroll → giữ nguyên (0%) từ API
      return base;
    }

    double totalProgress = 0;
    for (final c in enrolledCourses) {
      final e = enrollmentMap[c.courseId.value.toString()];
      totalProgress += e?.progressPercent ?? 0;
    }
    final progressPercent = totalProgress / enrolledCourses.length;

    return LearningPathInfo(
      id: base.id,
      title: base.title,
      description: base.description,
      courseCount: base.courseCount,
      progressPercent: progressPercent,
      courses: base.courses,
      totalModules: base.totalModules,
    );
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

        // ── Fetch enrollments to resolve real isCompleted per course ────────────
        final enrollmentsResult = await getMyCourses(page: 0, size: 1000);
        final Map<String, EnrolledCourse> enrollmentMap = {
          for (final e in enrollmentsResult.content) e.id: e,
        };
        // ───────────────────────────────────────────────────────────────────────

        final detail = _parseLearningPathDetail(data, enrollmentMap);
        return detail;
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
      // DEBUG
      log(">>> _parseCourseDetail input: enrolled=${data['enrolled']}");
      return CourseDetail(
      id: data['id']?.toString() ?? courseId,
      title: data['title'] ?? 'Khóa học',
      description: data['description'] ?? '',
      mentorId: data['mentorId'] ?? 0,
      mentorName: data['mentorName'] ?? 'Giảng viên',
      departmentId: data['departmentId'],
      departmentName: data['departmentName'],
      status: data['status'],
      deadlineStatus: data['deadlineStatus'],
      deadlineType: data['deadlineType'],
      defaultDeadlineDays: data['defaultDeadlineDays'],
      fixedDeadline: data['fixedDeadline']?.toString(),
      moduleCount: data['moduleCount'] ?? 0,
      lessonCount: data['lessonCount'] ?? 0,
      // Enrollment fields from backend
      enrolled: data['enrolled'] == true,
      progress: (data['progress'] ?? 0).round(),
      enrollmentStatus: data['enrollmentStatus'] ?? 'NOT_STARTED',
      enrolledAt: _parseDateTime(data['enrolledAt']),
      deadline: _parseDateTime(data['deadline']),
      overdue: data['overdue'] == true,
      modules: _parseModulesDetail(data['modules']),
    );
  }

  static List<ModuleDetail> _parseModulesDetail(dynamic modules) {
    if (modules == null) return [];
    final items = modules as List<dynamic>;
    return items.map((m) {
      final item = m as Map<String, dynamic>;
      return ModuleDetail(
        id: item['id'] ?? 0,
        title: item['title'] ?? 'Module',
        orderIndex: item['orderIndex'] ?? 0,
        lessonCount: item['lessonCount'] ?? 0,
        lessons: _parseLessonsDetail(item['lessons']),
      );
    }).toList();
  }

  static List<LessonDetail> _parseLessonsDetail(dynamic lessons) {
    if (lessons == null) return [];
    final items = lessons as List<dynamic>;
    return items.map((l) {
      final item = l as Map<String, dynamic>;
      return LessonDetail(
        id: item['id'] ?? 0,
        title: item['title'] ?? 'Bài học',
        orderIndex: item['orderIndex'] ?? 0,
        contents: _parseContentsDetail(item['contents']),
      );
    }).toList();
  }

  static List<LessonContentDetail> _parseContentsDetail(dynamic contents) {
    if (contents == null) return [];
    final items = contents as List<dynamic>;
    return items.map((c) {
      final item = c as Map<String, dynamic>;
      return LessonContentDetail(
        id: item['id'] ?? 0,
        type: item['type']?.toString() ?? 'TEXT',
        content: item['content']?.toString() ?? '',
        orderIndex: item['orderIndex'],
      );
    }).toList();
  }

  static EnrolledCourse _parseEnrolledCourse(Map<String, dynamic> c) {
    return EnrolledCourse(
      id: c['id']?.toString() ?? '',
      title: c['title'] ?? c['name'] ?? 'Khóa học',
      description: c['description']?.toString(),
      imageUrl: c['imageUrl'] ?? c['thumbnail'],
      progressPercent: (c['progress'] ?? c['progressPercent'] ?? 0).toDouble(),
      enrolledAt:
          DateTime.tryParse(c['enrolledAt'] ?? c['createdAt'] ?? '') ??
          DateTime.now(),
      status: EnrollmentStatus.fromString(c['status']?.toString()),
      certificateAvailable: c['certificateAvailable'] == true,
      deadline: _parseDateTime(c['deadline']),
      deadlineStatus: DeadlineStatus.fromString(c['deadlineStatus']?.toString()),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Backend trả CertificateResponse (DTO flat):
  /// {
  ///   id, verificationCode, shortCode, certificateUrl, verifyUrl,
  ///   issuedAt, issuedAtFormatted,
  ///   userId, userName, departmentName, courseId, courseTitle, issuer
  /// }
  static CertificateInfo _parseCertificate(Map<String, dynamic> data) {
    return CertificateInfo(
      id: data['id']?.toString() ?? '',
      code: data['verificationCode'] ?? '',
      displayCode: data['shortCode'] ?? '',
      courseName: data['courseTitle'] ?? data['courseName'] ?? '',
      userName: data['userName'] ?? '',
      departmentName: data['departmentName'] ?? '',
      issuedAt:
          DateTime.tryParse(data['issuedAt'] ?? '') ?? DateTime.now(),
      expiresAt: null,
      courseId: data['courseId']?.toString(),
      certificateUrl: data['certificateUrl']?.toString(),
      issuer: data['issuer'] ?? 'SMETS',
    );
  }

  /// Parse certificate từ body có thể bị truncate do circular reference serialization.
  /// Backend CertificateResponse dùng flat fields: userName, departmentName, courseTitle, verificationCode, shortCode, issuer.
  static CertificateInfo? _parseCertificateFallback(String body) {
    try {
      final userName = _extractJsonString(body, '"userName"');
      final courseTitle = _extractJsonString(body, '"courseTitle"');
      final verificationCode = _extractJsonString(body, '"verificationCode"');
      final shortCode = _extractJsonString(body, '"shortCode"');
      final id = _extractJsonString(body, '"id"');
      final issuedAtStr = _extractJsonString(body, '"issuedAt"');
      final courseId = _extractJsonString(body, '"courseId"');
      final certificateUrl = _extractJsonString(body, '"certificateUrl"');
      final departmentName = _extractJsonString(body, '"departmentName"');
      final issuer = _extractJsonString(body, '"issuer"');

      if (verificationCode == null && id == null) return null;

      return CertificateInfo(
        id: id ?? '',
        code: verificationCode ?? '',
        displayCode: shortCode ?? '',
        courseName: courseTitle ?? '',
        userName: userName ?? '',
        departmentName: departmentName ?? '',
        issuedAt: issuedAtStr != null
            ? DateTime.tryParse(issuedAtStr) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: null,
        courseId: courseId,
        certificateUrl: certificateUrl,
        issuer: issuer ?? 'SMETS',
      );
    } catch (e) {
      log("_parseCertificateFallback failed: $e");
      return null;
    }
  }

  static String? _extractJsonString(String body, String key) {
    final pattern = RegExp('${RegExp.escape(key)}\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(body);
    return match?.group(1);
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
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final coursesList = (lp['courses'] as List<dynamic>?) ?? [];
    final courseItems = coursesList.map((c) {
      final item = c as Map<String, dynamic>;
      return lpm.CourseItemResponse(
        relationId: lpm.Long(parseInt(item['relationId'])),
        courseId: lpm.Long(parseInt(item['courseId'])),
        courseTitle: item['courseTitle'] ?? '',
        orderIndex: parseInt(item['orderIndex']),
        mentorName: item['mentorName'],
        moduleCount: parseInt(item['moduleCount']),
      );
    }).toList();

    return LearningPathInfo(
      id: lp['id']?.toString() ?? '',
      title: lp['title'] ?? lp['name'] ?? '',
      description: lp['description'] ?? '',
      courseCount: lp['courseCount'] ?? coursesList.length,
      progressPercent:
          (lp['progress'] ?? lp['progressPercent'] ?? 0).toDouble(),
      courses: courseItems,
      totalModules: courseItems.fold(0, (sum, c) => sum + (c.moduleCount ?? 0)),
    );
  }

  static LearningPathDetail _parseLearningPathDetail(
    Map<String, dynamic> lp,
    Map<String, EnrolledCourse> enrollmentMap,
  ) {
    final courses =
        (lp['courses'] as List<dynamic>?)?.map((c) {
          final item = c as Map<String, dynamic>;
          final courseIdStr = item['courseId']?.toString() ?? '';
          // Real completion: look up enrollment, fallback to backend isCompleted
          bool isCompleted = item['isCompleted'] ?? false;
          if (courseIdStr.isNotEmpty && enrollmentMap.containsKey(courseIdStr)) {
            isCompleted =
                enrollmentMap[courseIdStr]!.status == EnrollmentStatus.completed;
          }
          return LearningPathCourseItem(
            id: courseIdStr,
            title: item['title'] ?? item['name'] ?? '',
            orderIndex: item['orderIndex'] ?? 0,
            isCompleted: isCompleted,
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

/// Metadata phân trang trích xuất từ HTTP headers
class _PaginationMeta {
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  _PaginationMeta({
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
  });
}

enum EnrollmentStatus {
  notStarted,
  inProgress,
  completed,
  unknown;

  static EnrollmentStatus fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'NOT_STARTED':
        return EnrollmentStatus.notStarted;
      case 'IN_PROGRESS':
        return EnrollmentStatus.inProgress;
      case 'COMPLETED':
        return EnrollmentStatus.completed;
      default:
        return EnrollmentStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case EnrollmentStatus.notStarted:
        return 'Chưa bắt đầu';
      case EnrollmentStatus.inProgress:
        return 'Đang học';
      case EnrollmentStatus.completed:
        return 'Hoàn thành';
      case EnrollmentStatus.unknown:
        return 'Không xác định';
    }
  }
}

enum DeadlineStatus {
  onTime,
  dueSoon,
  overdue,
  none;

  static DeadlineStatus fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'ON_TIME':
        return DeadlineStatus.onTime;
      case 'DUE_SOON':
        return DeadlineStatus.dueSoon;
      case 'OVERDUE':
        return DeadlineStatus.overdue;
      default:
        return DeadlineStatus.none;
    }
  }

  String get label {
    switch (this) {
      case DeadlineStatus.onTime:
        return 'Còn thời gian';
      case DeadlineStatus.dueSoon:
        return 'Sắp hết hạn';
      case DeadlineStatus.overdue:
        return 'Quá hạn';
      case DeadlineStatus.none:
        return '';
    }
  }
}

class EnrolledCourse {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final double progressPercent;
  final DateTime enrolledAt;
  final EnrollmentStatus status;
  final bool certificateAvailable;
  final DateTime? deadline;
  final DeadlineStatus deadlineStatus;
  /// Chỉ true khi tất cả quiz module đều đạt.
  /// Dùng để override hiển thị badge/nút thay vì dùng enrollment status.
  final bool allQuizPassed;

  EnrolledCourse({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.progressPercent,
    required this.enrolledAt,
    required this.status,
    required this.certificateAvailable,
    this.deadline,
    required this.deadlineStatus,
    this.allQuizPassed = false,
  });
}

class CertificateInfo {
  final String id;
  final String code; // verificationCode (UUID dài)
  final String displayCode; // shortCode (CERT-XXXX)
  final String courseName;
  final String userName;
  final String departmentName; // department của user
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String? courseId;
  final String? certificateUrl;
  final String issuer; // e.g. "SMETS"

  CertificateInfo({
    required this.id,
    required this.code,
    required this.displayCode,
    required this.courseName,
    required this.userName,
    required this.departmentName,
    required this.issuedAt,
    this.expiresAt,
    this.courseId,
    this.certificateUrl,
    required this.issuer,
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
  final List<lpm.CourseItemResponse> courses;
  final int totalModules;

  LearningPathInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.courseCount,
    required this.progressPercent,
    this.courses = const [],
    this.totalModules = 0,
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

class CatalogCourse {
  final String id;
  final String title;
  final String description;
  final String? mentorId;
  final String mentorName;
  final String? departmentId;
  final String? departmentName;
  final int moduleCount;
  final int lessonCount;
  final String status;
  final String? deadlineStatus;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final String? fixedDeadline;
  bool enrolled;
  final String? enrollmentStatus;

  CatalogCourse({
    required this.id,
    required this.title,
    required this.description,
    this.mentorId,
    required this.mentorName,
    this.departmentId,
    this.departmentName,
    required this.moduleCount,
    required this.lessonCount,
    required this.status,
    this.deadlineStatus,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
    this.enrolled = false,
    this.enrollmentStatus,
  });
}
