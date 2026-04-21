import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/service/common/auth_service.dart';

class CourseService {
  // Tích hợp API thật qua LmsService, giữ interface cũ
  static Future<CourseDetail> getCourseDetail(String courseId) async {
    return await LmsService.getCourseDetail(courseId);
  }

  // Enrollment — gọi trực tiếp LmsService
  static Future<bool> enrollCourse(String courseId) async {
    return await LmsService.enrollCourse(courseId);
  }

  static Future<bool> leaveCourse(String courseId) async {
    return await LmsService.leaveCourse(courseId);
  }

  static Future<bool> isEnrolled(String courseId) async {
    return await LmsService.isEnrolled(courseId);
  }

  static Future<PageResponse<EnrolledCourse>> getMyCourses({int page = 0, int size = 10}) async {
    return await LmsService.getMyCourses(page: page, size: size);
  }

  /// Lấy danh sách tất cả khóa học cho Catalog — trả về PageResponse
  static Future<PageResponse<CatalogCourse>> getCourses({
    String? keyword,
    String? departmentId,
    String? status,
    String? enrollmentStatus,
    int page = 0,
    int size = 12,
  }) async {
    return await LmsService.getCourses(
      keyword: keyword,
      departmentId: departmentId,
      status: status,
      enrollmentStatus: enrollmentStatus,
      page: page,
      size: size,
    );
  }

  static Future<bool> completeLesson(String lessonId) async {
    return await LmsService.completeLesson(lessonId);
  }

  static Future<bool> completeCourse(String courseId) async {
    return await LmsService.completeCourse(courseId);
  }

  static Future<LessonContent?> getLessonContent(String lessonId) async {
    return await LmsService.getLessonContent(lessonId);
  }

  static Future<LearningCourse?> getCourseProgress(String courseId) async {
    try {
      final user = await AuthService.getCurrentUser();
      return await LmsService.getCourseProgress(courseId, user.id.toString());
    } catch (_) {
      return null;
    }
  }
}
