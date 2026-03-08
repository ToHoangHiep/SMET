import 'package:flutter/material.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String leadName;
  final String leadAvatarUrl;
  final int teamSize;
  final int activeProjects;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.leadName,
    required this.leadAvatarUrl,
    required this.teamSize,
    required this.activeProjects,
  });

  // Hỗ trợ parse từ JSON sau này khi có API thật
  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: Icons.business, // Nên có hàm map string sang IconData ở thực tế
      iconColor: Colors.blue,
      iconBgColor: Colors.blue.withOpacity(0.1),
      leadName: json['lead_name'] ?? '',
      leadAvatarUrl: json['lead_avatar_url'] ?? '',
      teamSize: json['team_size'] ?? 0,
      activeProjects: json['active_projects'] ?? 0,
    );
  }
}
