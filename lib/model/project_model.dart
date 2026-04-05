enum ProjectStatus {
  INACTIVE,
  ACTIVE,
  COMPLETED;

  static ProjectStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'INACTIVE':
        return ProjectStatus.INACTIVE;
      case 'ACTIVE':
        return ProjectStatus.ACTIVE;
      case 'COMPLETED':
        return ProjectStatus.COMPLETED;
      default:
        return ProjectStatus.INACTIVE;
    }
  }

  String get label {
    switch (this) {
      case ProjectStatus.INACTIVE:
        return 'Không hoạt động';
      case ProjectStatus.ACTIVE:
        return 'Hoạt động';
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
    );
  }
}
