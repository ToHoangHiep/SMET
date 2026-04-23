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
    download_helper.downloadPdfWeb(bytes as dynamic, filename);
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
    final qrCode = cert.code.isNotEmpty ? cert.code : cert.displayCode;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QUÉT ĐỂ XÁC MINH',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cert.courseName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  size: 160,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A56B4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _copiedCode == cert.displayCode ? Icons.check : Icons.copy,
                        size: 14,
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

  @override
  Widget build(BuildContext context) {
    final isWebOrDesktop = kIsWeb ||
        MediaQuery.of(context).size.width >= 768 ||
        !Platform.isAndroid && !Platform.isIOS;

    if (isWebOrDesktop) {
      return _CertificateWeb(
        courseId: widget.courseId,
        tabController: _tabController,
        myCertificate: _myCertificate,
        myCertificateError: _myCertificateError,
        isLoading: _isLoading,
        isDownloading: _isDownloading,
        isViewing: _isViewing,
        verifiedCertificate: _verifiedCertificate,
        verifyError: _verifyError,
        verifyCode: _verifyCode,
        copiedCode: _copiedCode,
        certificates: _certificates,
        totalPages: _totalPages,
        totalElements: _totalElements,
        currentPage: _currentPage,
        isLoadingList: _isLoadingList,
        hasLoadedList: _hasLoadedList,
        onLoadMyCertificate: _loadMyCertificate,
        onLoadCertificatesList: () => _loadCertificatesList(reset: true),
        onLoadNextPage: _loadNextPage,
        onDownload: _downloadCertificate,
        onView: _viewCertificate,
        onViewVerified: _viewVerifiedCertificate,
        onShare: _shareCertificate,
        onCopyCode: (display, {raw}) => _copyCode(display, rawCode: raw),
        onVerify: (code) => _verifyCertificate(code),
        onShowQr: _showQrDialog,
        onBack: () => context.pop(),
        onGoHome: () => context.go('/employee/dashboard'),
      );
    }

    return _CertificateMobile(
      courseId: widget.courseId,
      tabController: _tabController,
      myCertificate: _myCertificate,
      myCertificateError: _myCertificateError,
      isLoading: _isLoading,
      isDownloading: _isDownloading,
      isViewing: _isViewing,
      verifiedCertificate: _verifiedCertificate,
      verifyError: _verifyError,
      verifyCode: _verifyCode,
      copiedCode: _copiedCode,
      certificates: _certificates,
      totalPages: _totalPages,
      totalElements: _totalElements,
      currentPage: _currentPage,
      isLoadingList: _isLoadingList,
      hasLoadedList: _hasLoadedList,
      onLoadMyCertificate: _loadMyCertificate,
      onLoadCertificatesList: () => _loadCertificatesList(reset: true),
      onLoadNextPage: _loadNextPage,
      onDownload: _downloadCertificate,
      onView: _viewCertificate,
      onViewVerified: _viewVerifiedCertificate,
      onShare: _shareCertificate,
      onCopyCode: (display, {raw}) => _copyCode(display, rawCode: raw),
      onVerify: (code) => _verifyCertificate(code),
      onShowQr: _showQrDialog,
      onBack: () => context.pop(),
      onGoHome: () => context.go('/employee/dashboard'),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// WEB LAYOUT
// ──────────────────────────────────────────────────────────────────────────────

class _CertificateWeb extends StatelessWidget {
  final String? courseId;
  final TabController tabController;
  final CertificateInfo? myCertificate;
  final String? myCertificateError;
  final bool isLoading;
  final bool isDownloading;
  final bool isViewing;
  final CertificateInfo? verifiedCertificate;
  final String? verifyError;
  final String? verifyCode;
  final String? copiedCode;
  final List<CertificateInfo> certificates;
  final int totalPages;
  final int totalElements;
  final int currentPage;
  final bool isLoadingList;
  final bool hasLoadedList;
  final VoidCallback onLoadMyCertificate;
  final VoidCallback onLoadCertificatesList;
  final VoidCallback onLoadNextPage;
  final Future<void> Function(CertificateInfo) onDownload;
  final VoidCallback onView;
  final void Function(CertificateInfo) onViewVerified;
  final void Function(CertificateInfo) onShare;
  final void Function(String, {String? raw}) onCopyCode;
  final Future<void> Function(String) onVerify;
  final void Function(CertificateInfo) onShowQr;
  final VoidCallback onBack;
  final VoidCallback onGoHome;

  const _CertificateWeb({
    required this.courseId,
    required this.tabController,
    required this.myCertificate,
    required this.myCertificateError,
    required this.isLoading,
    required this.isDownloading,
    required this.isViewing,
    required this.verifiedCertificate,
    required this.verifyError,
    required this.verifyCode,
    required this.copiedCode,
    required this.certificates,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
    required this.isLoadingList,
    required this.hasLoadedList,
    required this.onLoadMyCertificate,
    required this.onLoadCertificatesList,
    required this.onLoadNextPage,
    required this.onDownload,
    required this.onView,
    required this.onViewVerified,
    required this.onShare,
    required this.onCopyCode,
    required this.onVerify,
    required this.onShowQr,
    required this.onBack,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: onBack,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: courseId != null ? onLoadMyCertificate : onLoadCertificatesList,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.grey),
            onPressed: onGoHome,
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          labelColor: const Color(0xFF137FEC),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF137FEC),
          tabs: const [Tab(text: 'Chứng chỉ của tôi'), Tab(text: 'Xác minh')],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          courseId != null
              ? _buildSingleCertTabWeb()
              : _buildCertListTabWeb(),
          _buildVerifyTabWeb(),
        ],
      ),
    );
  }

  Widget _buildSingleCertTabWeb() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (myCertificate != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _CertCardWeb(
              cert: myCertificate!,
              showDownload: true,
              onDownload: () => onDownload(myCertificate!),
              onView: onView,
              isDownloading: isDownloading,
              isViewing: isViewing,
              onShare: () => onShare(myCertificate!),
              onShowQr: () => onShowQr(myCertificate!),
              copiedCode: copiedCode,
              onCopyCode: (d, {raw}) => onCopyCode(d, raw: raw),
            ),
          ),
        ),
      );
    }
    if (myCertificateError != null) {
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
              Text(myCertificateError!, style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onLoadMyCertificate,
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
          Text('Chưa có chứng chỉ nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCertListTabWeb() {
    if (!hasLoadedList && isLoadingList) return const Center(child: CircularProgressIndicator());
    if (certificates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Chưa có chứng chỉ nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Hoàn thành khóa học để nhận chứng chỉ', style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onLoadCertificatesList,
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
      onRefresh: () async => onLoadCertificatesList(),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: certificates.length + 1 + (currentPage < totalPages - 1 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$totalElements chứng chỉ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
            );
          }
          final itemIndex = index - 1;
          if (itemIndex == certificates.length) {
            if (isLoadingList) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }
            return Center(child: TextButton(onPressed: onLoadNextPage, child: const Text('Tải thêm')));
          }
          final cert = certificates[itemIndex];
          return _CertListItemWeb(
            cert: cert,
            onTap: () => _showCertDetailSheet(context, cert),
          );
        },
      ),
    );
  }

  void _showCertDetailSheet(BuildContext context, CertificateInfo cert) {
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
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _CertCardWeb(
                      cert: cert,
                      showDownload: true,
                      onDownload: () => onDownload(cert),
                      onView: () => onViewVerified(cert),
                      isDownloading: isDownloading,
                      isViewing: isViewing,
                      onShare: () => onShare(cert),
                      onShowQr: () => onShowQr(cert),
                      copiedCode: copiedCode,
                      onCopyCode: (d, {raw}) => onCopyCode(d, raw: raw),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyTabWeb() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Xác minh chứng chỉ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Nhập mã chứng chỉ để xác minh tính hợp lệ', style: TextStyle(color: Colors.grey[600])),
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
                        onChanged: (v) => verifyCode == v,
                        decoration: const InputDecoration(
                          hintText: 'Nhập mã chứng chỉ (VD: CERT-ABC123)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => onVerify(verifyCode ?? ''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Xác minh'),
                      ),
                    ),
                  ],
                ),
              ),
              if (verifyError != null) ...[
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
                      Expanded(child: Text('Không tìm thấy chứng chỉ với mã này', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ],
              if (verifiedCertificate != null) ...[
                const SizedBox(height: 24),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _CertCardWeb(
                      cert: verifiedCertificate!,
                      isVerified: true,
                      showDownload: true,
                      onDownload: () => onDownload(verifiedCertificate!),
                      onView: () => onViewVerified(verifiedCertificate!),
                      isDownloading: isDownloading,
                      isViewing: isViewing,
                      onShare: () => onShare(verifiedCertificate!),
                      onShowQr: () => onShowQr(verifiedCertificate!),
                      copiedCode: copiedCode,
                      onCopyCode: (d, {raw}) => onCopyCode(d, raw: raw),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// WEB: CERTIFICATE CARD
// ──────────────────────────────────────────────────────────────────────────────

class _CertCardWeb extends StatelessWidget {
  final CertificateInfo cert;
  final bool isVerified;
  final bool showDownload;
  final VoidCallback? onDownload;
  final VoidCallback? onView;
  final bool isDownloading;
  final bool isViewing;
  final VoidCallback? onShare;
  final VoidCallback? onShowQr;
  final String? copiedCode;
  final void Function(String, {String? raw}) onCopyCode;

  const _CertCardWeb({
    required this.cert,
    this.isVerified = false,
    this.showDownload = false,
    this.onDownload,
    this.onView,
    this.isDownloading = false,
    this.isViewing = false,
    this.onShare,
    this.onShowQr,
    this.copiedCode,
    required this.onCopyCode,
  });

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                    const Text('CHỨNG CHỈ HOÀN THÀNH',
                        style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(cert.courseName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(radius: 36, backgroundColor: Colors.white.withAlpha(51), child: const Icon(Icons.person, color: Colors.white, size: 36)),
                    const SizedBox(height: 12),
                    Text(cert.userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    if (cert.departmentName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(cert.departmentName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _infoChip(Icons.calendar_today, 'Ngày cấp: ${_formatDate(cert.issuedAt)}'),
                        if (cert.expiresAt != null) ...[
                          const SizedBox(width: 12),
                          _infoChip(Icons.event, 'Hết hạn: ${_formatDate(cert.expiresAt!)}'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onShowQr,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            Text('Hiện QR để xác minh', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new, color: Colors.white54, size: 14),
                          ],
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Đã xác minh thành công', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isViewing ? null : onView,
                  icon: isViewing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A56B4)))
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
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(isDownloading ? 'Đang tải...' : 'Tải về', style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56B4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShare,
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
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
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
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CertListItemWeb extends StatelessWidget {
  final CertificateInfo cert;
  final VoidCallback onTap;

  const _CertListItemWeb({required this.cert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2)),
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
                    Text(cert.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(cert.userName, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    if (cert.departmentName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(cert.departmentName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                    const SizedBox(height: 4),
                    Text('Ngày cấp: ${cert.issuedAt.day}/${cert.issuedAt.month}/${cert.issuedAt.year}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                child: Text(cert.displayCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A56B4), fontFamily: 'monospace')),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MOBILE LAYOUT
// ──────────────────────────────────────────────────────────────────────────────

class _CertificateMobile extends StatelessWidget {
  final String? courseId;
  final TabController tabController;
  final CertificateInfo? myCertificate;
  final String? myCertificateError;
  final bool isLoading;
  final bool isDownloading;
  final bool isViewing;
  final CertificateInfo? verifiedCertificate;
  final String? verifyError;
  final String? verifyCode;
  final String? copiedCode;
  final List<CertificateInfo> certificates;
  final int totalPages;
  final int totalElements;
  final int currentPage;
  final bool isLoadingList;
  final bool hasLoadedList;
  final VoidCallback onLoadMyCertificate;
  final VoidCallback onLoadCertificatesList;
  final VoidCallback onLoadNextPage;
  final Future<void> Function(CertificateInfo) onDownload;
  final VoidCallback onView;
  final void Function(CertificateInfo) onViewVerified;
  final void Function(CertificateInfo) onShare;
  final void Function(String, {String? raw}) onCopyCode;
  final Future<void> Function(String) onVerify;
  final void Function(CertificateInfo) onShowQr;
  final VoidCallback onBack;
  final VoidCallback onGoHome;

  const _CertificateMobile({
    required this.courseId,
    required this.tabController,
    required this.myCertificate,
    required this.myCertificateError,
    required this.isLoading,
    required this.isDownloading,
    required this.isViewing,
    required this.verifiedCertificate,
    required this.verifyError,
    required this.verifyCode,
    required this.copiedCode,
    required this.certificates,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
    required this.isLoadingList,
    required this.hasLoadedList,
    required this.onLoadMyCertificate,
    required this.onLoadCertificatesList,
    required this.onLoadNextPage,
    required this.onDownload,
    required this.onView,
    required this.onViewVerified,
    required this.onShare,
    required this.onCopyCode,
    required this.onVerify,
    required this.onShowQr,
    required this.onBack,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        title: const Text(
          'Chứng chỉ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: courseId != null ? onLoadMyCertificate : onLoadCertificatesList,
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          labelColor: const Color(0xFF137FEC),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF137FEC),
          tabs: const [Tab(text: 'Của tôi'), Tab(text: 'Xác minh')],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          courseId != null
              ? _buildSingleCertTabMobile()
              : _buildCertListTabMobile(),
          _buildVerifyTabMobile(),
        ],
      ),
    );
  }

  Widget _buildSingleCertTabMobile() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (myCertificate != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _CertCardMobile(
          cert: myCertificate!,
          showDownload: true,
          onDownload: () => onDownload(myCertificate!),
          onView: onView,
          isDownloading: isDownloading,
          isViewing: isViewing,
          onShare: () => onShare(myCertificate!),
          onShowQr: () => onShowQr(myCertificate!),
          copiedCode: copiedCode,
          onCopyCode: (d, {raw}) => onCopyCode(d, raw: raw),
        ),
      );
    }
    if (myCertificateError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.orange[400]),
              const SizedBox(height: 16),
              Text(
                'Không thể tải chứng chỉ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(myCertificateError!, style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onLoadMyCertificate,
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Chưa có chứng chỉ nào', style: TextStyle(fontSize: 17, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCertListTabMobile() {
    if (!hasLoadedList && isLoadingList) return const Center(child: CircularProgressIndicator());
    if (certificates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Chưa có chứng chỉ nào', style: TextStyle(fontSize: 17, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Hoàn thành khóa học để nhận chứng chỉ', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onLoadCertificatesList(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: certificates.length + 1 + (currentPage < totalPages - 1 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$totalElements chứng chỉ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
            );
          }
          final itemIndex = index - 1;
          if (itemIndex == certificates.length) {
            if (isLoadingList) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }
            return Center(child: TextButton(onPressed: onLoadNextPage, child: const Text('Tải thêm')));
          }
          final cert = certificates[itemIndex];
          return _CertListItemMobile(
            cert: cert,
            onTap: () => _showCertDetailSheet(context, cert),
          );
        },
      ),
    );
  }

  void _showCertDetailSheet(BuildContext context, CertificateInfo cert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
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
                padding: const EdgeInsets.all(16),
                child: _CertCardMobile(
                  cert: cert,
                  showDownload: true,
                  onDownload: () => onDownload(cert),
                  onView: () => onViewVerified(cert),
                  isDownloading: isDownloading,
                  isViewing: isViewing,
                  onShare: () => onShare(cert),
                  onShowQr: () => onShowQr(cert),
                  copiedCode: copiedCode,
                  onCopyCode: (d, {raw}) => onCopyCode(d, raw: raw),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyTabMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xác minh chứng chỉ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Nhập mã chứng chỉ để xác minh tính hợp lệ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 20),
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
                    onChanged: (v) {},
                    decoration: const InputDecoration(
                      hintText: 'Nhập mã chứng chỉ',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => onVerify(verifyCode ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Xác minh'),
                  ),
                ),
              ],
            ),
          ),
          if (verifyError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Không tìm thấy chứng chỉ với mã này', style: TextStyle(color: Colors.red, fontSize: 14))),
                ],
              ),
            ),
          ],
          if (verifiedCertificate != null) ...[
            const SizedBox(height: 24),
            _CertCardMobile(
              cert: verifiedCertificate!,
              isVerified: true,
              showDownload: true,
              onDownload: () => onDownload(verifiedCertificate!),
              onView: () => onViewVerified(verifiedCertificate!),
              isDownloading: isDownloading,
              isViewing: isViewing,
              onShare: () => onShare(verifiedCertificate!),
              onShowQr: () => onShowQr(verifiedCertificate!),
              copiedCode: copiedCode,
              onCopyCode: (d, {raw}) => onCopyCode(d, raw: raw),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MOBILE: CERTIFICATE CARD
// ──────────────────────────────────────────────────────────────────────────────

class _CertCardMobile extends StatelessWidget {
  final CertificateInfo cert;
  final bool isVerified;
  final bool showDownload;
  final VoidCallback? onDownload;
  final VoidCallback? onView;
  final bool isDownloading;
  final bool isViewing;
  final VoidCallback? onShare;
  final VoidCallback? onShowQr;
  final String? copiedCode;
  final void Function(String, {String? raw}) onCopyCode;

  const _CertCardMobile({
    required this.cert,
    this.isVerified = false,
    this.showDownload = false,
    this.onDownload,
    this.onView,
    this.isDownloading = false,
    this.isViewing = false,
    this.onShare,
    this.onShowQr,
    this.copiedCode,
    required this.onCopyCode,
  });

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Certificate visual
        Container(
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
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white24)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified, color: Colors.amber, size: 32),
                    const SizedBox(height: 6),
                    const Text('CHỨNG CHỈ HOÀN THÀNH',
                        style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(cert.courseName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: Colors.white.withAlpha(51), child: const Icon(Icons.person, color: Colors.white, size: 28)),
                    const SizedBox(height: 10),
                    Text(cert.userName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    if (cert.departmentName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(cert.departmentName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _infoChip(Icons.calendar_today, _formatDate(cert.issuedAt)),
                        if (cert.expiresAt != null) _infoChip(Icons.event, _formatDate(cert.expiresAt!)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: onShowQr,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            const Text('Hiện QR', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new, color: Colors.white54, size: 12),
                          ],
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Text('Đã xác minh', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isViewing ? null : onView,
                  icon: isViewing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.open_in_new, size: 16),
                  label: Text(isViewing ? 'Đang mở...' : 'Xem', style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A56B4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF1A56B4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDownloading ? null : onDownload,
                  icon: isDownloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(isDownloading ? 'Tải...' : 'Tải về', style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56B4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Chia sẻ liên kết'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CertListItemMobile extends StatelessWidget {
  final CertificateInfo cert;
  final VoidCallback onTap;

  const _CertListItemMobile({required this.cert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56B4), Color(0xFF0D3A8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cert.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Ngày cấp: ${cert.issuedAt.day}/${cert.issuedAt.month}/${cert.issuedAt.year}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(cert.displayCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1A56B4), fontFamily: 'monospace')),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
