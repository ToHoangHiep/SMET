import 'package:flutter/material.dart';

class ProfileRoleBadge extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const ProfileRoleBadge({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue[800],
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
