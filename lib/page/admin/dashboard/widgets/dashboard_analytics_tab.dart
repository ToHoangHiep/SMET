import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smet/page/admin/dashboard/models/admin_dashboard_models.dart';

class DashboardAnalyticsTab extends StatefulWidget {
  final DashboardTrend trend;

  const DashboardAnalyticsTab({super.key, required this.trend});

  @override
  State<DashboardAnalyticsTab> createState() => _DashboardAnalyticsTabState();
}

class _DashboardAnalyticsTabState extends State<DashboardAnalyticsTab> {
  // Trạng thái bật/tắt từng đường biểu đồ
  bool _showEnrollments = true;
  bool _showCompletions = true;
  bool _showUsers = true;

  @override
  Widget build(BuildContext context) {
    // Nếu không có dữ liệu gì để vẽ
    if (widget.trend.enrollments.isEmpty && 
        widget.trend.completions.isEmpty && 
        widget.trend.users.isEmpty) {
      return Center(
        child: Text(
          "Không có dữ liệu phân tích trong khoảng thời gian này.",
          style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 16),
        )
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân tích xu hướng',
            style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            'Lưu lượng người dùng, ghi danh và hoàn thành khóa học theo từng ngày. Bạn có thể nhấn vào biểu tượng (Chú thích) để ẩn/hiện từng loại dữ liệu.',
            style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Chú thích (Legend)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendIndicator(
                color: const Color(0xFF4F46E5), 
                text: 'Lượt ghi danh', 
                isActive: _showEnrollments,
                onTap: () => setState(() => _showEnrollments = !_showEnrollments)
              ),
              const SizedBox(width: 24),
              _buildLegendIndicator(
                color: const Color(0xFF10B981), 
                text: 'Lượt hoàn thành', 
                isActive: _showCompletions,
                onTap: () => setState(() => _showCompletions = !_showCompletions)
              ),
              const SizedBox(width: 24),
              _buildLegendIndicator(
                color: const Color(0xFFF59E0B), 
                text: 'Người dùng mới', 
                isActive: _showUsers,
                onTap: () => setState(() => _showUsers = !_showUsers)
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Biểu đồ LineChart
          Container(
            height: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: LineChart(_buildChartData()),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator({required Color color, required String text, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : Colors.grey[300],
                border: Border.all(color: isActive ? color : Colors.grey, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.notoSans(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF374151) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    List<LineChartBarData> lines = [];
    
    // Đường biểu diễn Enrollments (Ghi danh)
    if (_showEnrollments && widget.trend.enrollments.isNotEmpty) {
      lines.add(_createLineData(widget.trend.enrollments, const Color(0xFF4F46E5)));
    }
    // Đường biểu diễn Completions (Hoàn thành)
    if (_showCompletions && widget.trend.completions.isNotEmpty) {
      lines.add(_createLineData(widget.trend.completions, const Color(0xFF10B981)));
    }
    // Đường biểu diễn Users (Người dùng học)
    if (_showUsers && widget.trend.users.isNotEmpty) {
      lines.add(_createLineData(widget.trend.users, const Color(0xFFF59E0B)));
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.black.withValues(alpha: 0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()}',
                GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1, dashArray: [5, 5]),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              // Lấy date từ data đầu tiên hiện có để làm nhãn X
              List<DashboardTrendPoint> srcList = widget.trend.enrollments.isNotEmpty ? widget.trend.enrollments : 
                                                  (widget.trend.completions.isNotEmpty ? widget.trend.completions : widget.trend.users);
              if (index >= 0 && index < srcList.length) {
                // Formatting Date ngắn gọn, ví dụ "Mon", "Tue" hoặc "Ngày X" tuỳ input
                DateTime? parsedDate;
                try {
                  parsedDate = DateTime.parse(srcList[index].date);
                } catch(_) {}

                String label = srcList[index].date;
                if (parsedDate != null) {
                  label = "${parsedDate.day}/${parsedDate.month}";
                } else if (label.length > 5) {
                  label = label.substring(0, 5); // Cắt ngắn nếu raw string quá dài
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(label, style: GoogleFonts.notoSans(color: Colors.grey[600], fontSize: 12)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(value.toInt().toString(), style: GoogleFonts.notoSans(color: Colors.grey[600], fontSize: 12)),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: lines,
    );
  }

  LineChartBarData _createLineData(List<DashboardTrendPoint> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: color);
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }
}
