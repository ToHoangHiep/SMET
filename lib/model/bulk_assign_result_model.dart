enum BulkAssignResultCode {
  SUCCESS,
  DIFFERENT_DEPARTMENT,
  COURSE_NOT_FOUND,
  NO_DEPARTMENT,
  ERROR,
  UNKNOWN,
}

extension BulkAssignResultCodeDisplay on BulkAssignResultCode {
  String get displayName {
    switch (this) {
      case BulkAssignResultCode.SUCCESS:
        return 'Thành công';
      case BulkAssignResultCode.DIFFERENT_DEPARTMENT:
        return 'Khác phòng ban';
      case BulkAssignResultCode.COURSE_NOT_FOUND:
        return 'Khóa học không tồn tại';
      case BulkAssignResultCode.NO_DEPARTMENT:
        return 'Không có phòng ban';
      case BulkAssignResultCode.ERROR:
        return 'Lỗi';
      case BulkAssignResultCode.UNKNOWN:
        return 'Không xác định';
    }
  }
}

class BulkAssignResultModel {
  final int courseId;
  final String? courseName;
  final BulkAssignResultCode code;
  final String? message;

  BulkAssignResultModel({
    required this.courseId,
    this.courseName,
    required this.code,
    this.message,
  });

  factory BulkAssignResultModel.fromJson(Map<String, dynamic> json) {
    final codeStr = (json['code'] ?? 'UNKNOWN').toString().toUpperCase();
    BulkAssignResultCode code;
    try {
      code = BulkAssignResultCode.values.firstWhere(
        (e) => e.name == codeStr,
        orElse: () => BulkAssignResultCode.UNKNOWN,
      );
    } catch (_) {
      code = BulkAssignResultCode.UNKNOWN;
    }

    return BulkAssignResultModel(
      courseId: json['courseId'] ?? 0,
      courseName: json['courseName']?.toString(),
      code: code,
      message: json['message']?.toString(),
    );
  }

  bool get isSuccess => code == BulkAssignResultCode.SUCCESS;
  bool get isFailed => code != BulkAssignResultCode.SUCCESS;
}
