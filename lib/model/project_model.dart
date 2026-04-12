enum ProjectStatus {
  INACTIVE,
  ACTIVE,
  REVIEW_PENDING,
  COMPLETED;

  static ProjectStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'INACTIVE':
        return ProjectStatus.INACTIVE;
      case 'ACTIVE':
        return ProjectStatus.ACTIVE;
      case 'REVIEW_PENDING':
        return ProjectStatus.REVIEW_PENDING;
      case 'COMPLETED':
        return ProjectStatus.COMPLETED;
      default:
        return ProjectStatus.INACTIVE;
    }
  }

  String get label {
    switch (this) {
      case ProjectStatus.INACTIVE:
        return 'Khởi tạo';
      case ProjectStatus.ACTIVE:
        return 'Đang hoạt động';
      case ProjectStatus.REVIEW_PENDING:
        return 'Chờ duyệt';
      case ProjectStatus.COMPLETED:
        return 'Hoàn thành';
    }
  }
}

class ProjectModel {
  final int id;
  final String title;
  final String? description;
  final int departmentId;
  final ProjectStatus status;
  final int leaderId;
  final String? leaderName;
  final int? mentorId;
  final String? mentorName;
  final List<int>? memberIds;
  final List<String>? memberNames;

  // Trường phê duyệt
  final bool submitted;
  final String? submissionLink;
  final DateTime? submittedAt;
  final int? submittedBy;
  final bool mentorApproved;
  final int? mentorApprovedBy;
  final DateTime? mentorApprovedAt;
  final String? mentorFeedback;
  final bool pmApproved;
  final int? pmApprovedBy;
  final DateTime? pmApprovedAt;
  final String? pmFeedback;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.departmentId,
    required this.status,
    required this.leaderId,
    this.leaderName,
    this.mentorId,
    this.mentorName,
    this.memberIds,
    this.memberNames,
    this.submitted = false,
    this.submissionLink,
    this.submittedAt,
    this.submittedBy,
    this.mentorApproved = false,
    this.mentorApprovedBy,
    this.mentorApprovedAt,
    this.mentorFeedback,
    this.pmApproved = false,
    this.pmApprovedBy,
    this.pmApprovedAt,
    this.pmFeedback,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description']?.toString(),
      departmentId: json['departmentId'] ?? json['department']?['id'] ?? 0,
      status: ProjectStatus.fromString(json['status']),
      leaderId: json['leaderId'] ?? 0,
      leaderName: json['leaderName']?.toString(),
      mentorId: json['mentorId'] as int?,
      mentorName: json['mentorName']?.toString(),
      memberIds: json['memberIds'] != null
          ? List<int>.from(json['memberIds'])
          : null,
      memberNames: json['memberNames'] != null
          ? List<String>.from(json['memberNames'])
          : null,
      // Trường phê duyệt
      submitted: json['submitted'] == true,
      submissionLink: json['submissionLink']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      submittedBy: json['submittedBy'] as int?,
      mentorApproved: json['mentorApproved'] == true,
      mentorApprovedBy: json['mentorApprovedBy'] as int?,
      mentorApprovedAt: json['mentorApprovedAt'] != null
          ? DateTime.tryParse(json['mentorApprovedAt'].toString())
          : null,
      mentorFeedback: json['mentorFeedback']?.toString(),
      pmApproved: json['pmApproved'] == true,
      pmApprovedBy: json['pmApprovedBy'] as int?,
      pmApprovedAt: json['pmApprovedAt'] != null
          ? DateTime.tryParse(json['pmApprovedAt'].toString())
          : null,
      pmFeedback: json['pmFeedback']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'status': status.name,
      'leaderId': leaderId,
      'memberIds': memberIds,
    };
  }

  ProjectModel copyWith({
    int? id,
    String? title,
    String? description,
    int? departmentId,
    ProjectStatus? status,
    int? leaderId,
    String? leaderName,
    int? mentorId,
    String? mentorName,
    List<int>? memberIds,
    List<String>? memberNames,
    bool? submitted,
    String? submissionLink,
    DateTime? submittedAt,
    int? submittedBy,
    bool? mentorApproved,
    int? mentorApprovedBy,
    DateTime? mentorApprovedAt,
    String? mentorFeedback,
    bool? pmApproved,
    int? pmApprovedBy,
    DateTime? pmApprovedAt,
    String? pmFeedback,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
      status: status ?? this.status,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      submitted: submitted ?? this.submitted,
      submissionLink: submissionLink ?? this.submissionLink,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      mentorApproved: mentorApproved ?? this.mentorApproved,
      mentorApprovedBy: mentorApprovedBy ?? this.mentorApprovedBy,
      mentorApprovedAt: mentorApprovedAt ?? this.mentorApprovedAt,
      mentorFeedback: mentorFeedback ?? this.mentorFeedback,
      pmApproved: pmApproved ?? this.pmApproved,
      pmApprovedBy: pmApprovedBy ?? this.pmApprovedBy,
      pmApprovedAt: pmApprovedAt ?? this.pmApprovedAt,
      pmFeedback: pmFeedback ?? this.pmFeedback,
    );
  }
}
