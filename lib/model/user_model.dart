// file: user_model.dart
import 'package:flutter/material.dart';

enum UserRole { admin, projectManager, mentor, employee }

class UserModel {
  final String id;
  final String username; // Thêm username theo yêu cầu
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  bool isActive;
  final DateTime lastUpdated;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.lastUpdated,
  });

  String get fullName => '$firstName $lastName';
}
