class ReassignmentError {
  final int mentorId;
  final String mentorName;
  final int courseCount;
  final List<int> courseIds;
  final String rawMessage;

  ReassignmentError({
    required this.mentorId,
    required this.mentorName,
    required this.courseCount,
    required this.courseIds,
    required this.rawMessage,
  });

  factory ReassignmentError.fromMessage(String message, int mentorId, String mentorName) {
    final courseIds = _extractCourseIds(message);
    final count = _extractCourseCount(message);

    return ReassignmentError(
      mentorId: mentorId,
      mentorName: mentorName,
      courseCount: count,
      courseIds: courseIds,
      rawMessage: message,
    );
  }

  static int _extractCourseCount(String message) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }

  static List<int> _extractCourseIds(String message) {
    return [];
  }
}
