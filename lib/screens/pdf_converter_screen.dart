import 'dart:convert';
import '../widgets/scrollable_sheet_body.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/theme_constants.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/docx_converter_service.dart';
import '../services/document_parser_service.dart';
import '../services/ocr_engine_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/office_converter_service.dart';
import '../services/localization_service.dart';
import '../services/real_document_pipeline_service.dart';
import '../services/app_permission_service.dart';
import 'vip_paywall_sheet.dart';

Widget _compactButtonLabel(
  String text, {
  TextStyle? style,
}) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    ),
  );
}

class PdfConverterScreen extends StatefulWidget {
  final VoidCallback? onReturnHome;

  const PdfConverterScreen({
    super.key,
    this.onReturnHome,
  });

  @override
  State<PdfConverterScreen> createState() => _PdfConverterScreenState();
}

class _PdfConverterScreenState extends State<PdfConverterScreen> {
  int _activeDirection = 0; // 0: To PDF, 1: Office to Office

  void _openImageToPdfConverter() => ImageToPdfSheet.show(context);
  void _openDocToPdfConverter() => DocToPdfSheet.show(context);
  void _openPptxToPdfConverter() => PptxToPdfSheet.show(context);
  void _openPdfToDocxConverter() => PdfToDocxSheet.show(context);
  void _openOcrToTxtConverter() => OcrToTxtSheet.show(context);

