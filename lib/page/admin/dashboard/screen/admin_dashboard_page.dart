import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smet/page/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:smet/page/admin/dashboard/service/admin_dashboard_service.dart';
import 'package:smet/page/admin/dashboard/widgets/dashboard_overview_tab.dart';
import 'package:smet/page/admin/dashboard/widgets/dashboard_analytics_tab.dart';
import 'package:smet/page/admin/dashboard/widgets/dashboard_performance_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollingTimer;

  bool _isLoading = true;
  String _error = '';

  DashboardSummary? _summary;
  DashboardTrend? _trend;
  List<DashboardAlert> _alerts = [];
  DashboardPerformance? _performance;
  List<DashboardInsight> _insights = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    _fetchDashboardData();

    // Set up polling (e.g., every 5 minutes)
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchDashboardData(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final api = AdminDashboardApi();
      
      final results = await Future.wait([
        api.getSummary(),
        api.getAlerts(),
        api.getInsights(),
        api.getTrends(),
        api.getPerformance(),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as DashboardSummary;
          _alerts = results[1] as List<DashboardAlert>;
          _insights = results[2] as List<DashboardInsight>;
          _trend = results[3] as DashboardTrend;
          _performance = results[4] as DashboardPerformance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi không thể tải dữ liệu Dashboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty 
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                : RefreshIndicator(
                    onRefresh: () => _fetchDashboardData(isRefresh: true),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        DashboardOverviewTab(
                          summary: _summary!,
                          alerts: _alerts,
                          insights: _insights,
                        ),
                        DashboardAnalyticsTab(
                          trend: _trend!,
                        ),
                        DashboardPerformanceTab(
                          performance: _performance!,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bảng điều khiển Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tổng quan hệ thống phân tích theo thời gian thực',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _fetchDashboardData(isRefresh: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF4F46E5),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Phân tích'),
              Tab(text: 'Hiệu suất'),
            ],
          ),
        ],
      ),
    );
  }
}
