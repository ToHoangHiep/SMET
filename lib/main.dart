import 'package:flutter/material.dart';
import 'package:smet/page/mentor_course/mentor_course.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MentorCourse(),
    );
  }
}