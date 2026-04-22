import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/common/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _redirectByRole();
  }

  Future<void> _redirectByRole() async {
    if (!mounted) return;

    try {
      final user = await AuthService.getMe();
      final role = user['role']?.toString().toUpperCase() ?? 'USER';
      final departmentId = user['departmentId'];

      if (!mounted) return;

      // Redirect theo role
      if (role == 'ADMIN') {
        context.go('/user_management');
      } else if (role == 'PROJECT_MANAGER' || role == 'PM') {
        context.go('/pm/dashboard');
      } else if (role == 'MENTOR') {
        context.go('/user_management'); // Mentor có thể quản lý khóa học
      } else {
        // USER hoặc default → Employee Dashboard
        context.go('/employee/dashboard');
      }
    } catch (e) {
      if (mounted) {
        // Nếu lỗi → về login
        context.go('/login');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF137FEC)),
            const SizedBox(height: 16),
            Text(
              'Đang chuyển hướng...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
