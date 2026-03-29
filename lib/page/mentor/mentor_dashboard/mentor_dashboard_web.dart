import 'package:flutter/material.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class MentorDashboardWeb extends StatelessWidget {
  const MentorDashboardWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7f8),

      body: Row(
        children: [

          /// SIDEBAR - Dùng chung MentorSidebar
          // const MentorSidebar(selectedIndex: 0),

          /// MAIN CONTENT
          Expanded(
            child: Column(
              children: [

                /// PAGE HEADER WITH BREADCRUMB
                Container(
                  margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                  child: BreadcrumbPageHeader(
                    pageTitle: "Mentor Dashboard",
                    pageIcon: Icons.dashboard_rounded,
                    breadcrumbs: const [
                      BreadcrumbItem(label: "Mentor", route: "/mentor/dashboard"),
                      BreadcrumbItem(label: "Tổng quan"),
                    ],
                    primaryColor: const Color(0xFF6366F1),
                  ),
                ),

                /// PAGE CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// WELCOME - TODO: thay bằng user từ auth
                        const Text(
                          "Xin chào",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Đây là những gì đang diễn ra với các khóa học của bạn hôm nay.",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 25),

                        /// STATS - TODO: thay bằng data từ API
                        Row(
                          children: [
                            Expanded(child: _statCard(Icons.menu_book, "Khóa học", "--")),
                            const SizedBox(width: 20),
                            Expanded(child: _statCard(Icons.people, "Học viên", "--")),
                            const SizedBox(width: 20),
                            Expanded(child: _statCard(Icons.assignment, "Bài chờ", "--")),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// ACTIVITY - TODO: thay bằng data từ API
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Hoạt động gần đây",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Xem tất cả",
                              style: TextStyle(color: Color(0xff1a90ff)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        /// TODO: thay bằng ListView từ API
                        _emptyState("Chưa có hoạt động nào"),

                        const SizedBox(height: 30),

                        /// UPCOMING SESSION - TODO: thay bằng data từ API
                        _upcomingSessionPlaceholder(),

                        const SizedBox(height: 40),

                        /// FOOTER
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.school, color: Color(0xff1a90ff)),
                              SizedBox(height: 5),
                              Text(
                                "SMETS",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Hỗ trợ"),
                                  SizedBox(width: 20),
                                  Text("Chính sách bảo mật"),
                                  SizedBox(width: 20),
                                  Text("Điều khoản dịch vụ"),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                "© 2024 SMETS. Bảo lưu mọi quyền.",
                                style: TextStyle(color: Colors.grey),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  static Widget _statCard(IconData icon, String title, String value) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xff1a90ff)),
          const SizedBox(height: 8),
          Text(title),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  static Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  static Widget _upcomingSessionPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff1a90ff),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Không có buổi học sắp tới",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