  void _openWordToExcelConverter() => WordToExcelSheet.show(context);
  void _openExcelToDocxConverter() => ExcelToDocxSheet.show(context);
  void _openPptxToDocxConverter() => PptxToDocxSheet.show(context);
  void _openDocxToPptxConverter() => DocxToPptxSheet.show(context);
  void _openPptxToExcelConverter() => PptxToExcelSheet.show(context);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading:
                (Navigator.of(context).canPop() || widget.onReturnHome != null)
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1B2032)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 15, color: textColor),
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
              LocalizationService.tr('converter_title'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: textColor,
              ),
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
              // Direction Selector (To PDF vs From PDF vs Office)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161A28)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeDirection = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 9, horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: _activeDirection == 0
                                ? AppColors.blueGradient
                                : null,
                            color: _activeDirection == 0
                                ? null
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeDirection == 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 15,
                                color: _activeDirection == 0
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey
                                        : const Color(0xFF475569)),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    LocalizationService.tr(
                                        'converter_direction_to_pdf'),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: _activeDirection == 0
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.grey
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeDirection = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 9, horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: _activeDirection == 1
                                ? const LinearGradient(colors: [
                                    Color(0xFFD97706),
                                    Color(0xFFB45309)
                                  ])
                                : null,
                            color: _activeDirection == 1
                                ? null
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeDirection == 1
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFD97706)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.workspaces_rounded,
                                size: 15,
                                color: _activeDirection == 1
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey
                                        : const Color(0xFF475569)),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    LocalizationService.tr(
                                        'converter_direction_office'),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: _activeDirection == 1
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.grey
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Converter Tools List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
                  children: [
                    if (_activeDirection == 0) ...[
                      // 1. Word / Metin to PDF (DOCX/TXT)
                      _buildConverterCard(
                        context,
                        title: LocalizationService.tr('card_word_to_pdf'),
                        badge: 'DOCX ➔ PDF ENGINE',
                        description:
                            LocalizationService.tr('card_word_to_pdf_desc'),
                        gradient: AppColors.wordDocGradient,
                        icon: Icons.article_rounded,
                        formatFrom: 'DOCX',
                        formatTo: 'PDF',
                        isPro: false,
                        onTap: _openDocToPdfConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 2. PowerPoint to PDF (PPTX to PDF)
                      _buildConverterCard(
                        context,
                        title: LocalizationService.tr('card_pptx_to_pdf'),
                        badge: 'PPTX PRESENTATION ENGINE',
                        description:
                            LocalizationService.tr('card_pptx_to_pdf_desc'),
                        gradient: AppColors.pptGradient,
                        icon: Icons.slideshow_rounded,
                        formatFrom: 'PPTX',
                        formatTo: 'PDF',
                        isPro: false,
                        onTap: _openPptxToPdfConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 3. Görsel to PDF (JPG/PNG)
                      _buildConverterCard(
                        context,
                        title: LocalizationService.tr('card_img_to_pdf'),
                        badge: 'HD GALLERY ENGINE',
                        description:
                            LocalizationService.tr('card_img_to_pdf_desc'),
                        gradient: AppColors.blueGradient,
                        icon: Icons.photo_library_rounded,
                        formatFrom: 'IMG',
                        formatTo: 'PDF',
                        isPro: false,
                        onTap: _openImageToPdfConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 4. PDF to Word (PDF ➔ DOCX) - Reverse conversion
                      _buildConverterCard(
                        context,
                        title: LocalizationService.tr('card_pdf_to_word'),
                        badge: 'MICROSOFT WORD DOCX',
                        description:
                            LocalizationService.tr('card_pdf_to_word_desc'),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        icon: Icons.description_rounded,
                        formatFrom: 'PDF',
                        formatTo: 'DOCX',
                        isPro: false,
                        onTap: _openPdfToDocxConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 5. Görselden Metin Çıkarma (OCR)
                      _buildConverterCard(
                        context,
                        title: LocalizationService.tr('card_ocr_to_txt'),
                        badge: 'AI TEXT RECOGNITION',
                        description:
                            LocalizationService.tr('card_ocr_to_txt_desc'),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        icon: Icons.document_scanner_rounded,
                        formatFrom: 'IMG',
                        formatTo: 'TXT',
                        isPro: false,
                        onTap: _openOcrToTxtConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                    ] else if (_activeDirection == 1) ...[
                      // OFFICE ➔ OFFICE CROSS CONVERTERS
                      // 1. Word to Excel (DOCX ➔ XLSX)
                      _buildConverterCard(
                        context,
                        title:
                            LocalizationService.tr('converter_word_to_excel'),
                        badge: 'DOCX ➔ XLSX ENGINE',
                        description: LocalizationService.tr(
                            'converter_word_to_excel_desc'),
                        gradient: AppColors.excelGradient,
                        icon: Icons.table_chart_rounded,
                        formatFrom: 'DOCX',
                        formatTo: 'XLSX',
                        isPro: false,
                        onTap: _openWordToExcelConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 2. Excel to Word (XLSX ➔ DOCX)
                      _buildConverterCard(
                        context,
                        title:
                            LocalizationService.tr('converter_excel_to_word'),
                        badge: 'XLSX ➔ DOCX TABLE',
                        description: LocalizationService.tr(
                            'converter_excel_to_word_desc'),
                        gradient: AppColors.wordDocGradient,
                        icon: Icons.article_rounded,
                        formatFrom: 'XLSX',
                        formatTo: 'DOCX',
                        isPro: false,
                        onTap: _openExcelToDocxConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 3. PowerPoint to Word (PPTX ➔ DOCX)
                      _buildConverterCard(
                        context,
                        title: LocalizationService.tr('converter_pptx_to_word'),
                        badge: 'SLIDES ➔ DOCX OUTLINE',
                        description: LocalizationService.tr(
                            'converter_pptx_to_word_desc'),
                        gradient: AppColors.pptGradient,
                        icon: Icons.slideshow_rounded,
                        formatFrom: 'PPTX',
                        formatTo: 'DOCX',
                        isPro: false,
                        onTap: _openPptxToDocxConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 4. Word to PowerPoint (DOCX ➔ PPTX)
                      _buildConverterCard(
                        context,
                        title: LocalizationService.tr('converter_word_to_pptx'),
                        badge: 'DOCX ➔ PPTX SLIDES',
                        description: LocalizationService.tr(
                            'converter_word_to_pptx_desc'),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFB45309)],
                        ),
                        icon: Icons.present_to_all_rounded,
                        formatFrom: 'DOCX',
                        formatTo: 'PPTX',
                        isPro: false,
                        onTap: _openDocxToPptxConverter,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      // 5. PowerPoint to Excel (PPTX ➔ XLSX)
                      _buildConverterCard(
                        context,
                        title:
                            LocalizationService.tr('converter_pptx_to_excel'),
                        badge: 'PPTX ➔ XLSX MATRIX',
                        description: LocalizationService.tr(
                            'converter_pptx_to_excel_desc'),
                        gradient: AppColors.excelGradient,
                        icon: Icons.grid_on_rounded,
                        formatFrom: 'PPTX',
                        formatTo: 'XLSX',
                        isPro: false,
                        onTap: _openPptxToExcelConverter,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConverterCard(
    BuildContext context, {
    required String title,
    required String badge,
    required String description,
    required LinearGradient gradient,
    required IconData icon,
    required String formatFrom,
    required String formatTo,
    required bool isPro,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: gradient.colors.first.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: gradient.colors.first,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, height: 1.4, color: subColor),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. REAL IMAGE TO PDF MODAL SHEET
class ImageToPdfSheet extends StatefulWidget {
  const ImageToPdfSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ImageToPdfSheet(),
    );
  }

  @override
  State<ImageToPdfSheet> createState() => _ImageToPdfSheetState();
}

class _ImageToPdfSheetState extends State<ImageToPdfSheet> {
  final List<Uint8List> _selectedImages = [];
  bool _isGenerating = false;

  Future<void> _pickImagesFromGallery() async {
    final hasPerm =
        await AppPermissionService.requestGalleryPermission(context);
    if (!hasPerm) return;
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (final img in images) {
          final bytes = await img.readAsBytes();
          setState(() {
            _selectedImages.add(bytes);
          });
        }
      }
    } catch (e) {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isNotEmpty) {
        for (final file in files) {
          final bytes = await file.readAsBytes();
          setState(() {
            _selectedImages.add(bytes);
          });
        }
      }
    }
  }

  Future<void> _convertToPdfAndShare() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('error_pick_image')),
          backgroundColor: AppColors.accentRose,
        ),
      );
      return;
    }

    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    setState(() => _isGenerating = true);
    final pdfBytes = await PdfGeneratorService.generateImageToPdf(
      imageBytesList: _selectedImages,
      title: 'Gorsellerden_Donusturulen_Belge',
    );
    setState(() => _isGenerating = false);

    final fileName = 'Gorsel_Donusturucu_${_selectedImages.length}_Sayfa.pdf';
    await CvStorageService.saveDocument(
      DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName,
        type: DocumentType.imageToPdf,
        createdAt: DateTime.now(),
        pageCount: _selectedImages.length,
        fileSize: '${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
      ),
      fileBytes: pdfBytes,
    );

    if (mounted) {
      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(22),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.blueGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocalizationService.tr('converter_img_to_pdf_sheet_title'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            LocalizationService.tr('converter_img_to_pdf_sheet_sub'),
            style: const TextStyle(
                fontSize: 11.5, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickImagesFromGallery,
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _selectedImages.isEmpty
                    ? LocalizationService.tr('converter_pick_gallery_btn')
                    : LocalizationService.tr('converter_pick_gallery_more'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _selectedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                            LocalizationService.tr('converter_no_img_selected'),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, idx) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary, width: 1.5),
                              image: DecorationImage(
                                image: MemoryImage(_selectedImages[idx]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${LocalizationService.tr('page')} ${idx + 1}',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(idx);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentRose,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _convertToPdfAndShare,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isGenerating
                      ? LocalizationService.tr('converter_generating_pdf')
                      : '${LocalizationService.tr('converter_btn_convert_pdf')} (${_selectedImages.length} ${LocalizationService.tr('page')})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. REAL DOC / TEXT TO PDF MODAL SHEET (With Real DOCX & Text Parsing)
class DocToPdfSheet extends StatefulWidget {
  const DocToPdfSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DocToPdfSheet(),
    );
  }

  @override
  State<DocToPdfSheet> createState() => _DocToPdfSheetState();
}

class _DocToPdfSheetState extends State<DocToPdfSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  Uint8List? _selectedDocBytes;
  String? _selectedDocFileName;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: LocalizationService.tr('default_doc_title'));
    _contentController = TextEditingController(
        text: LocalizationService.tr('default_doc_content'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _isGenerating = false;
  bool _isParsing = false;

  Future<void> _pickDocumentFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc', 'txt', 'md', 'json', 'rtf'],
      );

      if (file != null) {
        setState(() => _isParsing = true);
        final bytes = await file.readAsBytes();
        final ext = file.extension?.toLowerCase() ?? '';
        _selectedDocBytes = bytes;
        _selectedDocFileName = file.name;

        String parsedText;
        if (ext == 'docx' || ext == 'doc') {
          parsedText = await DocumentParserService.parseDocx(bytes);
        } else {
          try {
            parsedText = utf8.decode(bytes, allowMalformed: true);
          } catch (_) {
            parsedText = String.fromCharCodes(bytes);
          }
        }

        setState(() {
          _isParsing = false;
          _titleController.text =
              file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          _contentController.text = parsedText;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '📄 ${file.name} ${LocalizationService.tr('msg_file_imported')}'),
              backgroundColor: AppColors.accentEmerald,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isParsing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${LocalizationService.tr('error_read_file')}: $e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    setState(() => _isGenerating = true);

    Uint8List pdfBytes;
    try {
      final sourceBytes = _selectedDocBytes ??
          Uint8List.fromList(utf8.encode(_contentController.text.trim()));
      final sourceName =
          _selectedDocFileName ?? '${_titleController.text.trim()}.docx';
      final converted = await RealDocumentPipelineService.convertWordToPdfBytes(
        sourceBytes,
        fileName: sourceName,
      );
      pdfBytes = converted;
    } catch (_) {
      pdfBytes = await PdfGeneratorService.generateTextDocumentPdf(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );
    }

    setState(() => _isGenerating = false);

    final fileName = '${_titleController.text.trim().replaceAll(' ', '_')}.pdf';
    await CvStorageService.saveDocument(
      DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName,
        type: DocumentType.signedContract,
        createdAt: DateTime.now(),
        pageCount: 1,
        fileSize: '${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
      ),
      fileBytes: pdfBytes,
    );

    if (mounted) {
      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(22),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.wordDocGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.article_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocalizationService.tr('converter_word_title'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _isParsing ? null : _pickDocumentFile,
            icon: _isParsing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_open_rounded, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _isParsing
                    ? LocalizationService.tr('converter_parsing_doc')
                    : LocalizationService.tr('converter_pick_real_doc'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
            decoration: InputDecoration(
              labelText: LocalizationService.tr('converter_doc_title'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: textColor),
              decoration: InputDecoration(
                labelText: LocalizationService.tr('converter_doc_content'),
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePdf,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isGenerating
                      ? LocalizationService.tr('converter_generating_pdf')
                      : LocalizationService.tr('converter_btn_create_pdf'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. REAL EXCEL & TABLE TO PDF MODAL SHEET (With Real XLSX & CSV Parsing)
class ExcelToPdfSheet extends StatefulWidget {
  const ExcelToPdfSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ExcelToPdfSheet(),
    );
  }

  @override
  State<ExcelToPdfSheet> createState() => _ExcelToPdfSheetState();
}

class _ExcelToPdfSheetState extends State<ExcelToPdfSheet> {
  late final TextEditingController _titleController;
  late final List<List<String>> _tableData;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: LocalizationService.tr('default_excel_title'));
    _tableData = [
      [
        LocalizationService.tr('table_header_order'),
        LocalizationService.tr('table_header_item'),
        LocalizationService.tr('table_header_period'),
        LocalizationService.tr('table_header_price'),
        LocalizationService.tr('table_header_total'),
      ],
      ['1', 'Core Mobile System & AI Engine', 'Q1 2026', '€4,500', '€4,500'],
      [
        '2',
        'Cloud Infrastructure & High Availability',
        '12 Mos',
        '€350',
        '€4,200'
      ],
      ['3', 'UI/UX Design & Global Design Tokens', 'Fixed', '€2,800', '€2,800'],
      [
        '4',
        'Security Audit & Penetration Testing',
        'Annual',
        '€3,500',
        '€3,500'
      ],
      [
        LocalizationService.tr('table_total_label'),
        '4 ${LocalizationService.tr('table_total_summary')}',
        '',
        '',
        '€15,000'
      ],
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool _isGenerating = false;
  bool _isParsing = false;

  Future<void> _pickCsvOrExcelFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'tsv', 'txt'],
      );

      if (file != null) {
        setState(() => _isParsing = true);
        final bytes = await file.readAsBytes();
        final ext = file.extension?.toLowerCase() ?? '';

        List<List<String>> parsedGrid;
        if (ext == 'xlsx' || ext == 'xls') {
          parsedGrid = await DocumentParserService.parseXlsx(bytes);
        } else {
          final text = utf8.decode(bytes, allowMalformed: true);
          parsedGrid = DocumentParserService.parseCsv(text);
        }

        if (parsedGrid.isNotEmpty) {
          setState(() {
            _isParsing = false;
            _titleController.text =
                file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
            _tableData
              ..clear()
              ..addAll(parsedGrid);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '📊 ${file.name} ${LocalizationService.tr('msg_file_imported')}'),
                backgroundColor: AppColors.accentEmerald,
              ),
            );
          }
        } else {
          setState(() => _isParsing = false);
        }
      }
    } catch (e) {
      setState(() => _isParsing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('error_read_table')}: $e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    setState(() => _isGenerating = true);
    final pdfBytes = await PdfGeneratorService.generateSpreadsheetPdf(
      title: _titleController.text.trim(),
      tableData: _tableData,
    );
    setState(() => _isGenerating = false);

    final fileName = '${_titleController.text.trim().replaceAll(' ', '_')}.pdf';
    await CvStorageService.saveDocument(
      DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName,
        type: DocumentType.invoice,
        createdAt: DateTime.now(),
        pageCount: 1,
        fileSize: '${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
      ),
      fileBytes: pdfBytes,
    );

    if (mounted) {
      Navigator.pop(context);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(22),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.excelGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_chart_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocalizationService.tr('converter_excel_title'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _isParsing ? null : _pickCsvOrExcelFile,
            icon: _isParsing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_present_rounded, size: 18),
            label: _compactButtonLabel(
              _isParsing
                  ? LocalizationService.tr('converter_parsing_doc')
                  : LocalizationService.tr('converter_pick_excel'),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
            decoration: InputDecoration(
              labelText: LocalizationService.tr('converter_doc_title'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF15803D).withValues(alpha: 0.15)),
                    columns:
                        (_tableData.isNotEmpty ? _tableData.first : ['Col 1'])
                            .map((col) => DataColumn(
                                  label: Text(col,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11)),
                                ))
                            .toList(),
                    rows: (_tableData.length > 1
                            ? _tableData.sublist(1)
                            : <List<String>>[])
                        .map(
                          (row) => DataRow(
                            cells: row
                                .map((cell) => DataCell(Text(cell,
                                    style: const TextStyle(fontSize: 11))))
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePdf,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: _compactButtonLabel(
                _isGenerating
                    ? LocalizationService.tr('converter_generating_pdf')
                    : LocalizationService.tr('converter_generate_pdf'),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3.5 REAL POWERPOINT (PPTX) TO PDF MODAL SHEET (With Real OpenXML Slide Parsing)
class PptxToPdfSheet extends StatefulWidget {
  const PptxToPdfSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PptxToPdfSheet(),
    );
  }

  @override
  State<PptxToPdfSheet> createState() => _PptxToPdfSheetState();
}

class _PptxToPdfSheetState extends State<PptxToPdfSheet> {
  late final TextEditingController _titleController;
  late final List<PptxSlide> _slides;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: LocalizationService.tr('default_pptx_title'));
    _slides = [
      PptxSlide(
        index: 1,
        title: LocalizationService.tr('app_title'),
        bulletPoints: [
          LocalizationService.tr('app_subtitle'),
          LocalizationService.tr('home_hero_desc'),
          LocalizationService.tr('home_ats_badge'),
        ],
      ),
      PptxSlide(
        index: 2,
        title: LocalizationService.tr('home_office_converters'),
        bulletPoints: [
          '${LocalizationService.tr('card_word_to_pdf')} & ${LocalizationService.tr('card_excel_to_pdf')}',
          LocalizationService.tr('card_ocr_text_sub'),
          LocalizationService.tr('cv_template_title'),
        ],
      ),
      PptxSlide(
        index: 3,
        title: LocalizationService.tr('profile_privacy'),
        bulletPoints: [
          LocalizationService.tr('profile_privacy_sub'),
          LocalizationService.tr('paywall_feat_5'),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool _isGenerating = false;
  bool _isParsing = false;

  Future<void> _pickPptxFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pptx', 'ppt'],
      );

      if (file != null) {
        setState(() => _isParsing = true);
        final bytes = await file.readAsBytes();
        final parsedSlides = await DocumentParserService.parsePptx(bytes);

        if (parsedSlides.isNotEmpty) {
          setState(() {
            _isParsing = false;
            _titleController.text =
                file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
            _slides
              ..clear()
              ..addAll(parsedSlides);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '🎯 ${file.name} ${LocalizationService.tr('msg_file_imported')}'),
                backgroundColor: AppColors.accentEmerald,
              ),
            );
          }
        } else {
          setState(() => _isParsing = false);
        }
      }
    } catch (e) {
      setState(() => _isParsing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${LocalizationService.tr('error_read_pres')}: $e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  void _addSlide() {
    setState(() {
      _slides.add(
        PptxSlide(
          index: _slides.length + 1,
          title:
              '${LocalizationService.tr('cv_new_slide')} ${_slides.length + 1}',
          bulletPoints: [LocalizationService.tr('cv_new_bullet')],
        ),
      );
    });
  }

  Future<void> _generatePdf() async {
    if (_titleController.text.trim().isEmpty || _slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('error_pick_file')),
          backgroundColor: AppColors.accentAmber,
        ),
      );
      return;
    }

    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final pdfBytes =
          await PdfGeneratorService.generatePresentationPdfFromPptx(
        presentationTitle: _titleController.text.trim(),
        slides: _slides,
      );

      final fileName =
          '${_titleController.text.trim().replaceAll(' ', '_')}.pdf';
      await CvStorageService.saveDocument(
        DocumentModel(
          id: 'pptx_pdf_${DateTime.now().millisecondsSinceEpoch}',
          title: fileName,
          type: DocumentType.imageToPdf,
          createdAt: DateTime.now(),
          pageCount: _slides.length,
          fileSize: '${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
        ),
        fileBytes: pdfBytes,
      );

      setState(() => _isGenerating = false);

      if (!mounted) return;
      Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${LocalizationService.tr('error_convert')}: $e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131726) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF262E48) : const Color(0xFFE2E8F0);
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.pptGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.slideshow_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('converter_pptx_title'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      LocalizationService.tr('converter_pptx_desc'),
                      style: TextStyle(fontSize: 11, color: subColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: subColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),

          // File Picker Button
          OutlinedButton.icon(
            onPressed: _isParsing ? null : _pickPptxFile,
            icon: _isParsing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.folder_open_rounded, size: 18),
            label: _compactButtonLabel(
              _isParsing
                  ? LocalizationService.tr('converter_parsing_doc')
                  : LocalizationService.tr('converter_pick_pptx'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
              side: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          // Presentation Title Input
          TextField(
            controller: _titleController,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w700, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: LocalizationService.tr('converter_doc_title'),
              labelStyle: TextStyle(color: subColor, fontSize: 12),
              prefixIcon: const Icon(Icons.title_rounded,
                  color: Color(0xFFEA580C), size: 18),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1B2032) : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFEA580C), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Slides Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${LocalizationService.tr('slides')} (${_slides.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: textColor),
                ),
              ),
              IconButton(
                onPressed: _addSlide,
                tooltip: LocalizationService.tr('converter_btn_add_slide'),
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFFEA580C),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),

          // Slides List
          Expanded(
            child: ListView.separated(
              itemCount: _slides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final slide = _slides[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B2032)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: textColor),
                            ),
                            if (slide.bulletPoints.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                slide.bulletPoints
                                    .map((b) => '• $b')
                                    .join('\n'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.accentRose, size: 18),
                        onPressed: () {
                          if (_slides.length > 1) {
                            setState(() => _slides.removeAt(idx));
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePdf,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: _compactButtonLabel(
                _isGenerating
                    ? LocalizationService.tr('converter_generating_pdf')
                    : LocalizationService.tr('converter_generate_pptx'),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. REAL OCR: GOOGLE ML KIT ON-DEVICE OCR ENGINE & TXT EXPORT
class OcrToTxtSheet extends StatefulWidget {
  const OcrToTxtSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const OcrToTxtSheet(),
    );
  }

  @override
  State<OcrToTxtSheet> createState() => _OcrToTxtSheetState();
}

class _OcrToTxtSheetState extends State<OcrToTxtSheet> {
  Uint8List? _capturedImageBytes;
  String _sourceFileName = 'Kamera_Cekimi';
  bool _isProcessingOcr = false;
  int _recognizedBlocks = 0;
  int _recognizedLines = 0;

  final TextEditingController _extractedTextController =
      TextEditingController();

  Future<void> _captureWithCamera() async {
    final hasPerm = await AppPermissionService.requestCameraPermission(context);
    if (!hasPerm) return;
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _processImageWithRealOcr(bytes, photo.path,
            'Kamera_Cekimi_${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (e) {
      _pickFromGallery();
    }
  }

  Future<void> _pickFromGallery() async {
    final hasPerm =
        await AppPermissionService.requestGalleryPermission(context);
    if (!hasPerm) return;
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _processImageWithRealOcr(
          bytes,
          photo.path,
          photo.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
        );
      }
    } catch (e) {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty) {
        final bytes = await files.first.readAsBytes();
        await _processImageWithRealOcr(
          bytes,
          files.first.path,
          files.first.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
        );
      }
    }
  }

  Future<void> _processImageWithRealOcr(
      Uint8List bytes, String? path, String title) async {
    setState(() {
      _capturedImageBytes = bytes;
      _sourceFileName = title;
      _isProcessingOcr = true;
    });

    OcrResult ocrResult;
    if (path != null && path.isNotEmpty) {
      ocrResult = await OcrEngineService.processImageFile(path);
    } else {
      ocrResult =
          await OcrEngineService.processImageBytes(bytes, fileName: title);
    }

    String finalText = ocrResult.text;
    int recognizedLines = ocrResult.lineCount;

    // Eğer yerel on-device ML Kit metin bulamadıysa (örneğin Latin dışı alfabeler: Arapça, Rusça, Çince, Japonca, Korece, Hintçe vb.)
    if (finalText.trim().isEmpty) {
      try {
        final cloudRes =
            await RealDocumentPipelineService.extractTextFromImageBytes(
          bytes,
          sourceName: title,
        );
        final cloudText = (cloudRes['text'] as String?)?.trim() ?? '';
        if (cloudText.isNotEmpty) {
          finalText = cloudText;
          recognizedLines =
              cloudText.split('\n').where((l) => l.trim().isNotEmpty).length;
        }
      } catch (e) {
        debugPrint('Fallback OCR error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isProcessingOcr = false;
        _recognizedBlocks = ocrResult.blockCount > 0
            ? ocrResult.blockCount
            : (recognizedLines > 0 ? 1 : 0);
        _recognizedLines = recognizedLines;

        if (finalText.isNotEmpty) {
          _extractedTextController.text = finalText;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(finalText.isNotEmpty
              ? 'OCR: $recognizedLines ${LocalizationService.tr('converter_ocr_lines')} - ${LocalizationService.tr('converter_ocr_status_success')}'
              : LocalizationService.tr('converter_ocr_status_ready')),
          backgroundColor: AppColors.accentEmerald,
        ),
      );
    }
  }

  Future<void> _exportAndShareTxtFile() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    final text = _extractedTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocalizationService.tr('error_empty_ocr')),
            backgroundColor: AppColors.accentRose),
      );
      return;
    }

    final bytes = Uint8List.fromList(utf8.encode(text));
    final filename = '${_sourceFileName}_Metin.txt';

    await CvStorageService.saveDocument(
      DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: filename,
        type: DocumentType.scannedDocument,
        createdAt: DateTime.now(),
        pageCount: 1,
        fileSize: '${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
      ),
      fileBytes: bytes,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
  }

  void _copyToClipboard() {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }
    final text = _extractedTextController.text.trim();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 ${LocalizationService.tr('msg_copied_clipboard')}'),
        backgroundColor: AppColors.accentEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(22),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.text_snippet_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LocalizationService.tr('converter_ocr_title'),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            LocalizationService.tr('converter_ocr_desc'),
            style: const TextStyle(
                fontSize: 11.5, color: Colors.grey, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessingOcr ? null : _captureWithCamera,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: _compactButtonLabel(
                    LocalizationService.tr('camera'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessingOcr ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: _compactButtonLabel(
                    LocalizationService.tr('gallery'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side:
                        const BorderSide(color: Color(0xFF7C3AED), width: 1.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_capturedImageBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E2235) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentEmerald),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_capturedImageBytes!,
                        width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sourceFileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isProcessingOcr
                              ? '⏳ ML Kit...'
                              : 'AI OCR: $_recognizedLines ${LocalizationService.tr('converter_ocr_lines')} / $_recognizedBlocks ${LocalizationService.tr('converter_ocr_blocks')}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _isProcessingOcr
                                ? AppColors.accentAmber
                                : AppColors.accentEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TextField(
              controller: _extractedTextController,
              maxLines: null,
              expands: true,
              style: TextStyle(fontSize: 12, height: 1.4, color: textColor),
              decoration: InputDecoration(
                labelText: LocalizationService.tr('converter_doc_content'),
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _exportAndShareTxtFile,
                  icon: const Icon(Icons.file_download_rounded, size: 18),
                  label: _compactButtonLabel(
                    LocalizationService.tr('converter_save_txt'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: _compactButtonLabel(
                    LocalizationService.tr('copy'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// REAL PDF TO WORD (DOCX) CONVERTER BOTTOM SHEET
// -------------------------------------------------------------
class PdfToDocxSheet extends StatefulWidget {
  const PdfToDocxSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PdfToDocxSheet(),
    );
  }

  @override
  State<PdfToDocxSheet> createState() => _PdfToDocxSheetState();
}

class _PdfToDocxSheetState extends State<PdfToDocxSheet> {
  String? _selectedFileName;
  Uint8List? _pdfBytes;
  List<String> _extractedParagraphs = [];
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: LocalizationService.tr('default_converted_doc_title'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file != null) {
        setState(() => _isProcessing = true);
        final bytes = await file.readAsBytes();

        setState(() {
          _selectedFileName = file.name;
          _titleController.text =
              file.name.replaceAll('.pdf', '').replaceAll('.PDF', '');
          _pdfBytes = bytes;
        });

        final lines = DocxConverterService.extractTextLinesFromPdf(bytes);

        setState(() {
          _extractedParagraphs = lines.isNotEmpty
              ? lines
              : [LocalizationService.tr('converter_pdf_extracted')];
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('error_read_file')}: $e')),
        );
      }
    }
  }

  Future<void> _exportAndSaveDocx() async {
    if (_pdfBytes == null && _extractedParagraphs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.tr('error_pick_pdf'))),
      );
      return;
    }

    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    try {
      Uint8List docxBytes;
      if (_pdfBytes != null && _selectedFileName != null) {
        try {
          docxBytes = await RealDocumentPipelineService.convertPdfToDocxBytes(
            _pdfBytes!,
            fileName: _selectedFileName!,
          );
        } catch (_) {
          docxBytes = DocxConverterService.createDocxFromText(
            title: _titleController.text.trim().isEmpty
                ? LocalizationService.tr('default_doc_title')
                : _titleController.text.trim(),
            paragraphs: _extractedParagraphs,
          );
        }
      } else {
        docxBytes = DocxConverterService.createDocxFromText(
          title: _titleController.text.trim().isEmpty
              ? LocalizationService.tr('default_doc_title')
              : _titleController.text.trim(),
          paragraphs: _extractedParagraphs,
        );
      }

      final tempDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_titleController.text.trim().replaceAll(' ', '_')}_Word.docx';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(docxBytes);

      // Save to document archive
      final sizeKb = (docxBytes.lengthInBytes / 1024).toStringAsFixed(1);
      await CvStorageService.saveDocument(
        DocumentModel(
          id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
          title: fileName,
          type: DocumentType.scannedDocument,
          createdAt: DateTime.now(),
          pageCount: 1,
          fileSize: '$sizeKb KB',
        ),
        fileBytes: docxBytes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ $fileName ${LocalizationService.tr('msg_file_saved')}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [
            XFile(file.path,
                name: fileName,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
          ],
          text: LocalizationService.tr('share_pdf_to_word_msg'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${LocalizationService.tr('error_convert')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocalizationService.tr('converter_pdf_to_word'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            LocalizationService.tr('converter_pdf_to_word_desc'),
            style: const TextStyle(
                fontSize: 11.5, color: Colors.grey, height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickPdfFile,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: _compactButtonLabel(
              _selectedFileName == null
                  ? LocalizationService.tr('error_pick_pdf')
                  : 'PDF: $_selectedFileName',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedFileName != null) ...[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: LocalizationService.tr('converter_doc_title'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: _selectedFileName == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          LocalizationService.tr('error_pick_pdf'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    child: ListView.builder(
                      itemCount: _extractedParagraphs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2563EB)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _extractedParagraphs[index],
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.4,
                                      color: textColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (_selectedFileName != null && !_isProcessing)
                ? _exportAndSaveDocx
                : null,
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: _compactButtonLabel(
              _isProcessing
                  ? LocalizationService.tr('converter_generating_pdf')
                  : LocalizationService.tr('converter_pdf_to_word'),
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. REAL PDF TO TXT EXTRACTOR MODAL SHEET
class PdfToTxtSheet extends StatefulWidget {
  const PdfToTxtSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PdfToTxtSheet(),
    );
  }

  @override
  State<PdfToTxtSheet> createState() => _PdfToTxtSheetState();
}

class _PdfToTxtSheetState extends State<PdfToTxtSheet> {
  String? _selectedFileName;
  String _extractedText = '';
  bool _isProcessing = false;

  Future<void> _pickPdfFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file != null) {
        setState(() => _isProcessing = true);
        final bytes = await file.readAsBytes();

        setState(() {
          _selectedFileName = file.name;
        });

        final lines = DocxConverterService.extractTextLinesFromPdf(bytes);

        setState(() {
          _extractedText = lines.join('\n\n');
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('error_read_file')}: $e')),
        );
      }
    }
  }

  Future<void> _exportTxtFile() async {
    if (_extractedText.isEmpty) return;

    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    try {
      final tempDir = await getApplicationDocumentsDirectory();
      final name =
          '${_selectedFileName?.replaceAll('.pdf', '') ?? 'Metin'}_Metin.txt';
      final file = File('${tempDir.path}/$name');
      await file.writeAsString(_extractedText);

      await CvStorageService.saveDocument(
        DocumentModel(
          id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
          title: name,
          type: DocumentType.scannedDocument,
          createdAt: DateTime.now(),
          pageCount: 1,
          fileSize: '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
        ),
        fileBytes: Uint8List.fromList(utf8.encode(_extractedText)),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ $name ${LocalizationService.tr('msg_file_saved')}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path, name: name)]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('error_read_file')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.text_snippet_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocalizationService.tr('converter_pdf_to_txt'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            LocalizationService.tr('converter_pdf_to_txt_desc'),
            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickPdfFile,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: _compactButtonLabel(
              _selectedFileName == null
                  ? LocalizationService.tr('error_pick_pdf')
                  : 'PDF: $_selectedFileName',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _extractedText.isEmpty
                ? Center(
                    child: Text(
                        LocalizationService.tr('converter_no_img_selected'),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)))
                : TextField(
                    controller: TextEditingController(text: _extractedText),
                    maxLines: null,
                    expands: true,
                    readOnly: false,
                    style:
                        TextStyle(fontSize: 12, color: textColor, height: 1.4),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _extractedText.isNotEmpty ? _exportTxtFile : null,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: _compactButtonLabel(
                    LocalizationService.tr('converter_save_txt'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _extractedText.isNotEmpty
                      ? () {
                          if (!(AuthService.currentUser?.isPro ?? false)) {
                            VipPaywallSheet.show(context);
                            return;
                          }
                          Clipboard.setData(
                              ClipboardData(text: _extractedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(LocalizationService.tr(
                                    'msg_copied_clipboard'))),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: _compactButtonLabel(
                    LocalizationService.tr('copy'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 8. WORD (DOCX) ➔ EXCEL (XLSX) MODAL SHEET
// =========================================================================
class WordToExcelSheet extends StatefulWidget {
  const WordToExcelSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WordToExcelSheet(),
    );
  }

  @override
  State<WordToExcelSheet> createState() => _WordToExcelSheetState();
}

class _WordToExcelSheetState extends State<WordToExcelSheet> {
  String? _selectedFileName;
  String _docTitle = 'Document';
  List<String> _extractedParagraphs = [];
  bool _isProcessing = false;

  Future<void> _pickWordFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc', 'txt', 'md'],
      );

      if (file != null) {
        setState(() => _isProcessing = true);
        final bytes = await file.readAsBytes();
        final ext = file.extension?.toLowerCase() ?? '';

        String rawText;
        if (ext == 'docx' || ext == 'doc') {
          rawText = await DocumentParserService.parseDocx(bytes);
        } else {
          try {
            rawText = utf8.decode(bytes, allowMalformed: true);
          } catch (_) {
            rawText = String.fromCharCodes(bytes);
          }
        }

        final paragraphs = rawText
            .split('\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        setState(() {
          _isProcessing = false;
          _selectedFileName = file.name;
          _docTitle = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          _extractedParagraphs = paragraphs;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_read')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _generateAndExportExcel() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    if (_extractedParagraphs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocalizationService.tr('converter_err_no_text'))),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final xlsxBytes = OfficeConverterService.createXlsxFromText(
        title: _docTitle,
        paragraphs: _extractedParagraphs,
      );

      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = _docTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName =
          '${sanitizedName}_Excel_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(xlsxBytes);

      final doc = DocumentModel(
        id: 'docx_to_xlsx_${DateTime.now().millisecondsSinceEpoch}',
        title: '$_docTitle (Excel Tablo)',
        createdAt: DateTime.now(),
        pageCount: 1,
        fileSize: '${(xlsxBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
        type: DocumentType.scannedDocument,
      );
      await CvStorageService.saveDocument(doc, fileBytes: xlsxBytes);

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ $fileName ${LocalizationService.tr('converter_success_msg')}'),
            backgroundColor: AppColors.accentEmerald,
          ),
        );
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: doc.title);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_convert')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.excelGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.table_chart_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('converter_word_to_excel'),
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                    Text(
                      LocalizationService.tr('converter_word_to_excel_desc'),
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickWordFile,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: _compactButtonLabel(
              _selectedFileName == null
                  ? LocalizationService.tr('converter_select_word')
                  : 'Word: $_selectedFileName',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _extractedParagraphs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          LocalizationService.tr('converter_no_word_selected'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F121E)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentEmerald, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${LocalizationService.tr('converter_extracted_paragraphs')}: ${_extractedParagraphs.length}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: textColor),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _extractedParagraphs.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${i + 1}. ${_extractedParagraphs[i]}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : const Color(0xFF334155)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _extractedParagraphs.isNotEmpty && !_isProcessing
                ? _generateAndExportExcel
                : null,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: _compactButtonLabel(
              _isProcessing
                  ? LocalizationService.tr('converter_processing')
                  : LocalizationService.tr('converter_export_excel'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 9. EXCEL (XLSX) ➔ WORD (DOCX) MODAL SHEET
// =========================================================================
class ExcelToDocxSheet extends StatefulWidget {
  const ExcelToDocxSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ExcelToDocxSheet(),
    );
  }

  @override
  State<ExcelToDocxSheet> createState() => _ExcelToDocxSheetState();
}

class _ExcelToDocxSheetState extends State<ExcelToDocxSheet> {
  String? _selectedFileName;
  String _docTitle = 'Excel Tablosu';
  List<List<String>> _extractedGrid = [];
  bool _isProcessing = false;

  Future<void> _pickExcelFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'tsv'],
      );

      if (file != null) {
        setState(() => _isProcessing = true);
        final bytes = await file.readAsBytes();
        final ext = file.extension?.toLowerCase() ?? '';

        List<List<String>> grid;
        if (ext == 'xlsx' || ext == 'xls') {
          grid = await DocumentParserService.parseXlsx(bytes);
        } else {
          final text = utf8.decode(bytes, allowMalformed: true);
          grid = DocumentParserService.parseCsv(text);
        }

        setState(() {
          _isProcessing = false;
          _selectedFileName = file.name;
          _docTitle = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          _extractedGrid = grid;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_read')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _generateAndExportDocx() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    if (_extractedGrid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocalizationService.tr('converter_err_no_table'))),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final docxBytes = OfficeConverterService.createDocxFromGrid(
        title: _docTitle,
        grid: _extractedGrid,
      );

      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = _docTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName =
          '${sanitizedName}_Word_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(docxBytes);

      final doc = DocumentModel(
        id: 'xlsx_to_docx_${DateTime.now().millisecondsSinceEpoch}',
        title: '$_docTitle (Word Tablosu)',
        createdAt: DateTime.now(),
        pageCount: 1,
        fileSize: '${(docxBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
        type: DocumentType.scannedDocument,
      );
      await CvStorageService.saveDocument(doc, fileBytes: docxBytes);

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ $fileName ${LocalizationService.tr('converter_success_msg')}'),
            backgroundColor: AppColors.accentEmerald,
          ),
        );
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: doc.title);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_convert')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.wordDocGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('converter_excel_to_word'),
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                    Text(
                      LocalizationService.tr('converter_excel_to_word_desc'),
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickExcelFile,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: _compactButtonLabel(
              _selectedFileName == null
                  ? LocalizationService.tr('converter_select_excel')
                  : 'Excel: $_selectedFileName',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _extractedGrid.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.table_rows_rounded,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          LocalizationService.tr('converter_no_excel_selected'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F121E)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentEmerald, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${LocalizationService.tr('converter_extracted_rows')}: ${_extractedGrid.length} (${_extractedGrid.first.length})',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: textColor),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _extractedGrid.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${i + 1}. ${_extractedGrid[i].join(' | ')}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: i == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : const Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _extractedGrid.isNotEmpty && !_isProcessing
                ? _generateAndExportDocx
                : null,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: _compactButtonLabel(
              _isProcessing
                  ? LocalizationService.tr('converter_processing')
                  : LocalizationService.tr('converter_export_word'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 10. POWERPOINT (PPTX) ➔ WORD (DOCX) MODAL SHEET
// =========================================================================
class PptxToDocxSheet extends StatefulWidget {
  const PptxToDocxSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PptxToDocxSheet(),
    );
  }

  @override
  State<PptxToDocxSheet> createState() => _PptxToDocxSheetState();
}

class _PptxToDocxSheetState extends State<PptxToDocxSheet> {
  String? _selectedFileName;
  String _docTitle = 'Presentation';
  List<PptxSlide> _slides = [];
  bool _isProcessing = false;

  Future<void> _pickPptxFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pptx', 'ppt'],
      );

      if (file != null) {
        setState(() => _isProcessing = true);
        final bytes = await file.readAsBytes();
        final slides = await DocumentParserService.parsePptx(bytes);

        setState(() {
          _isProcessing = false;
          _selectedFileName = file.name;
          _docTitle = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          _slides = slides;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_read')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _generateAndExportDocx() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    if (_slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocalizationService.tr('converter_err_no_slide'))),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final docxBytes = OfficeConverterService.createDocxFromSlides(
        title: _docTitle,
        slides: _slides,
      );

      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = _docTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName =
          '${sanitizedName}_Sunum_Word_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(docxBytes);

      final doc = DocumentModel(
        id: 'pptx_to_docx_${DateTime.now().millisecondsSinceEpoch}',
        title: '$_docTitle (Sunum Word Belgesi)',
        createdAt: DateTime.now(),
        pageCount: _slides.length,
        fileSize: '${(docxBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
        type: DocumentType.scannedDocument,
      );
      await CvStorageService.saveDocument(doc, fileBytes: docxBytes);

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ $fileName ${LocalizationService.tr('converter_success_msg')}'),
            backgroundColor: AppColors.accentEmerald,
          ),
        );
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: doc.title);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_convert')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.pptGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.slideshow_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('converter_pptx_to_word'),
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                    Text(
                      LocalizationService.tr('converter_pptx_to_word_desc'),
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickPptxFile,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: _compactButtonLabel(
              _selectedFileName == null
                  ? LocalizationService.tr('converter_select_pptx')
                  : 'PPTX: $_selectedFileName',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _slides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.slideshow_outlined,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          LocalizationService.tr('converter_no_pptx_selected'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F121E)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentEmerald, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${LocalizationService.tr('converter_extracted_slides')}: ${_slides.length}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: textColor),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _slides.length,
                            itemBuilder: (ctx, i) {
                              final s = _slides[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Slide ${s.index}: ${s.title}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: textColor),
                                    ),
                                    if (s.bulletPoints.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, top: 2),
                                        child: Text(
                                          s.bulletPoints
                                              .map((b) => '• $b')
                                              .join('\n'),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : const Color(0xFF475569)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _slides.isNotEmpty && !_isProcessing
                ? _generateAndExportDocx
                : null,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: _compactButtonLabel(
              _isProcessing
                  ? LocalizationService.tr('converter_processing')
                  : LocalizationService.tr('converter_export_word'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 11. WORD (DOCX) ➔ POWERPOINT (PPTX) MODAL SHEET
// =========================================================================
class DocxToPptxSheet extends StatefulWidget {
  const DocxToPptxSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DocxToPptxSheet(),
    );
  }

  @override
  State<DocxToPptxSheet> createState() => _DocxToPptxSheetState();
}

class _DocxToPptxSheetState extends State<DocxToPptxSheet> {
  String? _selectedFileName;
  String _docTitle = 'Sunum';
  List<String> _extractedParagraphs = [];
  bool _isProcessing = false;

  Future<void> _pickWordFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc', 'txt', 'md'],
      );

      if (file != null) {
        setState(() => _isProcessing = true);
        final bytes = await file.readAsBytes();
        final ext = file.extension?.toLowerCase() ?? '';

        String rawText;
        if (ext == 'docx' || ext == 'doc') {
          rawText = await DocumentParserService.parseDocx(bytes);
        } else {
          try {
            rawText = utf8.decode(bytes, allowMalformed: true);
          } catch (_) {
            rawText = String.fromCharCodes(bytes);
          }
        }

        final paragraphs = rawText
            .split('\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        setState(() {
          _isProcessing = false;
          _selectedFileName = file.name;
          _docTitle = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          _extractedParagraphs = paragraphs;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_read')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _generateAndExportPptx() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    if (_extractedParagraphs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocalizationService.tr('converter_err_no_text'))),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final pptxBytes = OfficeConverterService.createPptxFromParagraphs(
        title: _docTitle,
        paragraphs: _extractedParagraphs,
      );

      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = _docTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName =
          '${sanitizedName}_Sunum_${DateTime.now().millisecondsSinceEpoch}.pptx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pptxBytes);

      final doc = DocumentModel(
        id: 'docx_to_pptx_${DateTime.now().millisecondsSinceEpoch}',
        title: '$_docTitle (PowerPoint Sunumu)',
        createdAt: DateTime.now(),
        pageCount: (_extractedParagraphs.length / 4).ceil().clamp(1, 100),
        fileSize: '${(pptxBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
        type: DocumentType.scannedDocument,
      );
      await CvStorageService.saveDocument(doc, fileBytes: pptxBytes);

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ $fileName ${LocalizationService.tr('converter_success_msg')}'),
            backgroundColor: AppColors.accentEmerald,
          ),
        );
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: doc.title);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_convert')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFB45309)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.present_to_all_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('converter_word_to_pptx'),
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                    Text(
                      LocalizationService.tr('converter_word_to_pptx_desc'),
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickWordFile,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: _compactButtonLabel(
              _selectedFileName == null
                  ? LocalizationService.tr('converter_select_word')
                  : 'Word: $_selectedFileName',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _extractedParagraphs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.present_to_all_rounded,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          LocalizationService.tr('converter_no_word_selected'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F121E)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentEmerald, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${LocalizationService.tr('converter_slide_estimate')}: ${(_extractedParagraphs.length / 4).ceil()}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: textColor),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _extractedParagraphs.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${i + 1}. ${_extractedParagraphs[i]}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : const Color(0xFF334155)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _extractedParagraphs.isNotEmpty && !_isProcessing
                ? _generateAndExportPptx
                : null,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: _compactButtonLabel(
              _isProcessing
                  ? LocalizationService.tr('converter_processing')
                  : LocalizationService.tr('converter_export_pptx'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 12. POWERPOINT (PPTX) ➔ EXCEL (XLSX) MODAL SHEET
// =========================================================================
class PptxToExcelSheet extends StatefulWidget {
  const PptxToExcelSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PptxToExcelSheet(),
    );
  }

  @override
  State<PptxToExcelSheet> createState() => _PptxToExcelSheetState();
}

class _PptxToExcelSheetState extends State<PptxToExcelSheet> {
  String? _selectedFileName;
  String _docTitle = 'Sunum Tablosu';
  List<PptxSlide> _slides = [];
  bool _isProcessing = false;

  Future<void> _pickPptxFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pptx', 'ppt'],
      );

      if (file != null) {
        setState(() => _isProcessing = true);
        final bytes = await file.readAsBytes();
        final slides = await DocumentParserService.parsePptx(bytes);

        setState(() {
          _isProcessing = false;
          _selectedFileName = file.name;
          _docTitle = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          _slides = slides;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_read')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  Future<void> _generateAndExportExcel() async {
    if (!(AuthService.currentUser?.isPro ?? false)) {
      VipPaywallSheet.show(context);
      return;
    }

    if (_slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(LocalizationService.tr('converter_err_no_slide'))),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final xlsxBytes = OfficeConverterService.createXlsxFromSlides(
        title: _docTitle,
        slides: _slides,
      );

      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = _docTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final fileName =
          '${sanitizedName}_Sunum_Excel_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(xlsxBytes);

      final doc = DocumentModel(
        id: 'pptx_to_xlsx_${DateTime.now().millisecondsSinceEpoch}',
        title: '$_docTitle (Sunum Excel Tablosu)',
        createdAt: DateTime.now(),
        pageCount: _slides.length,
        fileSize: '${(xlsxBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
        type: DocumentType.scannedDocument,
      );
      await CvStorageService.saveDocument(doc, fileBytes: xlsxBytes);

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ $fileName ${LocalizationService.tr('converter_success_msg')}'),
            backgroundColor: AppColors.accentEmerald,
          ),
        );
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: doc.title);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocalizationService.tr('converter_err_convert')}$e'),
              backgroundColor: AppColors.accentRose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ScrollableSheetBody(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.excelGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_on_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('converter_pptx_to_excel'),
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                    Text(
                      LocalizationService.tr('converter_pptx_to_excel_desc'),
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickPptxFile,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: _compactButtonLabel(
              _selectedFileName == null
                  ? LocalizationService.tr('converter_select_pptx')
                  : 'PPTX: $_selectedFileName',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _slides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_on_outlined,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          LocalizationService.tr('converter_no_pptx_selected'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F121E)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentEmerald, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${LocalizationService.tr('converter_extracted_slides')}: ${_slides.length}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: textColor),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _slides.length,
                            itemBuilder: (ctx, i) {
                              final s = _slides[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'Slide ${s.index}: ${s.title} (${s.bulletPoints.length})',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : const Color(0xFF334155)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _slides.isNotEmpty && !_isProcessing
                ? _generateAndExportExcel
                : null,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: _compactButtonLabel(
              _isProcessing
                  ? LocalizationService.tr('converter_processing')
                  : LocalizationService.tr('converter_export_excel'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
