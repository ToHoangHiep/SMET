import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/model/Employee_learning_model.dart';
import 'package:smet/service/employee/lms_service.dart';

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

  static Future<List<EnrolledCourse>> getMyCourses({int page = 0, int size = 10}) async {
    return await LmsService.getMyCourses(page: page, size: size);
  }

  /// Lấy danh sách tất cả khóa học cho Catalog
  static Future<List<CatalogCourse>> getCourses({String? keyword, int page = 0, int size = 10}) async {
    return await LmsService.getCourses(keyword: keyword, page: page, size: size);
  }

  static Future<bool> completeLesson(String lessonId) async {
    return await LmsService.completeLesson(lessonId);
  }

  static Future<LessonContent?> getLessonContent(String lessonId) async {
    return await LmsService.getLessonContent(lessonId);
  }
}
