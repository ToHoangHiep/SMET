import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smet/page/login/login_Web.dart';
import 'package:smet/page/login/login_mobile.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  // Hàm xử lý đăng nhập
  void _onLoginPressed() {
    print("Login with: ${_emailController.text}");
    context.go('/user_management');
  }

  // CHỈ MỤC CHUNG: Toàn bộ nội dung bên trong Form
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Email address",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: "you@company.com",
            prefixIcon: const Icon(Icons.mail_outline, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Password",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "••••••••",
            prefixIcon: const Icon(Icons.key_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) => setState(() => _rememberMe = val!),
            ),
            const Text("Remember me", style: TextStyle(fontSize: 14)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Forgot password?",
                style: TextStyle(color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _onLoginPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              "Sign in",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ĐIỀU KIỆN ĐIỀU HƯỚNG
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (kIsWeb || constraints.maxWidth > 850) {
            return LoginWeb(formContent: _buildFormContent());
          } else {
            return LoginMobile(formContent: _buildFormContent());
          }
        },
      ),
    );
  }
}
