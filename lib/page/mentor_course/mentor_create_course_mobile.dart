import 'package:flutter/material.dart';

class MentorCreateCourseMobile extends StatelessWidget {
  const MentorCreateCourseMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7f8),

      appBar: AppBar(
        title: const Text("Tạo khóa học mới"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// COVER IMAGE
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[300],
              ),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera),
                  label: const Text("Thay đổi ảnh bìa"),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// COURSE NAME
            TextField(
              decoration: InputDecoration(
                labelText: "Tên khóa học",
                hintText: "Nhập tên khóa học",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// SUBTITLE
            TextField(
              decoration: InputDecoration(
                labelText: "Phụ đề",
                hintText: "Tóm tắt giá trị khóa học",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// DESCRIPTION
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Mô tả khóa học",
                hintText: "Chi tiết nội dung khóa học",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// YOUTUBE
            TextField(
              decoration: InputDecoration(
                labelText: "Link YouTube bài giảng",
                prefixIcon: const Icon(Icons.play_circle),
                hintText: "https://youtube.com/...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// MEET
            TextField(
              decoration: InputDecoration(
                labelText: "Link Google Meet",
                prefixIcon: const Icon(Icons.video_call),
                hintText: "https://meet.google.com/...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// SAVE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Lưu khóa học"),
              ),
            ),

            const SizedBox(height: 10),

            /// CANCEL
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Hủy"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}