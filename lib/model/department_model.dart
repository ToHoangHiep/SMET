import 'package:flutter/material.dart';

class DepartmentModel {
  final int id;
  final String name;
  final String code;
  final bool active;
  final int? projectManagerId;
  final String? projectManagerName;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.active,
    this.projectManagerId,
    this.projectManagerName,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      active: json['active'] ?? false,
      projectManagerId: json['projectManagerId'],
      projectManagerName: json['projectManagerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "code": code,
      "active": active,
      "projectManagerId": projectManagerId,
    };
  }
}
