import 'package:flutter/material.dart';
import 'package:smet/page/login/login_desktop.dart';
import 'package:smet/page/login/login_mobile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          if(width < 600)
          return LoginMobile();
          return LoginDesktop();
        },
      ),
    );
  }
}