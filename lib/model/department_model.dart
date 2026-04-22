class DepartmentModel {
  final int id;
  final String name;
  final String code;
  final bool isActive;
  final int? projectManagerId;
  final String? projectManagerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    this.projectManagerId,
    this.projectManagerName,
    this.createdAt,
    this.updatedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    // Try multiple field name formats for date fields
    final createdAtValue = json['createdAt'] ??
        json['created_at'] ??
        json['createdAt '] ??
        json['dateCreated'];
    final updatedAtValue = json['updatedAt'] ??
        json['updated_at'] ??
        json['updatedAt '] ??
        json['dateUpdated'];

    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? json['active'] ?? false,
      projectManagerId: json['projectManagerId'],
      projectManagerName: json['projectManagerName'],
      createdAt: parseDate(createdAtValue),
      updatedAt: parseDate(updatedAtValue),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "code": code,
      "isActive": isActive,
      if (projectManagerId != null) "projectManagerId": projectManagerId,
    };
  }
}
