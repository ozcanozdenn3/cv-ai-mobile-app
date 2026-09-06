import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import '../constants/theme_constants.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/localization_service.dart';
import '../services/ocr_engine_service.dart';
import '../services/real_document_pipeline_service.dart';
import '../services/app_permission_service.dart';
import 'vip_paywall_sheet.dart';

class ScannedDocPage {
  final String id;
  String name;
  String docType;
  int rotation;
  String filter;
  String ocrText;
  DateTime timestamp;
  Uint8List? imageBytes;
  final Uint8List? rawBytes;

  ScannedDocPage({
    required this.id,
    required this.name,
    required this.docType,
    this.rotation = 0,
    this.filter = 'Magic AI',
    required this.ocrText,
    required this.timestamp,
    this.imageBytes,
    this.rawBytes,
  });
}

class CamScannerScreen extends StatefulWidget {
  final VoidCallback? onReturnHome;

  const CamScannerScreen({
    super.key,
    this.onReturnHome,
  });

  @override
  State<CamScannerScreen> createState() => _CamScannerScreenState();
}

class _CamScannerScreenState extends State<CamScannerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDocModeIndex = 0;
  final int _selectedFilterIndex = 0;
  int _activePageIndex = 0;
  bool _isGridOn = false;
  bool _isProcessing = false;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  final List<ScannedDocPage> _scannedPages = [];

  List<Map<String, dynamic>> _getDocModes() => [
    {
      'title': LocalizationService.tr('scanner_mode_doc'),
      'icon': Icons.description_rounded,
      'ratio': 1.38,
      'badge': 'A4 / DOC',
      'desc': 'Document / Report',
    },
    {
      'title': LocalizationService.tr('scanner_mode_id'),
      'icon': Icons.badge_rounded,
      'ratio': 0.68,
      'badge': 'ID / DUAL',
      'desc': 'ID Card / Passport',
    },
    {
      'title': LocalizationService.tr('scanner_mode_receipt'),
      'icon': Icons.receipt_long_rounded,
      'ratio': 1.60,
      'badge': 'RECEIPT',
      'desc': 'Invoice / Receipt',
    },
    {
      'title': LocalizationService.tr('scanner_mode_ocr'),
      'icon': Icons.contact_page_rounded,
      'ratio': 0.60,
      'badge': 'MICRO',
      'desc': 'Business Card / Notes',
    },
  ];

  List<Map<String, dynamic>> _getFilters() => [
    {
      'name': 'Magic AI',
      'label': LocalizationService.tr('scanner_filter_magic'),
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF3B82F6),
      'desc': 'High Contrast & AI Boost',
    },
    {
      'name': 'Siyah-Beyaz',
      'label': LocalizationService.tr('scanner_filter_bw'),
      'icon': Icons.contrast_rounded,
      'color': const Color(0xFF10B981),
      'desc': 'B&W Sharp Text',
    },
    {
      'name': 'Gri Tonlama',
      'label': LocalizationService.tr('scanner_filter_grayscale'),
      'icon': Icons.filter_b_and_w_rounded,
      'color': const Color(0xFF8B5CF6),
      'desc': 'Copy / Archive',
    },
    {
      'name': 'Orijinal HD',
      'label': LocalizationService.tr('scanner_filter_original'),
      'icon': Icons.photo_size_select_actual_rounded,
      'color': const Color(0xFFF59E0B),
      'desc': 'Raw Original',
    },
  ];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _processCapturedImageBytes(Uint8List bytes, String sourceName) async {
    setState(() => _isProcessing = true);
    final docModes = _getDocModes();
    final filters = _getFilters();
    final mode = docModes[_selectedDocModeIndex.clamp(0, docModes.length - 1)];
    final filter = filters[_selectedFilterIndex.clamp(0, filters.length - 1)];
    final pageNum = _scannedPages.length + 1;

    try {
      String ocrText = '';
      Uint8List effectiveBytes = Uint8List.fromList(bytes);

      try {
        final pipelineResult = await RealDocumentPipelineService.runDocumentEnhancement(
          imageBytes: bytes,
          sourceName: '${mode['title']}_$pageNum',
          mode: (mode['title'] as String).toLowerCase(),
          filterName: filter['name'] as String,
        );

        final candidate = pipelineResult['enhancedBytes'] as Uint8List?;
        if (candidate != null && candidate.isNotEmpty) {
          effectiveBytes = candidate;
        }

        final pipelineText = (pipelineResult['ocrText'] as String?) ?? '';
        if (pipelineText.trim().isNotEmpty) {
          ocrText = pipelineText.trim();
        }
      } catch (_) {
        effectiveBytes = Uint8List.fromList(bytes);
      }

      if (ocrText.isEmpty) {
        try {
          final ocrResult = await OcrEngineService.processImageBytes(
            effectiveBytes,
            fileName: '${mode['title']}_$pageNum',
          );
          if (ocrResult.isSuccess && ocrResult.text.trim().isNotEmpty) {
            ocrText = ocrResult.text.trim();
          } else {
            ocrText = LocalizationService.tr('scanner_no_text_detected');
          }
        } catch (_) {
          ocrText = LocalizationService.tr('scanner_no_text_detected');
        }
      }

      final newPage = ScannedDocPage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${mode['title']}_#$pageNum',
        docType: mode['title'] as String,
        rotation: 0,
        filter: filter['name'] as String,
        imageBytes: effectiveBytes,
        rawBytes: bytes,
        ocrText: ocrText,
        timestamp: DateTime.now(),
      );

      setState(() {
        _scannedPages.add(newPage);
        _activePageIndex = _scannedPages.length - 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accentEmerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '#$pageNum ($sourceName) • ${LocalizationService.tr('scanner_enhanced_badge')}!',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _captureCurrentDocument() async {
    if (_isProcessing) return;
    await _startSmartDocumentScan();
  }

  Future<void> _startSmartDocumentScan() async {
    if (_isProcessing) return;
    final hasPerm = await AppPermissionService.requestCameraPermission(context);
    if (!hasPerm) return;
    try {
      final List<String>? pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 50,
        scannerSource: ScannerSource.camera,
        androidScannerMode: AndroidScannerMode.full,
      );
      if (pictures != null && pictures.isNotEmpty) {
        setState(() => _isProcessing = true);
        for (final picPath in pictures) {
          final file = File(picPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) {
              await _processCapturedImageBytes(bytes, 'AI Scanner');
            }
          }
        }
        return;
      }
    } catch (e) {
      debugPrint('Native smart document scanner fallback: $e');
      if (e is! CunningDocumentScannerException || e.code != 'permission_denied') {
        _captureWithCameraFallback();
      }
    }
  }

  Future<void> _captureWithCameraFallback() async {
    final hasPerm = await AppPermissionService.requestCameraPermission(context);
    if (!hasPerm) return;
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 98,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (bytes.isNotEmpty) {
          await _processCapturedImageBytes(bytes, 'Camera');
        }
      }
    } catch (e) {
      debugPrint('Camera fallback error: $e');
    }
  }

  void _showSourceSelectionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      LocalizationService.tr('card_camscanner'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildImportOption(
              icon: Icons.document_scanner_rounded,
              title: LocalizationService.tr('scanner_native_auto'),
              subtitle: LocalizationService.tr('scanner_native_auto_desc'),
              onTap: () async {
                Navigator.pop(ctx);
                await _startSmartDocumentScan();
              },
            ),
            const SizedBox(height: 10),
            _buildImportOption(
              icon: Icons.camera_enhance_rounded,
              title: LocalizationService.tr('scanner_manual_cam'),
              subtitle: LocalizationService.tr('scanner_manual_cam_desc'),
              onTap: () async {
                Navigator.pop(ctx);
                await _captureWithCameraFallback();
              },
            ),
            const SizedBox(height: 10),
            _buildImportOption(
              icon: Icons.photo_library_rounded,
              title: LocalizationService.tr('cv_photo_pick'),
              subtitle: LocalizationService.tr('scanner_gallery_desc'),
              onTap: () {
                Navigator.pop(ctx);
                _pickRealImagesFromDeviceGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRealImagesFromDeviceGallery() async {
    final hasPerm = await AppPermissionService.requestGalleryPermission(context);
    if (!hasPerm) return;
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (final img in images) {
          final bytes = await img.readAsBytes();
          await _processCapturedImageBytes(bytes, 'Gallery');
        }
      } else {
        final single = await picker.pickImage(source: ImageSource.gallery);
        if (single != null) {
          final bytes = await single.readAsBytes();
          await _processCapturedImageBytes(bytes, 'Gallery');
        }
      }
    } catch (e) {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isNotEmpty) {
        for (final file in files) {
          final bytes = await file.readAsBytes();
          await _processCapturedImageBytes(bytes, 'Files');
        }
      }
    }
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showPageDetailModal(int index) {
    final page = _scannedPages[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    bool isFiltering = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${index + 1} / ${_scannedPages.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentEmerald,
                          ),
                        ),
                        Text(
                          page.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: page.rotation ~/ 90,
                      child: Container(
                        width: 240,
                        height: 320,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accentEmerald, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: isFiltering
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accentEmerald,
                                ),
                              )
                            : (page.imageBytes != null && page.imageBytes!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      page.imageBytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              page.docType.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 12),
                                    ],
                                  )),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Canlı Filtre Seçici (Magic AI, Siyah-Beyaz, Gri Tonlama, Orijinal HD)
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModalFilterChip(
                          title: LocalizationService.tr('scanner_filter_magic'),
                          filterName: 'Magic AI',
                          icon: Icons.auto_awesome_rounded,
                          isSelected: page.filter == 'Magic AI',
                          page: page,
                          onStartFilter: () => setModalState(() => isFiltering = true),
                          onEndFilter: () => setModalState(() => isFiltering = false),
                        ),
                        const SizedBox(width: 8),
                        _buildModalFilterChip(
                          title: LocalizationService.tr('scanner_filter_bw'),
                          filterName: 'Siyah-Beyaz',
                          icon: Icons.contrast_rounded,
                          isSelected: page.filter == 'Siyah-Beyaz',
                          page: page,
                          onStartFilter: () => setModalState(() => isFiltering = true),
                          onEndFilter: () => setModalState(() => isFiltering = false),
                        ),
                        const SizedBox(width: 8),
                        _buildModalFilterChip(
                          title: LocalizationService.tr('scanner_filter_grayscale'),
                          filterName: 'Gri Tonlama',
                          icon: Icons.filter_b_and_w_rounded,
                          isSelected: page.filter == 'Gri Tonlama',
                          page: page,
                          onStartFilter: () => setModalState(() => isFiltering = true),
                          onEndFilter: () => setModalState(() => isFiltering = false),
                        ),
                        const SizedBox(width: 8),
                        _buildModalFilterChip(
                          title: LocalizationService.tr('scanner_filter_original'),
                          filterName: 'Orijinal HD',
                          icon: Icons.high_quality_rounded,
                          isSelected: page.filter == 'Orijinal HD',
                          page: page,
                          onStartFilter: () => setModalState(() => isFiltering = true),
                          onEndFilter: () => setModalState(() => isFiltering = false),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            page.rotation = (page.rotation + 90) % 360;
                          });
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.rotate_right_rounded, size: 16),
                        label: Text(LocalizationService.tr('scanner_rotate'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: AppColors.accentEmerald.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showOcrResultDialog(page);
                        },
                        icon: const Icon(Icons.text_snippet_rounded, size: 16),
                        label: Text(LocalizationService.tr('scanner_ocr_extract'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                      onPressed: () {
                        setState(() {
                          _scannedPages.removeAt(index);
                          if (_activePageIndex >= _scannedPages.length) {
                            _activePageIndex = _scannedPages.isEmpty ? 0 : _scannedPages.length - 1;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!(AuthService.currentUser?.isPro ?? false)) {
                        VipPaywallSheet.show(context);
                        return;
                      }
                      final pdfBytes = await PdfGeneratorService.generateScannedDocPdf(
                        pages: [
                          {
                            'name': page.name,
                            'docType': page.docType,
                            'imageBytes': page.imageBytes,
                            'ocrText': page.ocrText,
                            'rotation': page.rotation,
                          }
                        ],
                        docTitle: page.name,
                      );
                      await Printing.sharePdf(
                        bytes: pdfBytes,
                        filename: '${page.name}.pdf',
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: Text(LocalizationService.tr('docs_action_share'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalFilterChip({
    required String title,
    required String filterName,
    required IconData icon,
    required bool isSelected,
    required ScannedDocPage page,
    required VoidCallback onStartFilter,
    required VoidCallback onEndFilter,
  }) {
    return InkWell(
      onTap: () async {
        if (page.filter == filterName) return;
        final raw = page.rawBytes ?? page.imageBytes;
        if (raw == null || raw.isEmpty) return;

        onStartFilter();
        try {
          final newBytes = await RealDocumentPipelineService.enhanceDocument(
            imageBytes: raw,
            filterName: filterName,
          );
          setState(() {
            page.imageBytes = newBytes;
            page.filter = filterName;
          });
        } catch (_) {}
        onEndFilter();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOcrResultDialog(ScannedDocPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2438) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.accentEmerald, size: 20),
            Expanded(
              child: Text(
                LocalizationService.tr('card_ocr_text'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              page.ocrText,
              style: TextStyle(fontSize: 12, height: 1.5, color: textColor),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (!(AuthService.currentUser?.isPro ?? false)) {
                Navigator.pop(ctx);
                VipPaywallSheet.show(context);
                return;
              }
              Clipboard.setData(ClipboardData(text: page.ocrText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📋 ${LocalizationService.tr('copied')}'),
                  backgroundColor: AppColors.accentEmerald,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(LocalizationService.tr('copy'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(LocalizationService.tr('ok'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllPagesToPdf() async {
    if (_scannedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('home_recent_empty')),
          backgroundColor: AppColors.accentRose,
        ),
      );
      return;
    }

    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    final docTitle = 'CamScanner_HD_${_scannedPages.length}';
    final pdfBytes = await PdfGeneratorService.generateScannedDocPdf(
      pages: _scannedPages.map((p) => {
        'name': p.name,
        'docType': p.docType,
        'imageBytes': p.imageBytes,
        'ocrText': p.ocrText,
        'rotation': p.rotation,
      }).toList(),
      docTitle: docTitle,
    );

    await CvStorageService.saveDocument(
      DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '$docTitle.pdf',
        type: DocumentType.scannedDocument,
        createdAt: DateTime.now(),
        pageCount: _scannedPages.length,
        fileSize: '${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
      ),
      fileBytes: pdfBytes,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$docTitle.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
        final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final docModes = _getDocModes();
        final activeDocMode = docModes[_selectedDocModeIndex.clamp(0, docModes.length - 1)];

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop() || widget.onReturnHome != null) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B2032) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textColor),
                          ),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else if (widget.onReturnHome != null) {
                              widget.onReturnHome!();
                            }
                          },
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: AppColors.emeraldGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    LocalizationService.tr('scanner_title'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentEmerald.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'OCR 600 DPI',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.accentEmerald),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_scannedPages.length} ${LocalizationService.tr('scanner_mode_doc')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),

                Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docModes.length,
                    itemBuilder: (context, index) {
                      final mode = docModes[index];
                      final isSelected = _selectedDocModeIndex == index;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDocModeIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.emeraldGradient : null,
                            color: isSelected ? null : cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : borderColor,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.accentEmerald.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mode['icon'] as IconData,
                                size: 13,
                                color: isSelected ? Colors.white : AppColors.accentEmerald,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                mode['title'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 4),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.accentEmerald.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF131824),
                                      Color(0xFF0A0D14),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              if (_isGridOn)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GridPainter(),
                                  ),
                                ),

                              // Merkez Cam Scanner Kartı
                              Center(
                                child: _buildDocumentViewfinderCard(activeDocMode, isDark),
                              ),

                              // Yukarı Aşağı Gidip Gelen Lazer Animasyonu
                              AnimatedBuilder(
                                animation: _laserAnimation,
                                builder: (context, child) {
                                  final travelHeight = (constraints.maxHeight - 40).clamp(50.0, 600.0);
                                  final laserTop = 15 + travelHeight * _laserAnimation.value;

                                  return Positioned(
                                    top: laserTop,
                                    left: 14,
                                    right: 14,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 3,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(2),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                AppColors.accentEmerald,
                                                Colors.white,
                                                AppColors.accentEmerald,
                                                Colors.transparent,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accentEmerald.withValues(alpha: 0.95),
                                                blurRadius: 14,
                                                spreadRadius: 3,
                                              ),
                                              BoxShadow(
                                                color: Colors.white.withValues(alpha: 0.7),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 16,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                AppColors.accentEmerald.withValues(alpha: 0.25),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // Üst Araç Çubuğu
                              Positioned(
                                top: 10,
                                left: 12,
                                right: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.5)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.accentEmerald),
                                          SizedBox(width: 5),
                                          Text(
                                            'AI HD',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.6)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: AppColors.accentEmerald,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            activeDocMode['title'] as String,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildCameraToolIcon(
                                      icon: Icons.grid_3x3_rounded,
                                      isActive: _isGridOn,
                                      onTap: () => setState(() => _isGridOn = !_isGridOn),
                                    ),
                                  ],
                                ),
                              ),

                              // Köşe Kılavuzları
                              _buildCornerGuide(Alignment.topLeft),
                              _buildCornerGuide(Alignment.topRight),
                              _buildCornerGuide(Alignment.bottomLeft),
                              _buildCornerGuide(Alignment.bottomRight),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                if (_scannedPages.isNotEmpty)
                  Container(
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141826) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${LocalizationService.tr('docs_filter_scans')} (${_scannedPages.length}):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _scannedPages.length,
                            itemBuilder: (context, idx) {
                              final isSelected = _activePageIndex == idx;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _activePageIndex = idx);
                                  _showPageDetailModal(idx);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentEmerald.withValues(alpha: 0.2)
                                        : (isDark ? const Color(0xFF1E2438) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.accentEmerald : borderColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description_rounded, size: 12, color: AppColors.accentEmerald),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${idx + 1}',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: textColor),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.touch_app_rounded, size: 10, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 4),

                Container(
                  height: 76,
                  margin: const EdgeInsets.only(bottom: 96),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Gallery button
                      SizedBox(
                        width: 60,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _showSourceSelectionSheet,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_rounded, color: textColor, size: 18),
                                  const SizedBox(height: 2),
                                  Text(
                                    LocalizationService.tr('gallery'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Center Camera Shutter button
                      GestureDetector(
                        onTap: _captureCurrentDocument,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppColors.emeraldGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentEmerald.withValues(alpha: 0.5),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 3.5),
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),

                      // Right Export PDF button
                      SizedBox(
                        width: 110,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _exportAllPagesToPdf,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: AppColors.blueGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Text(
                                      '${_scannedPages.length}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      LocalizationService.tr('scanner_export_pdf'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraToolIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentEmerald : Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildDocumentViewfinderCard(Map<String, dynamic> docMode, bool isDark) {
    final width = MediaQuery.of(context).size.width * 0.65;
    final height = width * (docMode['ratio'] as double);

    if (_scannedPages.isNotEmpty && _activePageIndex < _scannedPages.length) {
      final activePage = _scannedPages[_activePageIndex];
      return GestureDetector(
        onTap: () => _showPageDetailModal(_activePageIndex),
        child: Container(
          width: width,
          height: height.clamp(130.0, 270.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.accentEmerald.withValues(alpha: 0.9),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (activePage.imageBytes != null && activePage.imageBytes!.isNotEmpty)
                  RotatedBox(
                    quarterTurns: activePage.rotation ~/ 90,
                    child: Image.memory(
                      activePage.imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    color: const Color(0xFF0F172A),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activePage.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        const Divider(color: Colors.grey),
                        Expanded(
                          child: Text(
                            activePage.ocrText,
                            style: const TextStyle(color: Colors.white70, fontSize: 9),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                  ),

                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentEmerald),
                    ),
                    child: Text(
                      '#${_activePageIndex + 1}',
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppColors.accentEmerald),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _captureCurrentDocument,
      child: Container(
        width: width,
        height: height.clamp(190.0, 310.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF141A29),
              Color(0xFF090D17),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.accentEmerald.withValues(alpha: 0.65),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentEmerald.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentEmerald.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentEmerald.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentEmerald.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.document_scanner_rounded, color: AppColors.accentEmerald, size: 30),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'CAM SCANNER',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: AppColors.accentEmerald,
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              LocalizationService.tr('scanner_hub_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
              decoration: BoxDecoration(
                color: AppColors.accentEmerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppColors.accentEmerald, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    LocalizationService.tr('scanner_tap_to_scan'),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.accentEmerald),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerGuide(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: AppColors.accentEmerald, width: 3)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: AppColors.accentEmerald, width: 3)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: AppColors.accentEmerald, width: 3)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: AppColors.accentEmerald, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    final dx = size.width / 3;
    final dy = size.height / 3;

    canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    canvas.drawLine(Offset(dx * 2, 0), Offset(dx * 2, size.height), paint);
    canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    canvas.drawLine(Offset(0, dy * 2), Offset(size.width, dy * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
