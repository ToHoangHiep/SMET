enum AssignmentSkipReason {
  ALREADY_ENROLLED,
  ALREADY_COMPLETED,
  ALREADY_ASSIGNED_LEARNING_PATH,
  USER_INACTIVE,
  NOT_IN_PROJECT;

  static AssignmentSkipReason fromString(String? value) {
    if (value == null) return NOT_IN_PROJECT;
    return AssignmentSkipReason.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => NOT_IN_PROJECT,
    );
  }

  String get label {
    switch (this) {
      case AssignmentSkipReason.ALREADY_ENROLLED:
        return 'Đã đăng ký rồi';
      case AssignmentSkipReason.ALREADY_COMPLETED:
        return 'Đã hoàn thành rồi';
      case AssignmentSkipReason.ALREADY_ASSIGNED_LEARNING_PATH:
        return 'Đã được gán Learning Path';
      case AssignmentSkipReason.USER_INACTIVE:
        return 'Tài khoản không hoạt động';
      case AssignmentSkipReason.NOT_IN_PROJECT:
        return 'Không thuộc dự án';
    }
  }
}

class SkippedUserDetail {
  final int userId;
  final String? userName;
  final AssignmentSkipReason reason;

  SkippedUserDetail({
    required this.userId,
    this.userName,
    required this.reason,
  });

  factory SkippedUserDetail.fromJson(Map<String, dynamic> json) {
    return SkippedUserDetail(
      userId: json['userId'] ?? 0,
      userName: json['userName']?.toString(),
      reason: AssignmentSkipReason.fromString(json['reason']?.toString()),
    );
  }
}

class AssignmentResult {
  final int assignedCount;
  final int skippedCount;
  final List<SkippedUserDetail> skippedUsers;

  AssignmentResult({
    required this.assignedCount,
    required this.skippedCount,
    required this.skippedUsers,
  });

  factory AssignmentResult.fromJson(Map<String, dynamic> json) {
    return AssignmentResult(
      assignedCount: json['assignedCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
      skippedUsers: (json['skippedUsers'] as List<dynamic>?)
              ?.map((e) => SkippedUserDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasSkipped => skippedCount > 0;
  bool get hasAssigned => assignedCount > 0;
}
