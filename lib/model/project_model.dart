enum ProjectStatus {
  DRAFT,
  IN_PROGRESS,
  COMPLETED,
  CANCELLED;

  static ProjectStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'IN_PROGRESS':
        return ProjectStatus.IN_PROGRESS;
      case 'COMPLETED':
        return ProjectStatus.COMPLETED;
      case 'CANCELLED':
        return ProjectStatus.CANCELLED;
      default:
        return ProjectStatus.DRAFT;
    }
  }

  String get label {
    switch (this) {
      case ProjectStatus.DRAFT:
        return 'Nháp';
      case ProjectStatus.IN_PROGRESS:
        return 'Đang tiến hành';
      case ProjectStatus.COMPLETED:
        return 'Hoàn thành';
      case ProjectStatus.CANCELLED:
        return 'Đã hủy';
    }
  }
}

class ProjectModel {
  final int id;
  final String title;
  final String? description;
  final int departmentId;
  final ProjectStatus status;
  final String? leaderName;
  final String? mentorName;
  final List<String>? members;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.departmentId,
    required this.status,
    this.leaderName,
    this.mentorName,
    this.members,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description']?.toString(),
      departmentId: json['departmentId'] ?? 0,
      status: ProjectStatus.fromString(json['status']),
      leaderName: json['leaderName']?.toString(),
      mentorName: json['mentorName']?.toString(),
      members: json['members'] != null 
          ? List<String>.from(json['members']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'status': status.name,
    };
  }

  ProjectModel copyWith({
    int? id,
    String? title,
    String? description,
    int? departmentId,
    ProjectStatus? status,
    String? leaderName,
    String? mentorName,
    List<String>? members,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
      status: status ?? this.status,
      leaderName: leaderName ?? this.leaderName,
      mentorName: mentorName ?? this.mentorName,
      members: members ?? this.members,
    );
  }
}
