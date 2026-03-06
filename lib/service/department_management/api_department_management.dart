import 'package:flutter/material.dart';
import 'package:smet/model/department_model.dart';

class DepartmentService {
  // Dữ liệu giả lập khớp với thiết kế UI của bạn
  final List<DepartmentModel> _mockDepartments = [
    DepartmentModel(
      id: '1',
      name: 'Engineering',
      description: 'Software development and infrastructure management.',
      icon: Icons.engineering,
      iconColor: const Color(0xFF137FEC), // Primary
      iconBgColor: const Color(0xFFEBF5FF), // Blue 50
      leadName: 'Alex Rivera',
      leadAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCVSCfi2FPpMMDqCRJKBw2T-22YUyfGWbErvUcX3WW9y5Qy-TVZoTA4O1feHAXyMjNojVcbaPC_R_cNhfINcr94KufF_EoQECGYQvehhkKHgw9PMUjl1ygB3z5QlnJc-ZXu4DvOrPpW5GOvJa7BRTvuulNoUZSlOc54cYSeg8TgbXaQXEeJ9VImnewGQ7roWVB-PV5rK72r3FmCtZJWUtNMmgac66njqLLd3vwyzbIFgmIvd69aKkZ0Zt9naI6ExBzwTk69ZiAIU2Eh',
      teamSize: 42,
      activeProjects: 12,
    ),
    DepartmentModel(
      id: '2',
      name: 'Marketing',
      description: 'Brand positioning, digital ads, and social strategy.',
      icon: Icons.campaign,
      iconColor: Colors.purple[600]!,
      iconBgColor: Colors.purple[50]!,
      leadName: 'Sarah Chen',
      leadAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB8K6Y5hrGCG863uDr6HKuP8uabmLyPCb0hmz8MvIu7YUQ3TkRnEPGp-IhJIPVqjc_zwzqTyxPrvI1CfzjjZ08iD7ci9S1d3l6bkdIKdUUeMI7qtIL8FlEscSCcy3Ycb78ROJqjOUXvvTC6rHeMhMQziEnlgrOJt2ULQQ-4cdciOegzyEGnBdu94RffwdSIwIrhXWG3OPwpiLXiAmXWj_aXIbMPoDzGuQpGSOcZGQ8qBuYvNWCc2ESgxLBKcs_5Sg738d9BgyzX15Vp',
      teamSize: 15,
      activeProjects: 5,
    ),
    DepartmentModel(
      id: '3',
      name: 'Operations',
      description: 'Logistics, facility management, and supply chain.',
      icon: Icons.settings_accessibility,
      iconColor: Colors.orange[600]!,
      iconBgColor: Colors.orange[50]!,
      leadName: 'James Wilson',
      leadAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCB_txajYZM0thY7YzKpcXFGzD0UZEaZW73fkJNiZMHeYzMvaw_LeVgrjwSfu7FRFOVOYZB9ssceyBsWNgceg_Et9mmgGhkscjbYJcjQU418kTUawpoOc8uL6aqQGRmdmKmwye0vU9SqueOPqecSsxGxRvX3lAUeU50XA2cfDLYNSf0mM3_zxlfTMMPYXl9nyj-Prb5LlOUsOmEIzQKVkunYs4y0Lp_NIYHWu_3zpKr-powplVBGSMM4v7uyeuuVwTb1Dg449_c_TC3',
      teamSize: 28,
      activeProjects: 8,
    ),
    DepartmentModel(
      id: '4',
      name: 'Finance',
      description: 'Accounting, payroll, and financial forecasting.',
      icon: Icons.payments,
      iconColor: Colors.teal[600]!,
      iconBgColor: Colors.teal[50]!,
      leadName: 'Elena Rodriguez',
      leadAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBtlUX1KzyV6nVEFNNuNOkrtyDcsUih2-X3o0RWk6N4gQ6-83wfdFVbWUpLKUHJT0QR7POFPveM4mmH0ecgkbBHVVltY0FYxTWNz9WUQiP668T7RuoOKs9xBc9Yho728K2tbYBbeOpQxYQJ4Cr84Owj_fFjmSAks2pmNuR7R0l-6LwasqZ-1XvFL7_nwrbY6hsHD08aWRLcbdsu3xFkfxM7BR07Ty5ZP47OILALRhm2v8om6hIo1hLdGCfA5H_R14OIfyfpP4pSIDf2',
      teamSize: 12,
      activeProjects: 3,
    ),
    DepartmentModel(
      id: '5',
      name: 'Human Resources',
      description: 'Recruiting, benefits, and employee relations.',
      icon: Icons.psychology,
      iconColor: Colors.pink[600]!,
      iconBgColor: Colors.pink[50]!,
      leadName: 'Michael Scott',
      leadAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCW-nOk1Egi-hYG47nfBlcIMpUDfUiM9T6x8VLxU16yx1Lw1rj38p8XkqIWNvaQKAxn80v5-8UBQAdvORt5gsPcAIEEKitQdqtR4gcPePqHfZNOydhUdk5p_jdgwA8mNmOfxbfvSjitRwCNz35Ra6CDN4lNH0PUySQcA9BOI8308JwsvPpy8hTN8xHE8CvUZlrjouhoAN_bs4EzXa6e5H_rHIMolmhDeHz-V-n49LeMvzm-ULhwz5GTYN-_x8iD15cYygNASwVFKG4a',
      teamSize: 18,
      activeProjects: 6,
    ),
  ];

  // API Lấy danh sách phòng ban
  Future<List<DepartmentModel>> getDepartments() async {
    // Giả lập độ trễ mạng (Network delay)
    await Future.delayed(const Duration(milliseconds: 800));
    return List<DepartmentModel>.from(_mockDepartments);
  }

  // API Tạo phòng ban
  Future<DepartmentModel> createDepartment({
    required String name,
    required String description,
    required String leadName,
    String? code,
    int teamSize = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final newDepartment = DepartmentModel(
      id: (code != null && code.trim().isNotEmpty)
          ? code.trim().toUpperCase()
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      icon: Icons.business,
      iconColor: const Color(0xFF137FEC),
      iconBgColor: const Color(0xFFEBF5FF),
      leadName: leadName,
      leadAvatarUrl:
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(leadName)}&background=E5E7EB&color=111827',
      teamSize: teamSize,
      activeProjects: 0,
    );

    _mockDepartments.insert(0, newDepartment);
    return newDepartment;
  }

  // API Cập nhật phòng ban
  Future<DepartmentModel?> updateDepartment({
    required String id,
    required String name,
    required String description,
    required String leadName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _mockDepartments.indexWhere((dept) => dept.id == id);
    if (index == -1) return null;

    final current = _mockDepartments[index];

    final updatedDepartment = DepartmentModel(
      id: current.id,
      name: name,
      description: description,
      icon: current.icon,
      iconColor: current.iconColor,
      iconBgColor: current.iconBgColor,
      leadName: leadName,
      leadAvatarUrl:
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(leadName)}&background=E5E7EB&color=111827',
      teamSize: current.teamSize,
      activeProjects: current.activeProjects,
    );

    _mockDepartments[index] = updatedDepartment;
    return updatedDepartment;
  }

  // API Xóa phòng ban (Ví dụ)
  Future<bool> deleteDepartment(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockDepartments.removeWhere((dept) => dept.id == id);
    return true;
  }
}
