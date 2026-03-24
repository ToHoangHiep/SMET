import 'package:flutter/material.dart';

class SidebarMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final String tooltip;

  const SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.tooltip,
  });
}
