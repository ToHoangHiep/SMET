import 'package:flutter/material.dart';
import 'package:smet/page/login/login.dart';
import 'package:smet/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/admin_dashboard/user_management/user_management.dart';
import 'package:smet/page/admin_dashboard/department_management/department_management.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SMET',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: AppPages.router,
    );
  }
}
