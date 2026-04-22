import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smet/service/employee/lms_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/service/common/base_url.dart';

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
  bool _isViewing = false;
  CertificateInfo? _myCertificate;
  CertificateInfo? _verifiedCertificate;
  String? _verifyError;
  String? _verifyCode;
  String? _copiedCode;
  String? _myCertificateError;

  // List mode (when courseId is null — accessed from sidebar)
  List<CertificateInfo> _certificates = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoadingList = false;
  bool _hasLoadedList = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.courseId != null) {
      _loadMyCertificate();
    } else {
      _loadCertificatesList();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCertificate() async {
    if (widget.courseId == null) return;
    setState(() {
      _isLoading = true;
      _myCertificateError = null;
    });
    final result = await LmsService.getMyCertificate(widget.courseId!);
    if (mounted) {
      setState(() {
        _myCertificate = result.cert;
        _myCertificateError = result.error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCertificatesList({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _certificates = [];
    }
    if (_isLoadingList) return;
    setState(() => _isLoadingList = true);

    final result = await LmsService.getMyCertificates(page: _currentPage, size: 10);

    if (mounted) {
      setState(() {
        if (reset) {
          _certificates = result.content;
        } else {
          _certificates.addAll(result.content);
        }
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _hasLoadedList = true;
        _isLoadingList = false;
      });
    }
  }

  void _loadNextPage() {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      _loadCertificatesList();
    }
  }

  Future<void> _downloadCertificate(CertificateInfo cert) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final String? courseIdToUse = cert.courseId ?? widget.courseId;

      if (courseIdToUse != null) {
        final bytes = await LmsService.downloadCertificateByCourseId(courseIdToUse);
        if (bytes != null && mounted) {
          _saveAndOpenPdf(bytes, '${cert.courseName}_certificate.pdf');
        } else if (mounted) {
          _showToast('Không thể tải chứng chỉ', isError: true);
        }
      } else if (cert.code.isNotEmpty) {
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

  void _viewCertificate() {
    if (_isViewing) return;
    if (_myCertificate == null) {
      _showToast('Không thể xem chứng chỉ. Vui lòng hoàn thành khóa học trước.', isError: true);
      return;
    }
    final url = LmsService.getCertificateVerifyPdfUrl(_myCertificate!.code);
    download_helper.openPdfInNewTab(url);
  }

  void _viewVerifiedCertificate(CertificateInfo cert) {
    if (_isViewing) return;
    final url = LmsService.getCertificateVerifyPdfUrl(cert.code);
    download_helper.openPdfInNewTab(url);
  }

  void _shareCertificate(CertificateInfo cert) {
    final verifyUrl = cert.certificateUrl ?? _buildVerifyUrl(cert.code);
    Clipboard.setData(ClipboardData(text: verifyUrl));
    _showToast('Đã copy liên kết chia sẻ', isError: false);
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

  Future<void> _copyCode(String displayCode, {String? rawCode}) async {
    // Always copy the full UUID for verification, even when showing shortCode
    await Clipboard.setData(ClipboardData(text: rawCode ?? displayCode));
    setState(() => _copiedCode = displayCode);
    _showToast('Đã copy mã: $displayCode', isError: false);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedCode = null);
    });
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

  String _buildVerifyUrl(String code) {
    return '$baseUrl/lms/certificates/verify/$code';
  }

  void _showQrDialog(CertificateInfo cert) {
    // QR luôn dùng full UUID (verificationCode) để verify chính xác
    final qrCode = cert.code.isNotEmpty ? cert.code : cert.displayCode;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QUÉT ĐỂ XÁC MINH',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cert.courseName,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: QrImageView(
                  data: _buildVerifyUrl(qrCode),
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1A56B4),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A56B4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mã chứng chỉ',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _copyCode(cert.displayCode, rawCode: cert.code),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          cert.displayCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A56B4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _copiedCode == cert.displayCode ? Icons.check : Icons.copy,
                        size: 16,
                        color: _copiedCode == cert.displayCode
                            ? Colors.green
                            : const Color(0xFF1A56B4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56B4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateCard(
    CertificateInfo cert, {
    bool isVerified = false,
    bool showDownload = true,
    VoidCallback? onDownload,
    VoidCallback? onView,
    bool isDownloading = false,
    bool isViewing = false,
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
                    if (cert.departmentName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        cert.departmentName,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
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
                    if (cert.issuer.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoChip(
                        Icons.verified_user,
                        'Issuer: ${cert.issuer}',
                      ),
                    ],
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
                              'Mã: ${cert.displayCode}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyCode(cert.displayCode, rawCode: cert.code),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                _copiedCode == cert.displayCode ? Icons.check : Icons.copy,
                                color: _copiedCode == cert.displayCode
                                    ? Colors.green.shade200
                                    : Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showQrDialog(cert),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_2, color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Hiện QR để xác minh',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new, color: Colors.white54, size: 14),
                          ],
                        ),
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
        if (showDownload && onDownload != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isViewing ? null : onView,
                        icon: isViewing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A56B4)),
                              )
                            : const Icon(Icons.open_in_new, size: 18),
                        label: Text(isViewing ? 'Đang mở...' : 'Xem PDF', style: const TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A56B4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF1A56B4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                          isDownloading ? 'Đang tải...' : 'Tải về',
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
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareCertificate(cert),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Chia sẻ liên kết', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSingleCertTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myCertificate != null) {
      return SingleChildScrollView(
        child: _buildCertificateCard(
          _myCertificate!,
          showDownload: true,
          onDownload: () => _downloadCertificate(_myCertificate!),
          onView: _viewCertificate,
          isDownloading: _isDownloading,
          isViewing: _isViewing,
        ),
      );
    }
    if (_myCertificateError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.orange[400]),
              const SizedBox(height: 16),
              Text(
                'Không thể tải chứng chỉ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                _myCertificateError!,
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadMyCertificate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56B4),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, size: 64, color: Colors.grey[400]),
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
    );
  }

  Widget _buildCertListTab() {
    if (!_hasLoadedList && _isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_certificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, size: 64, color: Colors.grey[400]),
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadCertificatesList(reset: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tải lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56B4),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadCertificatesList(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _certificates.length + 1 + (_currentPage < _totalPages - 1 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$_totalElements chứng chỉ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            );
          }
          final itemIndex = index - 1;
          if (itemIndex == _certificates.length) {
            if (_isLoadingList) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return Center(
              child: TextButton(
                onPressed: _loadNextPage,
                child: const Text('Tải thêm'),
              ),
            );
          }
          final cert = _certificates[itemIndex];
          return _buildCertListItem(cert);
        },
      ),
    );
  }

  Widget _buildCertListItem(CertificateInfo cert) {
    return GestureDetector(
      onTap: () => _showCertDetailBottomSheet(cert),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56B4), Color(0xFF0D3A8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert.courseName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cert.userName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (cert.departmentName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cert.departmentName,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Ngày cấp: ${_formatDate(cert.issuedAt)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cert.displayCode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A56B4),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCertDetailBottomSheet(CertificateInfo cert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _buildCertificateCard(
                  cert,
                  showDownload: true,
                  onDownload: () {
                    Navigator.pop(ctx);
                    _downloadCertificate(cert);
                  },
                  onView: () {
                    Navigator.pop(ctx);
                    final url = LmsService.getCertificateVerifyPdfUrl(cert.code);
                    download_helper.openPdfInNewTab(url);
                  },
                  isDownloading: _isDownloading,
                  isViewing: _isViewing,
                ),
              ),
            ),
          ],
        ),
      ),
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
          // Tab 1: My certificates (list mode) OR single cert by courseId
          widget.courseId != null
              ? _buildSingleCertTab()
              : _buildCertListTab(),
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
                    showDownload: true,
                    onDownload: () => _downloadCertificate(_verifiedCertificate!),
                    onView: () => _viewVerifiedCertificate(_verifiedCertificate!),
                    isDownloading: _isDownloading,
                    isViewing: _isViewing,
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
