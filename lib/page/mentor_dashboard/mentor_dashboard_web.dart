import 'package:flutter/material.dart';

class MentorDashboardWeb extends StatelessWidget {
  const MentorDashboardWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7f8),

      body: Row(
        children: [

          /// SIDEBAR
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 30),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, color: Color(0xff1a90ff)),
                    SizedBox(width: 8),
                    Text(
                      "SMETS",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 40),

                _menuItem(Icons.dashboard, "Tổng quan"),
                _menuItem(Icons.menu_book, "Khóa học"),
                _menuItem(Icons.people, "Học viên"),
                _menuItem(Icons.chat, "Tin nhắn"),
                _menuItem(Icons.settings, "Cài đặt"),
              ],
            ),
          ),

          /// MAIN CONTENT
          Expanded(
            child: Column(
              children: [

                /// HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: 70,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      const Text(
                        "Mentor Dashboard",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: const [
                          Icon(Icons.search),
                          SizedBox(width: 20),
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                                "https://lh3.googleusercontent.com/aida-public/AB6AXuBWLiqpFmgOF57zCBqOqCPaAy_fiVLHuuBmUc4kL5OnkqsnCELHDrE9dvZhwuE7Tfdo2BfeJsnbI7eFzKecAAUvc4VDQyy9fhroLL9Fsq3Fe9m9OQdQsarQiEaDahR8Gu-wx5kEcJiFtw7okVymvu3-BArXeYWLirr9AGeRNlVEh_eVuk4lyRcMYsIs8xYl8bt-CFoFoYm8lmHXVccX_Hd0qO1alKdFyK5FS-2l0G8eVs6Im6Sh1BFPZ5RlhXyRxAEitnNLTq7OnPD4"),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                /// PAGE CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// WELCOME
                        const Text(
                          "Xin chào, TS. Sarah Mitchell",
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

                        /// STATS
                        Row(
                          children: [
                            Expanded(child: _statCard(Icons.menu_book, "Khóa học", "5")),
                            const SizedBox(width: 20),
                            Expanded(child: _statCard(Icons.people, "Học viên", "120")),
                            const SizedBox(width: 20),
                            Expanded(child: _statCard(Icons.assignment, "Bài chờ", "18")),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// ACTIVITY
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

                        _activityItem(
                            Icons.assignment,
                            "Buổi Q&A: Marketing",
                            "8 Học viên đã đăng ký",
                            "Chấm điểm"),

                        _activityItem(
                            Icons.forum,
                            "Buổi Q&A: Marketing",
                            "8 Học viên đã đăng ký",
                            "Trả lời"),

                        _activityItem(
                            Icons.assignment,
                            "Buổi Q&A: Marketing",
                            "8 Học viên đã đăng ký",
                            "Chấm điểm"),

                        const SizedBox(height: 30),

                        /// UPCOMING SESSION
                        Container(
                          padding: const EdgeInsets.all(20),
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

                              const SizedBox(height: 8),

                              const Text(
                                "Mở rộng quy mô SME của bạn",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                "Chủ đề: Lean Management",
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

  static Widget _menuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
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

  static Widget _activityItem(
      IconData icon, String title, String subtitle, String action) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff1a90ff)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () {},
          child: Text(action),
        ),
      ),
    );
  }
}