import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

import 'package:smet/page/employee/certificate/download_helper.dart'
    if (dart.library.html) 'package:smet/page/employee/certificate/download_helper_web.dart'
    as download_helper;

class CertificatePage extends StatefulWidget {
  final String? courseId;

  const CertificatePage({super.key, this.courseId});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isDownloading = false;
  CertificateInfo? _myCertificate;
  CertificateInfo? _verifiedCertificate;
  String? _verifyError;
  String? _verifyCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.courseId != null) {
      _loadMyCertificate();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCertificate() async {
    if (widget.courseId == null) return;
    setState(() => _isLoading = true);
    try {
      final cert = await LmsService.getMyCertificate(widget.courseId!);
      setState(() {
        _myCertificate = cert;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadCertificate(CertificateInfo cert) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      // Ưu tiên dùng courseId nếu có → endpoint /courses/{courseId}/download
      final String? courseIdToUse = cert.courseId ?? widget.courseId;

      if (courseIdToUse != null) {
        final bytes = await LmsService.downloadCertificateByCourseId(courseIdToUse);
        if (bytes != null && mounted) {
          _saveAndOpenPdf(bytes, '${cert.courseName}_certificate.pdf');
        } else if (mounted) {
          _showToast('Không thể tải chứng chỉ', isError: true);
        }
      } else if (cert.code.isNotEmpty) {
        // Fallback: dùng verificationCode → endpoint /certificates/{code}
        final bytes = await LmsService.downloadCertificatePdf(cert.code);
        if (bytes != null && mounted) {
          _saveAndOpenPdf(bytes, '${cert.courseName}_certificate.pdf');
        } else if (mounted) {
          _showToast('Không thể tải chứng chỉ', isError: true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _saveAndOpenPdf(List<int> bytes, String filename) {
    if (kIsWeb) {
      _downloadWeb(bytes, filename);
    } else {
      _saveMobile(bytes, filename);
    }
  }

  void _downloadWeb(List<int> bytes, String filename) {
    download_helper.downloadPdfWeb(Uint8List.fromList(bytes), filename);
  }

  void _saveMobile(List<int> bytes, String filename) {
    // Mobile: lưu vào thư mục tải về và mở file
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
      _showToast('Đang tải: $filename', isError: false);
    }
  }

  void _showToast(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyCertificate(String code) async {
    if (code.isEmpty) return;
    setState(() {
      _isLoading = true;
      _verifyError = null;
      _verifiedCertificate = null;
      _verifyCode = code;
    });

    try {
      final cert = await LmsService.verifyCertificate(code);
      setState(() {
        _verifiedCertificate = cert;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _verifyError = 'Không tìm thấy chứng chỉ với mã này';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCertificateCard(
    CertificateInfo cert, {
    bool isVerified = false,
    bool showDownload = true,
    VoidCallback? onDownload,
    bool isDownloading = false,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56B4), Color(0xFF0D3A8C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A56B4).withAlpha(77),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white24)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified, color: Colors.amber, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'CHỨNG CHỈ HOÀN THÀNH',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cert.courseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Body
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withAlpha(51),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cert.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đã hoàn thành khóa học',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today,
                          'Ngày cấp: ${_formatDate(cert.issuedAt)}',
                        ),
                        if (cert.expiresAt != null) ...[
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.event,
                            'Hết hạn: ${_formatDate(cert.expiresAt!)}',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Mã: ${cert.code}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Đã xác minh thành công',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Download button
        if (showDownload && onDownload != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isDownloading ? null : onDownload,
                icon: isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  isDownloading ? 'Đang tải...' : 'Tải chứng chỉ PDF',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56B4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
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
                BreadcrumbItem(label: 'Chứng chỉ'),
              ],
              primaryColor: const Color(0xFF137FEC),
              fontSize: 11,
              padding: EdgeInsets.zero,
            ),
            const Text(
              'Chứng chỉ',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF137FEC),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF137FEC),
          tabs: const [Tab(text: 'Chứng chỉ của tôi'), Tab(text: 'Xác minh')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: My Certificates
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _myCertificate != null
                  ? SingleChildScrollView(
                      child: _buildCertificateCard(
                        _myCertificate!,
                        showDownload: true,
                        onDownload: () => _downloadCertificate(_myCertificate!),
                        isDownloading: _isDownloading,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có chứng chỉ nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hoàn thành khóa học để nhận chứng chỉ',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

          // Tab 2: Verify
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xác minh chứng chỉ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập mã chứng chỉ để xác minh tính hợp lệ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => _verifyCode = v,
                          decoration: const InputDecoration(
                            hintText: 'Nhập mã chứng chỉ (VD: CERT-ABC123)',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => _verifyCertificate(_verifyCode ?? ''),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF137FEC),
                            foregroundColor: Colors.white,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Xác minh'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_verifyError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Không tìm thấy chứng chỉ với mã này',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_verifiedCertificate != null) ...[
                  const SizedBox(height: 24),
                  _buildCertificateCard(
                    _verifiedCertificate!,
                    isVerified: true,
                    showDownload: false,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
