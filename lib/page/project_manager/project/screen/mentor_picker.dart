import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smet/service/project/project_member_service.dart';

/// Sheet chọn Mentor với search + phân trang (API /users/for-project, filter MENTOR role)
class MentorPickerSheetContent extends StatefulWidget {
  final int departmentId;
  final int pageSize;
  final Function(Map<String, dynamic>) onSelectMentor;

  const MentorPickerSheetContent({
    required this.departmentId,
    required this.pageSize,
    required this.onSelectMentor,
  });

  @override
  State<MentorPickerSheetContent> createState() => MentorPickerSheetContentState();
}

class MentorPickerSheetContentState extends State<MentorPickerSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _keyword = '';
  int _page = 0;
  bool _hasNext = true;
  Timer? _debounce;

  static const Color primaryAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadPage();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPage({bool append = false}) async {
    if (append && (!_hasNext || _isLoadingMore)) return;

    if (append) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final result = await ProjectMemberService.getUsersForProjectPaginated(
        departmentId: widget.departmentId,
        keyword: _keyword.isNotEmpty ? _keyword : null,
        role: 'MENTOR',
        page: append ? _page : 0,
        size: widget.pageSize,
      );

      setState(() {
        if (append) {
          _users.addAll(result['users'] as List<Map<String, dynamic>>);
          _isLoadingMore = false;
        } else {
          _users = result['users'] as List<Map<String, dynamic>>;
          _isLoading = false;
        }
        _hasNext = (_page + 1) < (result['totalPages'] as int);
        _page = (append ? _page : 0) + 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      _loadPage(append: true);
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _keyword = value;
        _page = 0;
        _users = [];
      });
      _loadPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_outlined, color: primaryAmber, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Chọn Người hướng dẫn',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryAmber),
                  ),
                  child: const Text('Mentor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryAmber)),
                ),
                const SizedBox(width: 8),
                Text('Người hướng dẫn', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryAmber))
                : _users.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(_keyword.isEmpty ? 'Không có mentor nào' : 'Không tìm thấy kết quả',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= _users.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(color: primaryAmber)),
                            );
                          }
                          return _buildMentorTile(_users[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorTile(Map<String, dynamic> u) {
    final firstName = u['firstName'] ?? '';
    final lastName = u['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = u['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onSelectMentor(u);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryAmber,
                  radius: 22,
                  child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF111827))),
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Mentor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryAmber)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
