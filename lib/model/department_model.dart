class DepartmentModel {
  final int id;
  final String name;
  final String code;
  final bool isActive;
  final int? projectManagerId;
  final String? projectManagerName;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    this.projectManagerId,
    this.projectManagerName,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      // Backend trả về "isActive" hoặc "active" đều được
      isActive: json['isActive'] ?? json['active'] ?? false,
      projectManagerId: json['projectManagerId'],
      projectManagerName: json['projectManagerName'],
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
