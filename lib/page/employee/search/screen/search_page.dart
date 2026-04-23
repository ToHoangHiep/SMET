import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/search/widgets/search_page_web.dart';
import 'package:smet/page/employee/search/widgets/search_page_mobile.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  SearchResult? _result;
  bool _isLoading = false;
  String? _error;
  String _keyword = '';

  Future<void> _search() async {
    if (_keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await LmsService.search(_keyword);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tìm kiếm: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebOrDesktop = kIsWeb ||
        MediaQuery.of(context).size.width >= 768 ||
        !Platform.isAndroid && !Platform.isIOS;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: Column(
        children: [
          SharedBreadcrumb(
            items: const [
              BreadcrumbItem(
                label: 'Trang chủ',
                route: '/employee/dashboard',
              ),
              BreadcrumbItem(label: 'Tìm kiếm'),
            ],
          ),
          Expanded(
            child: isWebOrDesktop
                ? SearchPageWeb(
                    keyword: _keyword,
                    result: _result,
                    isLoading: _isLoading,
                    error: _error,
                    onKeywordChanged: (v) => _keyword = v,
                    onSearch: _search,
                    onClear: () {
                      setState(() {
                        _result = null;
                        _keyword = '';
                      });
                    },
                    onCourseTap: (course) =>
                        context.go('/employee/course/${course.id}?from=search'),
                  )
                : SearchPageMobile(
                    keyword: _keyword,
                    result: _result,
                    isLoading: _isLoading,
                    error: _error,
                    onKeywordChanged: (v) => _keyword = v,
                    onSearch: _search,
                    onClear: () {
                      setState(() {
                        _result = null;
                        _keyword = '';
                      });
                    },
                    onCourseTap: (course) =>
                        context.go('/employee/course/${course.id}?from=search'),
                    onBack: () => context.pop(),
                  ),
          ),
        ],
      ),
    );
  }
}
