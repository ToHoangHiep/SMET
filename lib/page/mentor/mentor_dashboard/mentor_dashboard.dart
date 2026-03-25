import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mentor_dashboard_mobile.dart';
import 'mentor_dashboard_web.dart';

class MentorDashboard extends StatelessWidget {
  const MentorDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    // Nếu chạy trên Web → luôn dùng layout Web
    if (kIsWeb) {
      return const MentorDashboardWeb();
    }

    // Nếu chạy Mobile → kiểm tra kích thước màn hình
    return LayoutBuilder(
      builder: (context, constraints) {

        // Tablet / Desktop
        if (constraints.maxWidth >= 850) {
          return const MentorDashboardWeb();
        }

        // Mobile
        return const MentorDashboardMobile();
      },
    );
  }
}