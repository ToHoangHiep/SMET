import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProjectMemberMobile extends StatelessWidget {
  final Widget pageHeader;
  final Widget formCard;
  final Widget memberList;
  final bool showForm;
  final String userName;
  final VoidCallback onLogout;

  const ProjectMemberMobile({
    super.key,
    required this.pageHeader,
    required this.formCard,
    required this.memberList,
    required this.showForm,
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(title: const Text('Thành viên'), backgroundColor: const Color(0xFF137FEC), foregroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _showDrawer(context))),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [showForm ? formCard : pageHeader, if (!showForm) ...[const SizedBox(height: 16), memberList]])),
    );
  }

  void _showDrawer(BuildContext context) => Scaffold.of(context).openDrawer();

  Widget _buildDrawer(BuildContext context) => Drawer(
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(decoration: const BoxDecoration(color: Color(0xFF137FEC)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Color(0xFF137FEC))), const SizedBox(height: 12), Text(userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const Text('Quản lý dự án', style: TextStyle(color: Colors.white70, fontSize: 12))])),
      ListTile(leading: const Icon(Icons.dashboard), title: const Text('Bảng điều khiển'), onTap: () { Navigator.pop(context); context.go('/pm/dashboard'); }),
      ListTile(leading: const Icon(Icons.folder), title: const Text('Dự án'), onTap: () { Navigator.pop(context); context.go('/pm/projects'); }),
      ListTile(leading: const Icon(Icons.people), title: const Text('Thành viên'), selected: true, onTap: () => Navigator.pop(context)),
      ListTile(leading: const Icon(Icons.trending_up), title: const Text('Tiến độ'), onTap: () { Navigator.pop(context); context.go('/pm/project_progress'); }),
      ListTile(leading: const Icon(Icons.menu_book), title: const Text('Lộ trình học'), onTap: () { Navigator.pop(context); context.go('/pm/learning_path'); }),
      const Divider(),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); onLogout(); }),
    ]),
  );
}
