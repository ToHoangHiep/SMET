import 'package:flutter/material.dart';
import 'package:smet/page/mentor/mentor_course/mentor_course.dart';
import 'package:smet/page/mentor/mentor_course_report/mentor_course_report.dart';
import 'package:smet/page/mentor/mentor_dashboard/mentor_dashboard.dart';
import 'package:smet/page/mentor/mentor_learning_path/mentor_learning_path.dart';
import 'package:smet/page/mentor/mentor_live_session/screen/mentor_live_session.dart';
import 'package:smet/page/mentor/mentor_review_assignment/mentor_review_assignment.dart';

/// Mentor Sidebar - Dùng chung cho cả web và mobile
class MentorSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final bool isMobile;

  const MentorSidebar({
    super.key,
    this.selectedIndex = 1,
    this.onItemSelected,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            isMobile
                ? null
                : const Border(right: BorderSide(color: Color(0xffe0e0e0))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          /// LOGO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.school, color: Color(0xff1a90ff), size: 24),
              SizedBox(width: 8),
              Text(
                "SMETS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// MENU ITEMS
          _menuItem(context, Icons.grid_view_rounded, "Tổng quan", 0),
          _menuItem(context, Icons.menu_book_rounded, "Khóa học", 1),
          _menuItem(context, Icons.account_tree_rounded, "Lộ trình", 2),
          _menuItem(context, Icons.assessment_rounded, "Báo cáo", 3),
          _menuItem(context, Icons.calendar_month_rounded, "Lịch mentor", 4),
          _menuItem(context, Icons.rate_review_rounded, "Quiz Review", 5),
          _menuItem(context, Icons.people_rounded, "Học viên", 6),
          _menuItem(context, Icons.chat_bubble_rounded, "Tin nhắn", 7),

          const Spacer(),

          /// PROFILE SECTION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xffe0e0e0))),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xff1a90ff),
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TS. Sarah Mitchell",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Mentor",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    final bool isSelected = selectedIndex == index;

    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xffeef3ff) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            minLeadingWidth: 20,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xff1a90ff) : Colors.grey[700],
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? const Color(0xff1a90ff) : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () {
              // Gọi callback nếu có
              if (onItemSelected != null) {
                onItemSelected!(index);
                return;
              }

              // Default navigation
              _navigateTo(context, title);
            },
          ),
        );
      },
    );
  }

  void _navigateTo(BuildContext context, String title) {
    // Kiểm tra xem có drawer đang mở không
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }

    Widget? targetPage;

    switch (title) {
      case "Tổng quan":
        targetPage = const MentorDashboard();
        break;
      case "Khóa học":
        targetPage = const MentorCourse();
        break;
      case "Lộ trình":
        targetPage = const MentorLearningPath();
        break;
      case "Báo cáo":
        targetPage = const MentorCourseReport();
        break;
      case "Lịch mentor":
        targetPage = const MentorLiveSession();
        break;
      case "Chấm bài":
        targetPage = const MentorReviewAssignment();
        break;
      case "Học viên":
      case "Tin nhắn":
        Future.delayed(const Duration(milliseconds: 300), () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title - Đang phát triển')));
        });
        return;
    }

    if (targetPage != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => targetPage!));
      });
    }
  }
}
