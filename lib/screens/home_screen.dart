import 'package:flutter/material.dart';
 
import 'package:printing/printing.dart';
import '../constants/theme_constants.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';
import '../services/cv_storage_service.dart';
import '../services/localization_service.dart';
import '../services/pdf_generator_service.dart';
import 'cv_builder_screen.dart';
import 'cam_scanner_screen.dart';
import 'pdf_converter_screen.dart';
import 'documents_library_screen.dart';
import 'vip_paywall_sheet.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  final Function(int)? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onToggleTheme,
    this.isDark = true,
    this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final onToggleTheme = widget.onToggleTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final headerBg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // PINNED PREMIUM HEADER (ALWAYS VISIBLE AT TOP)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  color: headerBg,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Logo & Title: "CV AI" (Flexibly bounded)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFF38BDF8), Color(0xFF1D4ED8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        LocalizationService.tr('app_title'),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.8,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'STUDIO',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    LocalizationService.tr('app_subtitle'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Action: Ultra-Radiant Circular User Profile Avatar
                      ValueListenableBuilder<UserModel?>(
                        valueListenable: AuthService.currentUserNotifier,
                        builder: (context, user, _) {
                          final isProUser = user?.isPro ?? false;
                          final initials = user != null && user.fullName.isNotEmpty
                              ? user.fullName
                                  .trim()
                                  .split(' ')
                                  .where((w) => w.isNotEmpty)
                                  .map((w) => w[0].toUpperCase())
                                  .take(2)
                                  .join()
                              : 'CV';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () => ProfileScreen.show(
                                context,
                                isDark: isDark,
                                onToggleTheme: onToggleTheme ?? () {},
                                isPro: isProUser,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: isProUser
                                            ? const LinearGradient(
                                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : LinearGradient(
                                                colors: isDark
                                                    ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                                                    : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        border: Border.all(
                                          color: isProUser
                                              ? const Color(0xFFFFD54F)
                                              : (isDark ? const Color(0xFF475569) : const Color(0xFF93C5FD)),
                                          width: isProUser ? 2 : 1.5,
                                        ),
                                        boxShadow: isProUser
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.45 : 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 3),
                                                ),
                                                BoxShadow(
                                                  color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isProUser)
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3.5),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.radiantGoldGradient,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? const Color(0xFF0C0D14) : Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFA000).withValues(alpha: 0.7),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 11,
                                            color: Color(0xFF451A03),
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
                    ],
                  ),
                ),

                // SCROLLABLE BODY
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                    children: [
                      // HERO DIRECT CV CREATOR CARD
                      GestureDetector(
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(1);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CvBuilderScreen(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1E3A8A),
                                Color(0xFF2563EB),
                                Color(0xFF7C3AED),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.bolt_rounded,
                                            color: AppColors.accentAmber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          LocalizationService.tr('home_hero_badge'),
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white, size: 16),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                LocalizationService.tr('home_hero_title'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.15,
                                  letterSpacing: -0.4,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                LocalizationService.tr('home_hero_sub'),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFDBEAFE),
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_document,
                                        color: Color(0xFF1E3A8A), size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      LocalizationService.tr('home_hero_cta'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E3A8A),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: Color(0xFF1E3A8A), size: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Office Converters Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LocalizationService.tr('home_converter_title'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (widget.onNavigateTab != null) {
                                widget.onNavigateTab!(3);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PdfConverterScreen(),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              '${LocalizationService.tr('home_converter_all')} ➔',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      SizedBox(
                        height: 158 * MediaQuery.textScalerOf(context).scale(1),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildMiniConverterCard(
                              context,
                              title: LocalizationService.tr('convert_word_to_pdf'),
                              format: 'DOCX ➔ PDF',
                              gradient: AppColors.wordDocGradient,
                              icon: Icons.article_rounded,
                              onTap: () => DocToPdfSheet.show(context),
                            ),
                            const SizedBox(width: 15),
                            _buildMiniConverterCard(
                              context,
                              title: LocalizationService.tr('convert_pptx_to_pdf'),
                              format: 'PPTX ➔ PDF',
                              gradient: AppColors.pptGradient,
                              icon: Icons.slideshow_rounded,
                              onTap: () => PptxToPdfSheet.show(context),
                            ),
                            const SizedBox(width: 15),
                            _buildMiniConverterCard(
                              context,
                              title: LocalizationService.tr('convert_pdf_to_docx'),
                              format: 'PDF ➔ DOCX',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                              ),
                              icon: Icons.description_rounded,
                              onTap: () => PdfToDocxSheet.show(context),
                            ),
                            const SizedBox(width: 15),
                            _buildMiniConverterCard(
                              context,
                              title: LocalizationService.tr('converter_word_to_excel'),
                              format: 'DOCX ➔ XLSX',
                              gradient: AppColors.excelGradient,
                              icon: Icons.table_chart_rounded,
                              onTap: () => WordToExcelSheet.show(context),
                            ),
                            const SizedBox(width: 15),
                            _buildMiniConverterCard(
                              context,
                              title: LocalizationService.tr('converter_pptx_to_word'),
                              format: 'PPTX ➔ DOCX',
                              gradient: AppColors.pptGradient,
                              icon: Icons.slideshow_rounded,
                              onTap: () => PptxToDocxSheet.show(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Studio Tools
                      Text(
                        LocalizationService.tr('home_tools_title'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: LocalizationService.tr('cam_title'),
                              subtitle: LocalizationService.tr('home_tool_cam_sub'),
                              badge: LocalizationService.tr('cam_auto_mode'),
                              icon: Icons.document_scanner_rounded,
                              gradient: AppColors.emeraldGradient,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CamScannerScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: LocalizationService.tr('convert_img_to_pdf'),
                              subtitle: LocalizationService.tr('home_tool_img_sub'),
                              badge: 'HD PDF',
                              icon: Icons.photo_library_rounded,
                              gradient: AppColors.purpleGradient,
                              isDark: isDark,
                              onTap: () => ImageToPdfSheet.show(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: LocalizationService.tr('convert_ocr_to_txt'),
                              subtitle: LocalizationService.tr('home_tool_ocr_sub'),
                              badge: 'AI OCR',
                              icon: Icons.text_snippet_rounded,
                              gradient: AppColors.purpleGradient,
                              isDark: isDark,
                              onTap: () => OcrToTxtSheet.show(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: LocalizationService.tr('home_saved_docs'),
                              subtitle: LocalizationService.tr('home_saved_docs_sub'),
                              badge: LocalizationService.tr('nav_archive'),
                              icon: Icons.folder_shared_rounded,
                              gradient: AppColors.blueGradient,
                              isDark: isDark,
                              onTap: () {
                                if (widget.onNavigateTab != null) {
                                  widget.onNavigateTab!(4);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DocumentsLibraryScreen(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Recent Documents Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LocalizationService.tr('home_recent_title'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (widget.onNavigateTab != null) {
                                widget.onNavigateTab!(4);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DocumentsLibraryScreen(),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              '${LocalizationService.tr('home_recent_all')} ➔',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Dynamic Real Documents List from Supabase / Local Storage
                      FutureBuilder<List<DocumentModel>>(
                        future: CvStorageService.loadDocuments(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data ?? [];
                          if (docs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E2438) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.folder_open_rounded,
                                      color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizationService.tr('docs_empty_title'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          LocalizationService.tr('docs_empty_desc'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final displayDocs = docs.take(3).toList();
                          return Column(
                            children: displayDocs.map((doc) {
                              IconData icon;
                              Color iconColor;
                              switch (doc.type) {
                                case DocumentType.cv:
                                  icon = Icons.badge_rounded;
                                  iconColor = AppColors.primary;
                                  break;
                                case DocumentType.scannedDocument:
                                  icon = Icons.document_scanner_rounded;
                                  iconColor = const Color(0xFF10B981);
                                  break;
                                case DocumentType.imageToPdf:
                                case DocumentType.invoice:
                                case DocumentType.signedContract:
                                  icon = Icons.picture_as_pdf_rounded;
                                  iconColor = const Color(0xFFF59E0B);
                                  break;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildRecentTile(
                                  context,
                                  icon: icon,
                                  iconColor: iconColor,
                                  title: doc.title,
                                  type: '${doc.typeLabel} • ${doc.pageCount} p • ${doc.fileSize}',
                                  time: '${doc.createdAt.day}.${doc.createdAt.month}.${doc.createdAt.year}',
                                  isDark: isDark,
                                  onTap: () => _showRecentDocumentModal(
                                    context,
                                    title: doc.title,
                                    type: '${doc.typeLabel} • ${doc.pageCount} p',
                                    icon: icon,
                                    iconColor: iconColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
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

  Widget _buildMiniConverterCard(
    BuildContext context, {
    required String title,
    required String format,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 158 * MediaQuery.textScalerOf(context).scale(1),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.38),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    format,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required LinearGradient gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 145,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gradient.colors.first.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: gradient.colors.first,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecentDocumentModal(
    BuildContext context, {
    required String title,
    required String type,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                        type,
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

            // Open & Preview PDF
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility_rounded, color: AppColors.primaryLight, size: 20),
              ),
              title: Text(LocalizationService.tr('open_preview_pdf'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                if (!(AuthService.currentUser?.isPro ?? false)) {
                  VipPaywallSheet.show(context);
                  return;
                }
                final pdfBytes = await PdfGeneratorService.generateConvertedDocumentPdf(
                  fileName: title.replaceAll('.pdf', ''),
                  fileType: 'PDF',
                  originalFormat: 'Belge',
                );
                await Printing.layoutPdf(
                  onLayout: (_) => pdfBytes,
                  name: title,
                );
              },
            ),

            // Share PDF
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              title: Text(LocalizationService.tr('share_as_pdf'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                if (!(AuthService.currentUser?.isPro ?? false)) {
                  VipPaywallSheet.show(context);
                  return;
                }
                final pdfBytes = await PdfGeneratorService.generateConvertedDocumentPdf(
                  fileName: title.replaceAll('.pdf', ''),
                  fileType: 'PDF',
                  originalFormat: 'Belge',
                );
                await Printing.sharePdf(
                  bytes: pdfBytes,
                  filename: title,
                );
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
              title: Text(LocalizationService.tr('print_document'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                if (!(AuthService.currentUser?.isPro ?? false)) {
                  VipPaywallSheet.show(context);
                  return;
                }
                final pdfBytes = await PdfGeneratorService.generateConvertedDocumentPdf(
                  fileName: title.replaceAll('.pdf', ''),
                  fileType: 'PDF',
                  originalFormat: 'Belge',
                );
                await Printing.layoutPdf(
                  onLayout: (_) => pdfBytes,
                  name: title,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String type,
    required String time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$type • $time',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
