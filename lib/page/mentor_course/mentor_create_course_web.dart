import 'package:flutter/material.dart';

class MentorCreateCourseWeb extends StatelessWidget {
  const MentorCreateCourseWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      body: Row(
        children: [

          /// SIDEBAR
          Container(
            width: 240,
            color: Colors.white,
            child: Column(
              children: const [
                SizedBox(height: 40),
                Icon(Icons.school, size: 40, color: Colors.blue),
                SizedBox(height: 20),
                Text("SMETS",
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Tạo khóa học mới",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// COVER
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[300],
                      ),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.photo_camera),
                          label: const Text("Upload ảnh bìa"),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    _field("Tên khóa học"),
                    _field("Phụ đề"),
                    _field("Mô tả khóa học", lines: 4),
                    _field("Link YouTube bài giảng"),
                    _field("Link Google Meet"),

                    const SizedBox(height: 30),

                    Row(
                      children: [

                        ElevatedButton(
                          onPressed: () {},
                          child: const Text("Lưu khóa học"),
                        ),

                        const SizedBox(width: 16),

                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Hủy"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  static Widget _field(String label, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}