import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/core/theme/app_colors.dart';
import 'package:smet/page/employee/learning_path/screen/learning_path_web.dart';
import 'package:smet/page/employee/learning_path/screen/learning_path_mobile.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/employee/lms_service.dart';

export 'package:smet/page/shared/widgets/shared_breadcrumb.dart' show BreadcrumbItem;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
        _error = 'Không thể tải lộ trình học. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb || constraints.maxWidth > 768) {
          return EmployeeLearningPathWeb(
            paths: _paths,
            isLoading: _isLoading,
            error: _error,
            searchQuery: _searchQuery,
            breadcrumbs: const [
              BreadcrumbItem(label: 'Trang chủ', route: '/employee/dashboard'),
              BreadcrumbItem(label: 'Lộ trình học tập'),
            ],
            onSearchChanged: (v) {
              _searchQuery = v;
              _loadPaths();
            },
            onRetry: _loadPaths,
          );
        }

        return EmployeeLearningPathMobile(
          paths: _paths,
          isLoading: _isLoading,
          error: _error,
          searchQuery: _searchQuery,
          onSearchChanged: (v) {
            _searchQuery = v;
            _loadPaths();
          },
          onRetry: _loadPaths,
        );
      },
    );
  }
}
