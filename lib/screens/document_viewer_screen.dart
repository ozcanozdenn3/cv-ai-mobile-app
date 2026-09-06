import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/theme_constants.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/localization_service.dart';
import '../services/pdf_generator_service.dart';
import 'vip_paywall_sheet.dart';

/// Arşivdeki orijinal belgeleri (CV, CamScanner, Dönüştürülen PDF/TXT)
/// sahte şablonlar olmadan doğrudan gerçek içeriğiyle görüntüleyen ekran.
class DocumentViewerScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Uint8List? _documentBytes;
  String? _textContent;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = widget.document;
      Uint8List? bytes = await CvStorageService.getDocumentBytes(doc);

      // Eğer belge bir CV ise ve doğrudan byte bulunamadıysa, kaydedilmiş gerçek aktif CV'den üret
      if ((bytes == null || bytes.isEmpty) && doc.type == DocumentType.cv) {
        final activeCv = await CvStorageService.loadActiveCv();
        if (activeCv.fullName.isNotEmpty || activeCv.experiences.isNotEmpty) {
          bytes = await PdfGeneratorService.generateCvPdf(
            activeCv,
            locale: LocalizationService.currentLocale,
          );
        }
      }

      // Eğer TXT dosyası ise metin olarak oku
      if (bytes != null && doc.title.toLowerCase().endsWith('.txt')) {
        try {
          _textContent = utf8.decode(bytes);
        } catch (_) {
          _textContent = String.fromCharCodes(bytes);
        }
      }

      if (mounted) {
        setState(() {
          _documentBytes = bytes;
          _isLoading = false;
          if (bytes == null || bytes.isEmpty) {
            _errorMessage = LocalizationService.tr('docs_empty_bytes_error');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _shareDocument() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    final doc = widget.document;
    if (_documentBytes != null && _documentBytes!.isNotEmpty) {
      if (doc.title.toLowerCase().endsWith('.pdf')) {
        await Printing.sharePdf(
          bytes: _documentBytes!,
          filename: doc.title,
        );
      } else {
        if (doc.filePath != null && await File(doc.filePath!).exists()) {
          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [XFile(doc.filePath!, name: doc.title)],
            text: doc.title,
          );
        } else {
          await Printing.sharePdf(
            bytes: _documentBytes!,
            filename: doc.title,
          );
        }
      }
    }
  }

  Future<void> _printDocument() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    final doc = widget.document;
    if (_documentBytes != null && _documentBytes!.isNotEmpty) {
      await Printing.layoutPdf(
        onLayout: (_) => _documentBytes!,
        name: doc.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
        final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final textColor =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subColor =
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final borderColor =
            isDark ? AppColors.darkBorder : AppColors.lightBorder;

        final isPdf = widget.document.title.toLowerCase().endsWith('.pdf');
        final isTxt = widget.document.title.toLowerCase().endsWith('.txt');

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2032)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: textColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                Text(
                  '${widget.document.typeLabel} • ${widget.document.fileSize}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_rounded,
                    color: AppColors.primaryLight, size: 22),
                tooltip: LocalizationService.tr('docs_action_print'),
                onPressed: _documentBytes != null ? _printDocument : null,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded,
                    color: AppColors.primaryLight, size: 22),
                tooltip: LocalizationService.tr('docs_action_share'),
                onPressed: _documentBytes != null ? _shareDocument : null,
              ),
              IconButton(
                icon: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.accentAmber, size: 24),
                onPressed: () => VipPaywallSheet.show(context),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.accentRose.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.accentRose,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadDocument,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(LocalizationService.tr('retry')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : isTxt
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: SelectableText(
                              _textContent ?? '',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.6,
                                color: textColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        )
                      : isPdf && _documentBytes != null
                          ? PdfPreview.builder(
                              build: (_) => _documentBytes!,
                              allowPrinting: false,
                              allowSharing: false,
                              canChangeOrientation: false,
                              canChangePageFormat: false,
                              canDebug: false,
                              dynamicLayout: false,
                              useActions: false,
                              pagesBuilder: (context, pages) {
                                return InteractiveViewer(
                                  minScale: 0.8,
                                  maxScale: 4.5,
                                  panAxis: PanAxis.free,
                                  boundaryMargin: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 80),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 20),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (final page in pages)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 20),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: isDark
                                                                ? 0.45
                                                                : 0.15),
                                                    blurRadius: 18,
                                                    offset:
                                                        const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Image(
                                                  image: page.image,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file_rounded,
                                      size: 56,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.document.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${widget.document.typeLabel} • ${widget.document.fileSize}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subColor,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _shareDocument,
                                      icon: const Icon(Icons.share_rounded,
                                          size: 18),
                                      label: Text(LocalizationService.tr(
                                          'docs_action_share')),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _documentBytes != null ? _printDocument : null,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      LocalizationService.tr('docs_action_print'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _documentBytes != null ? _shareDocument : null,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      LocalizationService.tr('docs_action_share'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
