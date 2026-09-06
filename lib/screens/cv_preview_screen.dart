import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../constants/theme_constants.dart';
import '../models/cv_model.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/localization_service.dart';
import 'vip_paywall_sheet.dart';

class CvPreviewScreen extends StatelessWidget {
  final CvModel cv;

  const CvPreviewScreen({super.key, required this.cv});

  Future<void> _exportAndSaveCv(BuildContext context) async {
    // Ücretsiz kullanıcılar dışa aktarma / paylaşma yaparken Paywall ekranı açılır
    final isPro = AuthService.currentUser?.isPro ?? false;
    if (!isPro) {
      VipPaywallSheet.show(context);
      return;
    }

    final cvLocale = (cv.targetLanguage != null && cv.targetLanguage!.trim().isNotEmpty)
        ? cv.targetLanguage!
        : LocalizationService.currentLocale;
    final pdfBytes = await PdfGeneratorService.generateCvPdf(cv,
        locale: cvLocale);
    final fileName =
        '${cv.fullName.isNotEmpty ? cv.fullName.replaceAll(' ', '_') : 'CV'}_CV_AI.pdf';

    await CvStorageService.saveActiveCv(cv);
    await CvStorageService.saveDocument(
      DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName,
        type: DocumentType.cv,
        createdAt: DateTime.now(),
        pageCount: 1,
        fileSize: '${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(0)} KB',
      ),
      fileBytes: pdfBytes,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  Future<void> _printCv(BuildContext context) async {
    // Ücretsiz kullanıcılar yazdırma yaparken Paywall ekranı açılır
    final isPro = AuthService.currentUser?.isPro ?? false;
    if (!isPro) {
      VipPaywallSheet.show(context);
      return;
    }

    final cvLocale = (cv.targetLanguage != null && cv.targetLanguage!.trim().isNotEmpty)
        ? cv.targetLanguage!
        : LocalizationService.currentLocale;
    final pdfBytes = await PdfGeneratorService.generateCvPdf(cv,
        locale: cvLocale);
    final fileName =
        '${cv.fullName.isNotEmpty ? cv.fullName.replaceAll(' ', '_') : 'CV'}_CV_AI.pdf';

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: fileName,
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
        final textColor =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
                }
              },
            ),
            title: Text(
              LocalizationService.tr('cv_preview_btn'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: textColor),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_rounded,
                    color: AppColors.primaryLight, size: 22),
                tooltip: LocalizationService.tr('docs_action_print'),
                onPressed: () => _printCv(context),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded,
                    color: AppColors.primaryLight, size: 22),
                tooltip: LocalizationService.tr('docs_action_share'),
                onPressed: () => _exportAndSaveCv(context),
              ),
              IconButton(
                icon: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.accentAmber, size: 24),
                tooltip: 'PRO VIP',
                onPressed: () => VipPaywallSheet.show(context),
              ),
            ],
          ),
          body: PdfPreview.builder(
            build: (format) => PdfGeneratorService.generateCvPdf(cv,
                locale: (cv.targetLanguage != null && cv.targetLanguage!.trim().isNotEmpty)
                    ? cv.targetLanguage!
                    : LocalizationService.currentLocale),
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
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.45 : 0.15),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
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
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder)),
            ),
            child: Row(
              children: [
                // Print button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _printCv(context),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      LocalizationService.tr('docs_action_print'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Share / Download PDF button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportAndSaveCv(context),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: Text(
                      '${LocalizationService.tr('docs_action_share')} (PDF)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
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
