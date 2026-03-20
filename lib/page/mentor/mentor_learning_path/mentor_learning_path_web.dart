import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/service/mentor/learning_path_service.dart';

/// Mentor Learning Path - Web Layout (Danh sach Lo trinh hoc tap)
class MentorLearningPathWeb extends StatefulWidget {
  const MentorLearningPathWeb({super.key});

  @override
  State<MentorLearningPathWeb> createState() => _MentorLearningPathWebState();
}

class _MentorLearningPathWebState extends State<MentorLearningPathWeb> {
  final LearningPathService _service = LearningPathService();

  List<LearningPathResponse> _paths = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadLearningPaths();
  }

  Future<void> _loadLearningPaths({int page = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final result = await _service.getAllLearningPaths(
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
        page: page,
        size: _pageSize,
      );
      setState(() {
        _paths = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
    _loadLearningPaths(page: 0);
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    _loadLearningPaths(page: page);
  }

  Future<void> _deletePath(Long pathId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xoa lo trinh"),
        content: const Text("Ban co chac chan muon xoa lo trinh hoc tap nay khong?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Huy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Xoa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteLearningPath(pathId);
        _loadLearningPaths(page: _currentPage);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Xoa lo trinh thanh cong")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Xoa that bai: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Column(
        children: [
          /// TOPBAR
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quan ly lo trinh hoc tap",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xff1a90ff),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                )
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  const Text(
                    "Lo trinh hoc tap",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// CREATE BUTTON
                  ElevatedButton.icon(
                    onPressed: () => context.go('/mentor/learning-paths/create'),
                    icon: const Icon(Icons.add),
                    label: const Text("Tao lo trinh moi"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// SEARCH
                  SizedBox(
                    width: 400,
                    child: TextField(
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: "Tim kiem lo trinh...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// TABLE / LIST
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadLearningPaths(page: _currentPage),
              child: const Text("Thu lai"),
            ),
          ],
        ),
      );
    }

    if (_paths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? "Chua co lo trinh hoc tap nao"
                  : "Khong tim thay lo trinh phu hop",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go('/mentor/learning-paths/create'),
                icon: const Icon(Icons.add),
                label: const Text("Tao lo trinh dau tien"),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: _buildTable()),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TABLE HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xfff8f9fc),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text("Lo trinh", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  flex: 2,
                  child: Text("Mo ta", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  flex: 1,
                  child: Text("Khoa hoc", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                const Expanded(
                  flex: 1,
                  child: Text("Bai hoc", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                const Expanded(
                  flex: 2,
                  child: Text("Hanh dong", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ],
            ),
          ),

          /// TABLE ROWS
          Expanded(
            child: ListView.separated(
              itemCount: _paths.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final path = _paths[index];
                return _buildRow(path);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(LearningPathResponse path) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          /// TITLE + BADGE
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffeef3ff),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${path.courseCount} khoa",
                        style: const TextStyle(fontSize: 11, color: Color(0xff1a90ff)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// DESCRIPTION
          Expanded(
            flex: 2,
            child: Text(
              path.description.isEmpty ? "-" : path.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          /// COURSE COUNT
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "${path.courseCount}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          /// MODULE COUNT
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "${path.totalModules}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          /// ACTIONS
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => context.go('/mentor/learning-paths/create?edit=${path.id.value}'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: "Chinh sua",
                  color: Colors.grey[700],
                ),
                IconButton(
                  onPressed: () => _deletePath(path.id),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: "Xoa",
                  color: Colors.red[400],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        ...List.generate(_totalPages, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _goToPage(index),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: index == _currentPage ? const Color(0xff1a90ff) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: index == _currentPage ? const Color(0xff1a90ff) : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: index == _currentPage ? Colors.white : Colors.black,
                      fontWeight: index == _currentPage ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 16),
        Text(
          "$_totalElements items",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }
}
