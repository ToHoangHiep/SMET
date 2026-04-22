import 'package:flutter/material.dart';
import 'package:smet/page/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:data_table_2/data_table_2.dart'; // Ensure it's imported in pubspec

class DashboardPerformanceTab extends StatelessWidget {
  final DashboardPerformance performance;

  const DashboardPerformanceTab({super.key, required this.performance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTopUsersTable("Người dùng xuất sắc", performance.topUsers, const Color(0xFF10B981)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildTopUsersTable("Người dùng cần hỗ trợ", performance.lowUsers, const Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCoursePerformanceTable(),
        ],
      ),
    );
  }

  Widget _buildTopUsersTable(String title, List<LeaderboardItem> users, Color headerColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: headerColor.darken),
            ),
          ),
          SizedBox(
            height: 300,
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 16,
              columns: const [
                DataColumn2(label: Text('Tên người dùng'), size: ColumnSize.L),
                DataColumn2(label: Text('Điểm trung bình'), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Text('Tổng điểm'), size: ColumnSize.M, numeric: true),
              ],
              rows: users.map((user) => DataRow(
                cells: [
                  DataCell(Text(user.userName, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(user.avgScore.toStringAsFixed(1))),
                  DataCell(Text(user.finalScore.toStringAsFixed(1), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                ]
              )).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCoursePerformanceTable() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Hiệu Suất Khoá Học",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 16,
              columns: const [
                DataColumn2(label: Text('Tên Khoá học'), size: ColumnSize.L),
                DataColumn2(label: Text('Số Lượng Đăng ký'), size: ColumnSize.M, numeric: true),
                DataColumn2(label: Text('Tỉ lệ hoàn thành'), size: ColumnSize.M, numeric: true),
              ],
              rows: performance.coursePerformance.map((course) => DataRow(
                cells: [
                  DataCell(Text(course.courseTitle, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(course.enrollments.toString())),
                  DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${course.completionRate}%', style: TextStyle(fontWeight: FontWeight.bold, color: course.completionRate > 50 ? Colors.green : Colors.red)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: LinearProgressIndicator(
                            value: course.completionRate / 100,
                            backgroundColor: Colors.grey[200],
                            color: course.completionRate > 50 ? Colors.green : Colors.red,
                          ),
                        )
                      ],
                    )
                  ),
                ]
              )).toList(),
            ),
          )
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color get darken {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
