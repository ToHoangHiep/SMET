import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/service/common/base_url.dart';

enum AssignmentItemType { course, learningPath }

class AssignmentItem {
  final int id;
  final String title;
  final String description;
  final int count;
  final AssignmentItemType type;
  final String? imageUrl;

  AssignmentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.count,
    required this.type,
    this.imageUrl,
  });

  factory AssignmentItem.fromCourseJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Khóa học',
      description: json['description'] ?? '',
      count: json['courseCount'] ?? json['lessonCount'] ?? 0,
      type: AssignmentItemType.course,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  factory AssignmentItem.fromLearningPathJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Learning Path',
      description: json['description'] ?? '',
      count: json['courseCount'] ?? 0,
      type: AssignmentItemType.learningPath,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class CourseLPSelectionDialog extends StatefulWidget {
  final Color primaryColor;
  final AssignmentItemType allowedType;
  final String title;

  const CourseLPSelectionDialog({
    super.key,
    required this.primaryColor,
    required this.allowedType,
    this.title = 'Chọn khóa học / Learning Path',
  });

  static Future<List<AssignmentItem>?> showForCourse({
    required BuildContext context,
    required Color primaryColor,
  }) {
    return showDialog<List<AssignmentItem>>(
      context: context,
      builder: (context) => CourseLPSelectionDialog(
        primaryColor: primaryColor,
        allowedType: AssignmentItemType.course,
        title: 'Chọn khóa học để gán',
      ),
    );
  }

  static Future<List<AssignmentItem>?> showForLearningPath({
    required BuildContext context,
    required Color primaryColor,
  }) {
    return showDialog<List<AssignmentItem>>(
      context: context,
      builder: (context) => CourseLPSelectionDialog(
        primaryColor: primaryColor,
        allowedType: AssignmentItemType.learningPath,
        title: 'Chọn Learning Path để gán',
      ),
    );
  }

  @override
  State<CourseLPSelectionDialog> createState() => _CourseLPSelectionDialogState();
}

class _CourseLPSelectionDialogState extends State<CourseLPSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<AssignmentItem> _items = [];
  List<AssignmentItem> _selectedItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  bool _hasNext = true;
  String _searchQuery = '';
  bool _isMultiSelect = false;

  String get _baseUrl => baseUrl;
  String get _tokenKey => "token";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _loadItems({bool append = false}) async {
    if (append) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      String endpoint;
      if (widget.allowedType == AssignmentItemType.course) {
        endpoint = '$_baseUrl/lms/courses';
      } else {
        endpoint = '$_baseUrl/lms/learning-paths';
      }

      final params = <String, String>{
        'page': (append ? _currentPage : 0).toString(),
        'size': '20',
      };
      if (_searchQuery.isNotEmpty) {
        params['keyword'] = _searchQuery;
      }

      final uri = Uri.parse(endpoint).replace(queryParameters: params);
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> content =
            (data['data'] ?? data['content'] ?? []) as List<dynamic>;

        final items = content.map((e) {
          if (widget.allowedType == AssignmentItemType.course) {
            return AssignmentItem.fromCourseJson(e as Map<String, dynamic>);
          } else {
            return AssignmentItem.fromLearningPathJson(e as Map<String, dynamic>);
          }
        }).toList();

        int totalPages = data['totalPages'] ?? 1;
        int currentPage = data['page'] ?? 0;

        setState(() {
          if (append) {
            _items.addAll(items);
            _isLoadingMore = false;
          } else {
            _items = items;
            _isLoading = false;
          }
          _hasNext = currentPage < totalPages - 1;
          _currentPage = currentPage + 1;
        });
      } else {
        throw Exception("HTTP ${res.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Không thể tải danh sách';
      });
    }
  }

  void _toggleItem(AssignmentItem item) {
    setState(() {
      if (!_isMultiSelect) {
        _selectedItems = [item];
      } else {
        final exists = _selectedItems.any((s) => s.id == item.id && s.type == item.type);
        if (exists) {
          _selectedItems.removeWhere((s) => s.id == item.id && s.type == item.type);
        } else {
          _selectedItems.add(item);
        }
      }
    });
  }

  bool _isSelected(AssignmentItem item) {
    return _selectedItems.any((s) => s.id == item.id && s.type == item.type);
  }

  String get _itemTypeLabel {
    return widget.allowedType == AssignmentItemType.course ? 'khóa học' : 'Learning Path';
  }

  IconData get _itemIcon {
    return widget.allowedType == AssignmentItemType.course
        ? Icons.school_outlined
        : Icons.route_outlined;
  }

  @override
  void initState() {
    super.initState();
    _isMultiSelect = true; // Cho phép chọn nhiều khóa học và Learning Path
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const Divider(height: 1),
            _buildItemList(),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_itemIcon, color: widget.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  _isMultiSelect ? 'Chọn nhiều $_itemTypeLabel' : 'Chọn một $_itemTypeLabel',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _currentPage = 0;
              _items = [];
            });
            _loadItems();
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm $_itemTypeLabel...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 0;
                        _items = [];
                      });
                      _loadItems();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    if (_isLoading) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red[600])),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadItems(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Không có $_itemTypeLabel nào',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 350,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              !_isLoadingMore &&
              _hasNext) {
            _loadItems(append: true);
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _items.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = _items[index];
            return _ItemListTile(
              item: item,
              isSelected: _isSelected(item),
              isMultiSelect: _isMultiSelect,
              primaryColor: widget.primaryColor,
              onTap: () => _toggleItem(item),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isMultiSelect
                ? 'Đã chọn: ${_selectedItems.length} $_itemTypeLabel'
                : (_selectedItems.isNotEmpty ? _selectedItems.first.title : ''),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedItems.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selectedItems),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isMultiSelect ? 'Tiếp tục (${_selectedItems.length})' : 'Tiếp tục'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemListTile extends StatelessWidget {
  final AssignmentItem item;
  final bool isSelected;
  final bool isMultiSelect;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ItemListTile({
    required this.item,
    required this.isSelected,
    required this.isMultiSelect,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? primaryColor.withValues(alpha: 0.05) : Colors.transparent,
        child: Row(
          children: [
            if (isMultiSelect)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              )
            else
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Icon(
                item.type == AssignmentItemType.course
                    ? Icons.school_outlined
                    : Icons.route_outlined,
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        item.type == AssignmentItemType.course
                            ? Icons.book_outlined
                            : Icons.school_outlined,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.type == AssignmentItemType.course
                            ? '${item.count} bài học'
                            : '${item.count} khóa học',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
