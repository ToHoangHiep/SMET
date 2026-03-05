import 'package:flutter/material.dart';

class MentorDashboardMobile extends StatelessWidget {
  const MentorDashboardMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7f8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Row(
          children: [
            Icon(Icons.school, color: Color(0xff1a90ff)),
            SizedBox(width: 8),
            Text(
              "SMETS Người quản trị",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.search, color: Colors.black54),
          SizedBox(width: 10),
          CircleAvatar(
            backgroundImage: NetworkImage(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBWLiqpFmgOF57zCBqOqCPaAy_fiVLHuuBmUc4kL5OnkqsnCELHDrE9dvZhwuE7Tfdo2BfeJsnbI7eFzKecAAUvc4VDQyy9fhroLL9Fsq3Fe9m9OQdQsarQiEaDahR8Gu-wx5kEcJiFtw7okVymvu3-BArXeYWLirr9AGeRNlVEh_eVuk4lyRcMYsIs8xYl8bt-CFoFoYm8lmHXVccX_Hd0qO1alKdFyK5FS-2l0G8eVs6Im6Sh1BFPZ5RlhXyRxAEitnNLTq7OnPD4"),
          ),
          SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Welcome
            const Text(
              "Xin chào, TS. Sarah Mitchell",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Đây là những gì đang diễn ra với các khóa học của bạn hôm nay.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            /// Stats
            Row(
              children: [
                Expanded(child: _statCard(Icons.menu_book, "Khóa học đang dạy", "5")),
                const SizedBox(width: 10),
                Expanded(child: _statCard(Icons.group, "Tổng số học viên", "120")),
                const SizedBox(width: 10),
                Expanded(child: _statCard(Icons.pending_actions, "Bài nộp đang chờ", "18")),
              ],
            ),

            const SizedBox(height: 25),

            /// Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Hoạt động gần đây",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Xem tất cả",
                  style: TextStyle(color: Color(0xff1a90ff)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _activityItem(
                Icons.assignment, "Buổi Q&A: Marketing", "8 Học viên đã đăng ký", "Chấm điểm"),
            _activityItem(
                Icons.forum, "Buổi Q&A: Marketing", "8 Học viên đã đăng ký", "Trả lời"),
            _activityItem(
                Icons.assignment, "Buổi Q&A: Marketing", "8 Học viên đã đăng ký", "Chấm điểm"),

            const SizedBox(height: 25),

            /// Upcoming session
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff1a90ff),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bắt đầu sau 15 phút",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Mở rộng quy mô SME của bạn: Chiến lược nâng cao",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Chủ đề: Quản lý tinh gọn & Chuỗi cung ứng",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff1a90ff),
                    ),
                    onPressed: () {},
                    child: const Text("Tham gia ngay"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// Footer
            Center(
              child: Column(
                children: const [
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
            ),
          ],
        ),
      ),

      /// Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Tổng quan",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "Khóa học",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Học viên",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Tin nhắn",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Cài đặt",
          ),
        ],

        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xff1a90ff)),
          const SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget _activityItem(
      IconData icon, String title, String subtitle, String button) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff1a90ff)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () {},
          child: Text(button),
        ),
      ),
    );
  }
}