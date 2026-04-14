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
      return DateTime.tryParse(value.toString());
    }

    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? json['active'] ?? false,
      projectManagerId: json['projectManagerId'],
      projectManagerName: json['projectManagerName'],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
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
