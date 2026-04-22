import 'package:flutter/material.dart';
import 'package:smet/page/admin/dashboard/models/admin_dashboard_models.dart';

class DashboardOverviewTab extends StatelessWidget {
  final DashboardSummary summary;
  final List<DashboardAlert> alerts;
  final List<DashboardInsight> insights;

  const DashboardOverviewTab({
    super.key,
    required this.summary,
    required this.alerts,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatGrid(context),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildAlertsSection()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildInsightsSection()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: [
            _buildStatCard('Tổng User', summary.totalUsers.toString(), Icons.people, Colors.blue),
            _buildStatCard('Người dùng Active', summary.activeUsers.toString(), Icons.check_circle_outline, Colors.teal),
            _buildStatCard('Tổng Khóa học', summary.totalCourses.toString(), Icons.book, Colors.orange),
            _buildStatCard('Số lượng đăng ký', summary.totalEnrollments.toString(), Icons.school, Colors.purple),
            _buildStatCard('Tỉ lệ hoàn thành', '${summary.completionRate}%', Icons.trending_up, Colors.green),
            _buildStatCard('Quá hạn', summary.overdueCount.toString(), Icons.warning_amber_rounded, Colors.red),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cảnh báo hệ thống',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            const Text('Không có cảnh báo nào', style: TextStyle(color: Colors.grey))
          else
            ...alerts.map((alert) => _buildListItem(
              icon: Icons.notifications_active,
              iconColor: const Color(0xFFEF4444),
              title: alert.type,
              subtitle: alert.message,
              badge: alert.count.toString(),
            )),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý tối ưu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          if (insights.isEmpty)
            const Text('Hệ thống đang hoạt động tốt', style: TextStyle(color: Colors.grey))
          else
            ...insights.map((insight) => _buildListItem(
              icon: Icons.lightbulb_outline,
              iconColor: insight.severity == 'HIGH' ? Colors.orange : Colors.blue,
              title: insight.message,
              subtitle: insight.recommendation,
              badge: insight.severity,
            )),
        ],
      ),
    );
  }

  Widget _buildListItem({required IconData icon, required Color iconColor, required String title, required String subtitle, required String badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
