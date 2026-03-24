import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class EmployeeLearningPathPage extends StatefulWidget {
  const EmployeeLearningPathPage({super.key});

  @override
  State<EmployeeLearningPathPage> createState() =>
      _EmployeeLearningPathPageState();
}

class _EmployeeLearningPathPageState extends State<EmployeeLearningPathPage> {
  List<LearningPathInfo> _paths = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    setState(() => _isLoading = true);
    try {
      final paths = await LmsService.getMyLearningPaths(
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _paths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải lộ trình học';
        _isLoading = false;
      });
    }
  }

  List<LearningPathInfo> get filteredPaths => _paths;

  Widget buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF137FEC), Color(0xFF0D5ED6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF137FEC).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lộ trình học tập',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_paths.length} lộ trình được giao',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double percent) {
    final color =
        percent >= 100
            ? Colors.green
            : percent >= 50
            ? Colors.orange
            : Colors.blue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percent.round()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPathsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadPaths, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (filteredPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Chưa có lộ trình nào được giao'
                  : 'Không tìm thấy lộ trình',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredPaths.length,
      itemBuilder: (ctx, i) {
        final path = filteredPaths[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // TODO: Navigate to path detail
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF137FEC).withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.route,
                            color: Color(0xFF137FEC),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                path.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${path.courseCount} khóa học',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    if (path.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        path.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildProgressBar(path.progressPercent),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SharedBreadcrumb(
              items: const [
                BreadcrumbItem(
                  label: 'Trang chủ',
                  route: '/employee/dashboard',
                ),
                BreadcrumbItem(label: 'Lộ trình học tập'),
              ],
              primaryColor: const Color(0xFF137FEC),
              fontSize: 11,
              padding: EdgeInsets.zero,
            ),
            const Text(
              'Lộ trình học tập',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.grey),
            onPressed: () => context.go('/employee/dashboard'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _loadPaths();
              },
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm lộ trình...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Expanded(child: buildPathsList()),
        ],
      ),
    );
  }
}
