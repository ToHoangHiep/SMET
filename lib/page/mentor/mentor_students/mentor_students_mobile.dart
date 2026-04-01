import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/mentor_enrollment_model.dart';
import 'package:smet/service/mentor/mentor_student_service.dart';
import 'package:smet/service/mentor/course_service.dart';

class MentorStudentsMobile extends StatefulWidget {
  const MentorStudentsMobile({super.key});

  @override
  State<MentorStudentsMobile> createState() => _MentorStudentsMobileState();
}

class _MentorStudentsMobileState extends State<MentorStudentsMobile> {
  final _studentService = MentorStudentService();
  final _courseService = MentorCourseService();

  List<CourseResponse> _courses = [];
  CourseResponse? _selectedCourse;
  List<MentorEnrollmentInfo> _enrollments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 0;
  int _totalPages = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final result = await _courseService.listCourses(page: 0, size: 50);
      if (!mounted) return;
      setState(() { _courses = result.content; });
      if (_courses.isNotEmpty && _selectedCourse == null) {
        _selectCourse(_courses.first);
      }
    } catch (e) {
      log("[StudentsMobile] loadCourses failed: $e");
      if (!mounted) return;
      setState(() { _isLoading = false; _error = 'Khong the tai danh sach khoa hoc'; });
    }
  }

  Future<void> _selectCourse(CourseResponse course) async {
    setState(() { _selectedCourse = course; _isLoading = true; });
    _loadEnrollments(page: 0);
  }

  Future<void> _loadEnrollments({int page = 0}) async {
    if (_selectedCourse == null) return;
    if (page == 0) setState(() => _error = null);

    try {
      final result = await _studentService.getEnrollmentsByCourse(
        _selectedCourse!.id, page: page, size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (page == 0) {
          _enrollments = result.content;
        } else {
          _enrollments = [..._enrollments, ...result.content];
        }
        _totalPages = result.totalPages;
        _currentPage = result.number;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      log("[StudentsMobile] loadEnrollments failed: $e");
      if (!mounted) return;
      setState(() { _error = 'Khong the tai danh sach hoc vien'; _isLoading = false; _isLoadingMore = false; });
    }
  }

  List<MentorEnrollmentInfo> get _filtered {
    if (_searchQuery.isEmpty) return _enrollments;
    final q = _searchQuery.toLowerCase();
    return _enrollments.where((e) =>
      e.userName.toLowerCase().contains(q) ||
      e.userEmail.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> _showExtendDeadlineDialog(MentorEnrollmentInfo enrollment) async {
    final daysController = TextEditingController(text: '7');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Gia han deadline"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Gia han cho ${enrollment.userName}", style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'So ngay', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('ngay'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Huy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            child: const Text("Gia han"),
          ),
        ],
      ),
    );

    if (result == true) {
      final days = int.tryParse(daysController.text) ?? 7;
      try {
        await _studentService.extendDeadline(enrollment.enrollmentId, days);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Da gia han $days ngay cho ${enrollment.userName}"), backgroundColor: Colors.green),
        );
        _loadEnrollments(page: 0);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gia han that bai: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Quan ly hoc vien", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: () {})],
      ),
      body: Column(
        children: [
          if (_courses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: DropdownButtonFormField<CourseResponse>(
                value: _selectedCourse,
                decoration: InputDecoration(
                  hintText: 'Chon khoa hoc',
                  filled: true,
                  fillColor: const Color(0xFFF1F3FD),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                isExpanded: true,
                items: _courses.map((c) => DropdownMenuItem(
                  value: c, child: Text(c.title, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (course) { if (course != null) _selectCourse(course); },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Tim kiem hoc vien...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadEnrollments, child: const Text("Thu lai")),
          ],
        ),
      );
    }

    final filtered = _filtered;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? "Khong tim thay hoc vien" : "Chua co hoc vien nao",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadEnrollments(page: 0),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200 &&
              !_isLoadingMore && _currentPage < _totalPages - 1) {
            setState(() => _isLoadingMore = true);
            _loadEnrollments(page: _currentPage + 1);
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filtered.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return _buildStudentCard(filtered[index]);
          },
        ),
      ),
    );
  }

  Widget _buildStudentCard(MentorEnrollmentInfo enrollment) {
    Color statusColor;
    String statusLabel;
    switch (enrollment.status) {
      case EnrollmentStatus.COMPLETED:
        statusColor = const Color(0xFF22C55E);
        statusLabel = 'Hoan thanh';
        break;
      case EnrollmentStatus.IN_PROGRESS:
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'Dang hoc';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'Chua bat dau';
    }
    if (enrollment.isOverdue) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Qua han';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(enrollment.initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(enrollment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(enrollment.userEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tien do: ${enrollment.progress}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: enrollment.progress / 100,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showExtendDeadlineDialog(enrollment),
                icon: const Icon(Icons.timer_outlined, color: Color(0xFF6366F1)),
                tooltip: 'Gia han deadline',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
