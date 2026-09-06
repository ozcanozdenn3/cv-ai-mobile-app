import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/theme_constants.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/localization_service.dart';
import 'document_viewer_screen.dart';
import 'vip_paywall_sheet.dart';

class DocumentsLibraryScreen extends StatefulWidget {
  final VoidCallback? onReturnHome;

  const DocumentsLibraryScreen({
    super.key,
    this.onReturnHome,
  });

  @override
  State<DocumentsLibraryScreen> createState() => _DocumentsLibraryScreenState();
}

class _DocumentsLibraryScreenState extends State<DocumentsLibraryScreen> {
  int _selectedFilterIndex = 0; // 0: Tümü, 1: CV, 2: Taranan, 3: Dönüştürülen
  List<DocumentModel> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedDocuments();
  }

  Future<void> _loadSavedDocuments() async {
    final docs = await CvStorageService.loadDocuments();
    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  List<DocumentModel> get _filteredDocuments {
    return _documents.where((doc) {
      switch (_selectedFilterIndex) {
        case 1:
          return doc.type == DocumentType.cv;
        case 2:
          return doc.type == DocumentType.scannedDocument;
        case 3:
          return doc.type == DocumentType.imageToPdf ||
              doc.type == DocumentType.invoice ||
              doc.type == DocumentType.signedContract;
        default:
          return true;
      }
    }).toList();
  }

  Future<Uint8List?> _getRealDocumentBytes(DocumentModel doc) async {
    return await CvStorageService.getDocumentBytes(doc);
  }

  void _showDocumentActionSheet(DocumentModel doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getDocumentColor(doc.type).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getDocumentIcon(doc.type),
                      color: _getDocumentColor(doc.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doc.typeLabel} • ${doc.pageCount} p • ${doc.fileSize}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 6),

              // Preview & View Document
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.visibility_rounded, color: AppColors.primaryLight, size: 20),
                ),
                title: Text(LocalizationService.tr('docs_action_preview'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentViewerScreen(document: doc),
                    ),
                  );
                },
              ),

              // Share / View PDF
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                title: Text(LocalizationService.tr('docs_action_share'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!(AuthService.currentUser?.isPro ?? false)) {
                    VipPaywallSheet.show(context);
                    return;
                  }

                  final isPdf = doc.title.toLowerCase().endsWith('.pdf');
                  final realBytes = await _getRealDocumentBytes(doc);

                  if (isPdf) {
                    final pdfBytes = realBytes ??
                        await PdfGeneratorService.generateConvertedDocumentPdf(
                          fileName: doc.title.replaceAll('.pdf', ''),
                          fileType: 'PDF',
                          originalFormat: 'Document',
                        );
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: doc.title,
                    );
                  } else {
                    if (doc.filePath != null && await File(doc.filePath!).exists()) {
                      // ignore: deprecated_member_use
                      await Share.shareXFiles(
                        [XFile(doc.filePath!, name: doc.title)],
                        text: doc.title,
                      );
                    } else if (realBytes != null) {
                      final tempDir = await getTemporaryDirectory();
                      final tempFile = File('${tempDir.path}/${doc.title}');
                      await tempFile.writeAsBytes(realBytes);
                      // ignore: deprecated_member_use
                      await Share.shareXFiles(
                        [XFile(tempFile.path, name: doc.title)],
                        text: doc.title,
                      );
                    }
                  }
                },
              ),

              // Print Document
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.print_rounded, color: AppColors.accentEmerald, size: 20),
                ),
                title: Text(LocalizationService.tr('docs_action_print'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!(AuthService.currentUser?.isPro ?? false)) {
                    VipPaywallSheet.show(context);
                    return;
                  }

                  final isPdf = doc.title.toLowerCase().endsWith('.pdf');
                  final realBytes = await _getRealDocumentBytes(doc);

                  if (isPdf) {
                    final pdfBytes = realBytes ??
                        await PdfGeneratorService.generateConvertedDocumentPdf(
                          fileName: doc.title.replaceAll('.pdf', ''),
                          fileType: 'PDF',
                          originalFormat: 'Document',
                        );
                    await Printing.layoutPdf(
                      onLayout: (_) => pdfBytes,
                      name: doc.title,
                    );
                  } else {
                    if (doc.filePath != null && await File(doc.filePath!).exists()) {
                      // ignore: deprecated_member_use
                      await Share.shareXFiles(
                        [XFile(doc.filePath!, name: doc.title)],
                        text: doc.title,
                      );
                    }
                  }
                },
              ),

              // Delete Document
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 20),
                ),
                title: Text(LocalizationService.tr('docs_action_delete'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentRose, fontSize: 13)),
                onTap: () async {
                  await CvStorageService.deleteDocument(doc.id);
                  setState(() {
                    _documents.removeWhere((d) => d.id == doc.id);
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🗑️ ${doc.title} ${LocalizationService.tr('delete')}'),
                        backgroundColor: AppColors.accentRose,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        final dateFormat = DateFormat('dd.MM.yyyy • HH:mm');
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

        final filteredDocs = _filteredDocuments;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: (Navigator.of(context).canPop() || widget.onReturnHome != null)
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
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
                  )
                : null,
            title: Text(
              LocalizationService.tr('docs_title'),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.accentAmber, size: 26),
                onPressed: () => VipPaywallSheet.show(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Chips Row
              Container(
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('📂 ${LocalizationService.tr('docs_filter_all')} (${_documents.length})', 0, isDark),
                    _buildFilterChip('👤 ${LocalizationService.tr('docs_filter_cv')}', 1, isDark),
                    _buildFilterChip('📷 ${LocalizationService.tr('docs_filter_scans')}', 2, isDark),
                    _buildFilterChip('⚡ ${LocalizationService.tr('docs_filter_converters')}', 3, isDark),
                  ],
                ),
              ),

              // Document List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadSavedDocuments,
                  color: AppColors.primary,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : filteredDocs.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E2438) : const Color(0xFFEFF6FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.folder_open_rounded,
                                          size: 48,
                                          color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        LocalizationService.tr('docs_empty_title'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 40),
                                        child: Text(
                                          LocalizationService.tr('docs_empty_desc'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: subColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentViewerScreen(document: doc),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getDocumentColor(doc.type).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getDocumentIcon(doc.type),
                                      color: _getDocumentColor(doc.type),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              doc.typeLabel,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: _getDocumentColor(doc.type),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '• ${doc.pageCount} p • ${doc.fileSize}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateFormat.format(doc.createdAt),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.more_vert_rounded,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        size: 18),
                                    onPressed: () => _showDocumentActionSheet(doc),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : borderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }

  Color _getDocumentColor(DocumentType type) {
    switch (type) {
      case DocumentType.cv:
        return AppColors.primary;
      case DocumentType.scannedDocument:
        return AppColors.accentEmerald;
      case DocumentType.imageToPdf:
        return const Color(0xFF2B579A); // Word Blue
      case DocumentType.signedContract:
        return AppColors.accentAmber;
      case DocumentType.invoice:
        return const Color(0xFF217346); // Excel Green
    }
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.cv:
        return Icons.badge_rounded;
      case DocumentType.scannedDocument:
        return Icons.document_scanner_rounded;
      case DocumentType.imageToPdf:
        return Icons.article_rounded;
      case DocumentType.signedContract:
        return Icons.draw_rounded;
      case DocumentType.invoice:
        return Icons.table_chart_rounded;
    }
  }
}
