import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/theme_constants.dart';
import '../models/cv_model.dart';
import '../services/cv_storage_service.dart';
import '../services/localization_service.dart';
import '../services/app_permission_service.dart';
import '../services/ai_cv_service.dart';
import '../services/document_parser_service.dart';
import '../widgets/ai_aurora_glow.dart';
import '../widgets/voice_to_cv_sheet.dart';
import '../services/auth_service.dart';
import 'cv_preview_screen.dart';

class CvBuilderScreen extends StatefulWidget {
  final CvModel? initialCv;
  final VoidCallback? onReturnHome;

  const CvBuilderScreen({
    super.key,
    this.initialCv,
    this.onReturnHome,
  });

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CvModel _cv;
  late String _cvLanguage;

  String _cvTr(String key) => LocalizationService.trFor(_cvLanguage, key);

  Future<void> _pickProfilePhotoFromGallery() async {
    final hasPerm =
        await AppPermissionService.requestGalleryPermission(context);
    if (!hasPerm) return;
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 90,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _cv.profilePhotoBytes = bytes;
          _cv.hasPhoto = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.tr('msg_photo_added')),
              backgroundColor: AppColors.accentEmerald,
            ),
          );
        }
      }
    } catch (e) {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty) {
        final bytes = await files.first.readAsBytes();
        setState(() {
          _cv.profilePhotoBytes = bytes;
          _cv.hasPhoto = true;
        });
      }
    }
  }

  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _portfolioController;
  late TextEditingController _summaryController;
  final TextEditingController _aiPromptController = TextEditingController();
  bool _isAiGenerating = false;
  final Set<String> _glowingItemKeys = <String>{};
  bool _isTypewritingSummary = false;

  Future<void> _handleVoiceToCv() async {
    final hasMic =
        await AppPermissionService.requestMicrophonePermission(context);
    if (!hasMic || !mounted) return;

    await VoiceToCvSheet.show(
      context: context,
      onApplyPrompt: (voiceText) async {
        final cleanText = voiceText.trim();
        if (cleanText.isEmpty) return;

        setState(() {
          _isAiGenerating = true;
          _summaryController.text = cleanText;
          _cv.summary = cleanText;
        });

        try {
          final parseResult = await AiCvService.parseCvPrompt(
            prompt: cleanText,
            locale: LocalizationService.currentLocale,
            isStrictExtraction: false,
          );
          if (!mounted) return;

          if (parseResult.isSuccess && parseResult.totalExtractedItems > 0) {
            // Voice input fills absent data but never erases the current CV.
            _applyAiParseResult(parseResult);
          } else {
            final enhancedText = await AiCvService.enhanceSummary(
              rawSummary: cleanText,
              locale: LocalizationService.currentLocale,
            );
            if (mounted && enhancedText != null && enhancedText.isNotEmpty) {
              setState(() {
                _summaryController.text = enhancedText;
                _cv.summary = enhancedText;
              });
            }
          }
        } catch (e) {
          if (mounted) _showAiImportError(e);
        } finally {
          if (mounted) setState(() => _isAiGenerating = false);
        }
      },
    );
  }

  final TextEditingController _skillInputController = TextEditingController();
  final TextEditingController _traitInputController = TextEditingController();
  double _newSkillLevel = 85;
  final TextEditingController _newSectionTitleController =
      TextEditingController();

  List<String> get _quickSkills => LocalizationService.getQuickSkills();
  List<String> get _quickTraits =>
      LocalizationService.getQuickTraits(_cvLanguage);
  List<String> get _quickCustomTitles =>
      LocalizationService.getQuickCustomTitles(_cvLanguage);
  List<String> get _languageLevels =>
      LocalizationService.getLanguageLevels(_cvLanguage);
  List<Map<String, dynamic>> get _themePalette =>
      LocalizationService.getThemePalettes(_cvLanguage);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCv;
    _cv = (initial != null && !initial.isSample)
        ? initial
        : CvModel.createEmpty(LocalizationService.currentLocale);
    _cvLanguage = _cv.targetLanguage ?? LocalizationService.currentLocale;
    _tabController = TabController(length: 13, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);

    _nameController = TextEditingController(text: _cv.fullName);
    _titleController = TextEditingController(text: _cv.jobTitle);
    _emailController = TextEditingController(text: _cv.email);
    _phoneController = TextEditingController(text: _cv.phone);
    _locationController = TextEditingController(text: _cv.location);
    _linkedinController = TextEditingController(text: _cv.linkedin);
    _githubController = TextEditingController(text: _cv.github);
    _portfolioController = TextEditingController(text: _cv.portfolioUrl);
    _summaryController = TextEditingController(text: _cv.summary);
    _aiPromptController.clear();
    _lastLocale = LocalizationService.currentLocale;
    _loadUserSavedCv();
    AuthService.currentUserNotifier.addListener(_onAuthUserChanged);
  }

  void _onAuthUserChanged() {
    if (mounted) {
      _loadUserSavedCv();
    }
  }

  Future<void> _loadUserSavedCv() async {
    if (widget.initialCv != null) return;
    try {
      final saved = await CvStorageService.loadActiveCv();
      if (!saved.isSample &&
          mounted &&
          (saved.fullName.isNotEmpty ||
              saved.experiences.any((e) => e.company.isNotEmpty))) {
        setState(() {
          _cv = saved;
          if (saved.targetLanguage != null &&
              saved.targetLanguage!.isNotEmpty) {
            _cvLanguage = saved.targetLanguage!;
          }
          _nameController.text = _cv.fullName;
          _titleController.text = _cv.jobTitle;
          _emailController.text = _cv.email;
          _phoneController.text = _cv.phone;
          _locationController.text = _cv.location;
          _linkedinController.text = _cv.linkedin;
          _githubController.text = _cv.github;
          _portfolioController.text = _cv.portfolioUrl;
          _summaryController.text = _cv.summary;
        });
      } else if (mounted) {
        setState(() {
          _cv = saved;
          _cvLanguage =
              saved.targetLanguage ?? LocalizationService.currentLocale;
          _nameController.text = '';
          _titleController.text = '';
          _emailController.text = '';
          _phoneController.text = '';
          _locationController.text = '';
          _linkedinController.text = '';
          _githubController.text = '';
          _portfolioController.text = '';
          _summaryController.text = '';
        });
      }
    } catch (_) {}
  }

  String _lastLocale = 'en';

  void _onTabChanged() {
    FocusScope.of(context).unfocus();
    if (mounted) setState(() {});
  }

  void _onLocaleChanged(String newLocale) {
    if (_lastLocale != newLocale) {
      _lastLocale = newLocale;
      setState(() {
        _refreshLocalizedCvLabels();
      });
    }
  }

  void _refreshLocalizedCvLabels() {
    for (final skill in _cv.skills) {
      skill.levelLabel = _getSkillLabel(skill.level);
    }
    for (final language in _cv.languages) {
      language.level =
          LocalizationService.normalizeLanguageLevel(language.level);
    }
    for (final section in _cv.customSections) {
      section.title =
          LocalizationService.localizePresetCustomSectionTitle(section.title);
    }
  }

  @override
  void dispose() {
    AuthService.currentUserNotifier.removeListener(_onAuthUserChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _summaryController.dispose();
    _aiPromptController.dispose();
    _skillInputController.dispose();
    _traitInputController.dispose();
    _newSectionTitleController.dispose();
    super.dispose();
  }

  void _syncCvData() {
    _cv.targetLanguage = _cvLanguage;
    _cv.fullName = _nameController.text;
    _cv.jobTitle = _titleController.text;
    _cv.email = _emailController.text;
    _cv.phone = _phoneController.text;
    _cv.location = _locationController.text;
    _cv.linkedin = _linkedinController.text;
    _cv.github = _githubController.text;
    _cv.portfolioUrl = _portfolioController.text;
    _cv.summary = _summaryController.text;
    _refreshLocalizedCvLabels();
    CvStorageService.saveActiveCv(_cv);
  }

  void _navigateToPreview() {
    _syncCvData();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CvPreviewScreen(cv: _cv),
      ),
    );
  }

  int _calculateAtsScore() {
    _cv.fullName = _nameController.text;
    _cv.jobTitle = _titleController.text;
    _cv.email = _emailController.text;
    _cv.phone = _phoneController.text;
    _cv.location = _locationController.text;
    _cv.summary = _summaryController.text;
    return _cv.calculateAtsScore();
  }

  int _filledItemsCount() {
    final expCount = _cv.experiences
        .where(
            (e) => e.company.trim().isNotEmpty || e.position.trim().isNotEmpty)
        .length;
    final eduCount = _cv.educations
        .where((e) => e.school.trim().isNotEmpty || e.field.trim().isNotEmpty)
        .length;
    final skillCount = _cv.skills.where((s) => s.name.trim().isNotEmpty).length;
    final certCount =
        _cv.certificates.where((c) => c.name.trim().isNotEmpty).length;
    final projCount =
        _cv.projects.where((p) => p.name.trim().isNotEmpty).length;
    final langCount =
        _cv.languages.where((l) => l.language.trim().isNotEmpty).length;
    return expCount + eduCount + skillCount + certCount + projCount + langCount;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.localeNotifier,
      builder: (context, currentLoc, __) {
        if (_lastLocale != currentLoc) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _onLocaleChanged(currentLoc),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
        final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final textColor =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subColor =
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final borderColor =
            isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final atsScore = _calculateAtsScore();

        return Scaffold(
          backgroundColor: bg,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
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
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 15,
                            color: textColor,
                          ),
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
            titleSpacing:
                (Navigator.of(context).canPop() || widget.onReturnHome != null)
                    ? 0
                    : 16,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocalizationService.tr('cv_builder_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: _navigateToPreview,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6.5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 72),
                          child: Text(
                            LocalizationService.tr('cv_preview_btn'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141724) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF262D42)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            atsScore >= 80
                                ? Icons.verified_rounded
                                : (atsScore >= 40
                                    ? Icons.offline_bolt_rounded
                                    : Icons.info_outline_rounded),
                            size: 14,
                            color: atsScore >= 80
                                ? AppColors.accentEmerald
                                : (atsScore >= 40
                                    ? AppColors.accentAmber
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${LocalizationService.tr('cv_ats_score')}: %$atsScore',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: atsScore / 100,
                                backgroundColor: isDark
                                    ? const Color(0xFF242738)
                                    : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  atsScore >= 80
                                      ? AppColors.accentEmerald
                                      : (atsScore >= 40
                                          ? AppColors.accentAmber
                                          : (isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8))),
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2336)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_filledItemsCount()}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: subColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141826) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF262D42)
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.25 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _tabController.animation ?? _tabController,
                        builder: (context, _) {
                          final double animValue =
                              _tabController.animation?.value ??
                                  _tabController.index.toDouble();
                          final bool isPersonalActive =
                              _tabController.indexIsChanging
                                  ? (_tabController.index == 1)
                                  : (animValue > 0.5 && animValue < 1.5);

                          return TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            onTap: (_) => FocusScope.of(context).unfocus(),
                            indicator: BoxDecoration(
                              gradient: isPersonalActive
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6), // Violet
                                        Color(0xFFEC4899), // Pink
                                        Color(0xFFF43F5E), // Rose
                                        Color(0xFFFB923C), // Amber/Orange
                                        Color(0xFF06B6D4), // Cyan
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : AppColors.blueGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: isPersonalActive
                                      ? const Color(0xFFEC4899)
                                          .withValues(alpha: 0.45)
                                      : const Color(0xFF2563EB)
                                          .withValues(alpha: 0.35),
                                  blurRadius: isPersonalActive ? 10 : 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              letterSpacing: 0,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                            padding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            tabs: [
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.file_present_rounded,
                                        size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_file')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_rounded, size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_personal')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.work_rounded, size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_experience')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school_rounded, size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_education')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_skills')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_traits')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.language_rounded,
                                        size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_languages')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.rocket_launch_rounded,
                                        size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_projects')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded,
                                        size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_certificates')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.people_alt_rounded,
                                        size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_references')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_circle_outline_rounded,
                                        size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_custom')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_vert_rounded,
                                        size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_ordering')),
                                  ],
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.palette_rounded, size: 17),
                                    const SizedBox(width: 7),
                                    Text(_cvTr('cv_tab_template')),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAiGeneratorTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildPersonalTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildExperienceTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildEducationTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildSkillsTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildPersonalTraitsTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildLanguagesTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildProjectsTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildCertificatesTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildReferencesTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildCustomSectionsTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildSectionOrderingTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                        _buildTemplateAndThemeTab(
                            isDark, cardBg, borderColor, textColor, subColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // TAB 1: PERSONAL
  Widget _buildPersonalTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Photo & ATS Format Toggle Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickProfilePhotoFromGallery,
                    child: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _cv.profilePhotoBytes == null
                                ? AppColors.blueGradient
                                : null,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF93C5FD), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _cv.profilePhotoBytes != null
                              ? ClipOval(
                                  child: Image.memory(
                                    _cv.profilePhotoBytes!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _cvTr('cv_photo'),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textColor),
                            ),
                            if (_cv.profilePhotoBytes != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accentEmerald
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _cvTr('success').toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accentEmerald),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cv.hasPhoto
                              ? _cvTr('cv_photo_pick')
                              : _cvTr('cv_photo_ats'),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: subColor),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _cv.hasPhoto,
                    activeThumbColor: AppColors.accentEmerald,
                    activeTrackColor:
                        AppColors.accentEmerald.withValues(alpha: 0.4),
                    onChanged: (val) => setState(() => _cv.hasPhoto = val),
                  ),
                ],
              ),
              if (_cv.hasPhoto) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickProfilePhotoFromGallery,
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: Text(
                          _cv.profilePhotoBytes == null
                              ? _cvTr('cv_photo_pick')
                              : _cvTr('cv_photo'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (_cv.profilePhotoBytes != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: LocalizationService.tr('delete'),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.accentRose, size: 20),
                        onPressed: () {
                          setState(() {
                            _cv.profilePhotoBytes = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Primary Info Group Card with Aurora Glow
        AiAuroraGlowCard(
          isGlowing: _glowingItemKeys.contains('personal'),
          onDismissGlow: () =>
              setState(() => _glowingItemKeys.remove('personal')),
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
                  blurRadius: 12,
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _cvTr('cv_tab_personal'),
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(_cvTr('cv_name'), _nameController,
                    Icons.badge_outlined, isDark,
                    hint: _cvTr('hint_full_name')),
                _buildTextField(_cvTr('cv_job_title'), _titleController,
                    Icons.work_outline_rounded, isDark,
                    hint: _cvTr('hint_position')),
                _buildTextField(_cvTr('cv_email'), _emailController,
                    Icons.mail_outline_rounded, isDark,
                    hint: _cvTr('hint_email')),
                _buildTextField(_cvTr('cv_phone'), _phoneController,
                    Icons.phone_outlined, isDark,
                    hint: _cvTr('hint_phone')),
                _buildTextField(_cvTr('cv_location'), _locationController,
                    Icons.location_on_outlined, isDark,
                    hint: _cvTr('hint_location')),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Social & Portfolio Links Group Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.link_rounded,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _cvTr('cv_links_social'),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(_cvTr('cv_linkedin'), _linkedinController,
                  Icons.business_center_outlined, isDark,
                  hint: _cvTr('hint_linkedin')),
              _buildTextField(_cvTr('cv_github'), _githubController,
                  Icons.code_rounded, isDark,
                  hint: _cvTr('hint_github')),
              _buildTextField(_cvTr('cv_website'), _portfolioController,
                  Icons.language_rounded, isDark,
                  hint: _cvTr('hint_portfolio')),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Summary Group Card with Aurora Glow & Typing Indicator
        AiAuroraGlowCard(
          isGlowing:
              _glowingItemKeys.contains('summary') || _isTypewritingSummary,
          onDismissGlow: () =>
              setState(() => _glowingItemKeys.remove('summary')),
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
                  blurRadius: 12,
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _cvTr('cv_summary'),
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: textColor),
                      ),
                    ),
                    if (_isTypewritingSummary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              LocalizationService.tr('cv_ai_typing'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _cvTr('cv_summary'),
                  _summaryController,
                  Icons.notes_rounded,
                  isDark,
                  maxLines: null,
                  minLines: 5,
                  hint: _cvTr('cv_hint_summary'),
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF7C3AED).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isAiGenerating ? null : _handleVoiceToCv,
                        icon: const Icon(Icons.mic_rounded,
                            size: 18, color: Colors.white),
                        label: Text(
                          LocalizationService.tr('cv_ai_voice_btn'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAiGenerateButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 2: WORK EXPERIENCES (SEAMLESS PRO CARD)
  Widget _buildExperienceTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${_cvTr('cv_experiences_title')} (${_cv.experiences.length})',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  Text(_cvTr('cv_experiences_sub'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: subColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cv.experiences.add(
                    WorkExperience(
                      company: '',
                      position: '',
                      startDate: '',
                      endDate: '',
                      description: '',
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocalizationService.tr('add'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._cv.experiences.asMap().entries.map((entry) {
          final index = entry.key;
          final exp = entry.value;
          final isGlowing = _glowingItemKeys.contains('experience_$index');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AiAuroraGlowCard(
              isGlowing: isGlowing,
              onDismissGlow: () =>
                  setState(() => _glowingItemKeys.remove('experience_$index')),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 12,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '💼 #${index + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            exp.position.isNotEmpty
                                ? exp.position
                                : _cvTr('cv_new_experience'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.accentRose, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => _cv.experiences.removeAt(index)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildModernInput(
                      label: _cvTr('cv_exp_position'),
                      initialValue: exp.position,
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                      hint: _cvTr('hint_position'),
                      onChanged: (val) => exp.position = val,
                    ),
                    const SizedBox(height: 8),
                    _buildModernInput(
                      label: _cvTr('cv_exp_company'),
                      initialValue: exp.company,
                      icon: Icons.business_rounded,
                      isDark: isDark,
                      hint: _cvTr('hint_company'),
                      onChanged: (val) => exp.company = val,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernInput(
                            label: _cvTr('cv_exp_start_year'),
                            initialValue: exp.startDate,
                            icon: Icons.calendar_today_rounded,
                            isDark: isDark,
                            hint: '2021',
                            onChanged: (val) => exp.startDate = val,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModernInput(
                            label: _cvTr('cv_exp_end_year'),
                            initialValue: exp.endDate,
                            icon: Icons.event_available_rounded,
                            isDark: isDark,
                            hint: _cvTr('cv_present'),
                            onChanged: (val) => exp.endDate = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildModernInput(
                      label: _cvTr('cv_exp_desc'),
                      initialValue: exp.description,
                      icon: Icons.subject_rounded,
                      isDark: isDark,
                      maxLines: 6,
                      hint: _cvTr('cv_hint_exp_desc'),
                      onChanged: (val) => exp.description = val,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // TAB 3: EDUCATIONS (SEAMLESS PRO CARD WITH GPA)
  Widget _buildEducationTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${_cvTr('cv_educations_title')} (${_cv.educations.length})',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  Text(_cvTr('cv_educations_sub'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: subColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cv.educations.add(
                    Education(
                      school: '',
                      degree: '',
                      field: '',
                      startDate: '',
                      endDate: '',
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocalizationService.tr('add'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._cv.educations.asMap().entries.map((entry) {
          final index = entry.key;
          final edu = entry.value;
          final isGlowing = _glowingItemKeys.contains('education_$index');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AiAuroraGlowCard(
              isGlowing: isGlowing,
              onDismissGlow: () =>
                  setState(() => _glowingItemKeys.remove('education_$index')),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 12,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accentEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🎓 #${index + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentEmerald),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            edu.school.isNotEmpty
                                ? edu.school
                                : _cvTr('cv_new_education'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.accentRose, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => _cv.educations.removeAt(index)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildModernInput(
                      label: _cvTr('cv_edu_school'),
                      initialValue: edu.school,
                      icon: Icons.school_outlined,
                      isDark: isDark,
                      hint: _cvTr('hint_school'),
                      onChanged: (val) => edu.school = val,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernInput(
                            label: _cvTr('cv_edu_degree'),
                            initialValue: edu.degree,
                            icon: Icons.workspace_premium_outlined,
                            isDark: isDark,
                            hint: _cvTr('hint_degree'),
                            onChanged: (val) => edu.degree = val,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModernInput(
                            label: _cvTr('cv_edu_field'),
                            initialValue: edu.field,
                            icon: Icons.menu_book_outlined,
                            isDark: isDark,
                            hint: _cvTr('hint_field'),
                            onChanged: (val) => edu.field = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernInput(
                            label: _cvTr('cv_edu_start'),
                            initialValue: edu.startDate,
                            icon: Icons.calendar_today_rounded,
                            isDark: isDark,
                            hint: '2016',
                            onChanged: (val) => edu.startDate = val,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModernInput(
                            label: _cvTr('cv_edu_end'),
                            initialValue: edu.endDate,
                            icon: Icons.event_available_rounded,
                            isDark: isDark,
                            hint: '2020',
                            onChanged: (val) => edu.endDate = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildModernInput(
                      label: _cvTr('cv_edu_gpa'),
                      initialValue: edu.gpa,
                      icon: Icons.grade_rounded,
                      isDark: isDark,
                      hint: _cvTr('hint_gpa'),
                      onChanged: (val) => edu.gpa = val,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // TAB 4: SKILLS (PRO CARD & QUICK PRESETS)
  Widget _buildSkillsTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Header info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded,
                    size: 20, color: AppColors.accentAmber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_cvTr('cv_tab_skills')} (${_cv.skills.length})',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                    ),
                    Text(
                      _cvTr('cv_skills_sub'),
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Quick Suggestion Chips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚡ ${_cvTr('cv_popular_skills')}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSkills.map((skillName) {
                  final alreadyAdded = _cv.skills.any(
                      (s) => s.name.toLowerCase() == skillName.toLowerCase());
                  return GestureDetector(
                    onTap: () {
                      if (!alreadyAdded) {
                        setState(() {
                          _cv.skills.add(SkillItem(
                              name: skillName,
                              level: 85,
                              levelLabel: _getSkillLabel(85)));
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: alreadyAdded
                            ? (isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFECFDF5))
                            : (isDark
                                ? const Color(0xFF1B2032)
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: alreadyAdded
                              ? AppColors.accentEmerald
                              : (isDark
                                  ? const Color(0xFF38415C)
                                  : const Color(0xFFCBD5E1)),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            alreadyAdded
                                ? Icons.check_circle_rounded
                                : Icons.add_rounded,
                            size: 15,
                            color: alreadyAdded
                                ? AppColors.accentEmerald
                                : subColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            skillName,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: alreadyAdded
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: alreadyAdded
                                  ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF065F46))
                                  : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Add Skill Input Card with Slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _cvTr('cv_add_custom_skill'),
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillInputController,
                      scrollPadding: const EdgeInsets.only(bottom: 140),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _cvTr('hint_custom_skill'),
                        hintStyle: TextStyle(
                            color: subColor.withValues(alpha: 0.65),
                            fontSize: 12.5),
                        prefixIcon: Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1B2032)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF38415C)
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF2563EB), width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      final name = _skillInputController.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          _cv.skills.add(SkillItem(
                            name: name,
                            level: _newSkillLevel.round(),
                            levelLabel: _getSkillLabel(_newSkillLevel.round()),
                          ));
                          _skillInputController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(LocalizationService.tr('add'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_cvTr('cv_skill_level'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: subColor)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '%${_newSkillLevel.round()} (${_getSkillLabel(_newSkillLevel.round())})',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppColors.primary,
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: _newSkillLevel,
                  min: 20,
                  max: 100,
                  divisions: 16,
                  inactiveColor: isDark
                      ? const Color(0xFF2E344A)
                      : const Color(0xFFCBD5E1),
                  onChanged: (val) => setState(() => _newSkillLevel = val),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Added Skills List
        if (_cv.skills.isEmpty)
          _buildEmptyState(
              _cvTr('cv_empty_skills'), Icons.bolt_outlined, isDark, subColor),

        ..._cv.skills.asMap().entries.map((entry) {
          final idx = entry.key;
          final skill = entry.value;
          final isGlowing = idx == 0 && _glowingItemKeys.contains('skills');

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AiAuroraGlowCard(
              isGlowing: isGlowing,
              onDismissGlow: () =>
                  setState(() => _glowingItemKeys.remove('skills')),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 210),
                                child: Text(
                                  skill.name,
                                  softWrap: true,
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: textColor),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '%${skill.level} (${_getSkillLabel(skill.level)})',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: skill.level / 100,
                              backgroundColor: isDark
                                  ? const Color(0xFF242738)
                                  : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.accentRose, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _cv.skills.removeAt(idx)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // TAB 5: PERSONAL TRAITS / KİŞİSEL ÖZELLİKLER & NİTELİKLER
  Widget _buildPersonalTraitsTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Header Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_rounded,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cvTr('cv_soft_skills_title'),
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: textColor),
                        ),
                        Text(
                          _cvTr('cv_soft_skills_sub'),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: subColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Quick Suggestion Pill Grid Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 18, color: AppColors.accentAmber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _cvTr('cv_ready_traits_pool'),
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTraits.map((trait) {
                  final alreadyAdded = _cv.personalTraits.contains(trait);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (alreadyAdded) {
                          _cv.personalTraits.remove(trait);
                        } else {
                          _cv.personalTraits.add(trait);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: alreadyAdded
                            ? (isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFECFDF5))
                            : (isDark
                                ? const Color(0xFF1B2032)
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: alreadyAdded
                              ? AppColors.accentEmerald
                              : (isDark
                                  ? const Color(0xFF38415C)
                                  : const Color(0xFFCBD5E1)),
                          width: alreadyAdded ? 1.5 : 1.2,
                        ),
                        boxShadow: [
                          if (alreadyAdded)
                            BoxShadow(
                              color: AppColors.accentEmerald
                                  .withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            alreadyAdded
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 16,
                            color: alreadyAdded
                                ? (isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669))
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            trait,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: alreadyAdded
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: alreadyAdded
                                  ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF065F46))
                                  : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Custom Trait Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_task_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _cvTr('cv_add_custom_trait'),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _traitInputController,
                      scrollPadding: const EdgeInsets.only(bottom: 140),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _cvTr('hint_custom_trait'),
                        hintStyle: TextStyle(
                            color: subColor.withValues(alpha: 0.65),
                            fontSize: 12.5),
                        prefixIcon: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1B2032)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF38415C)
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF2563EB), width: 2.0),
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty &&
                            !_cv.personalTraits.contains(val.trim())) {
                          setState(() {
                            _cv.personalTraits.add(val.trim());
                            _traitInputController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      final text = _traitInputController.text.trim();
                      if (text.isNotEmpty &&
                          !_cv.personalTraits.contains(text)) {
                        setState(() {
                          _cv.personalTraits.add(text);
                          _traitInputController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(LocalizationService.tr('add'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Added Traits Display Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_cvTr('cv_selected_traits')} (${_cv.personalTraits.length})',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: textColor),
                  ),
                  if (_cv.personalTraits.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setState(() => _cv.personalTraits.clear()),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30)),
                      child: Text(_cvTr('cv_clear_all'),
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.accentRose,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_cv.personalTraits.isEmpty)
                _buildEmptyState(_cvTr('cv_empty_traits'),
                    Icons.psychology_outlined, isDark, subColor),
              LayoutBuilder(builder: (context, constraints) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cv.personalTraits.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final trait = entry.value;
                    return ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1B2032)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF38415C)
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                trait,
                                softWrap: true,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: textColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _cv.personalTraits.removeAt(idx)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentRose
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 13, color: AppColors.accentRose),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _getSkillLabel(int level) {
    if (level >= 90) return _cvTr('skill_expert');
    if (level >= 75) return _cvTr('skill_advanced');
    if (level >= 50) return _cvTr('skill_intermediate');
    return _cvTr('skill_basic');
  }

  // TAB 6: FOREIGN LANGUAGES (SEAMLESS PRO CARD)
  Widget _buildLanguagesTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${_cvTr('cv_languages_title')} (${_cv.languages.length})',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  Text(_cvTr('cv_languages_sub'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: subColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cv.languages.add(LanguageItem(
                      language: '', level: _cvTr('cv_default_lang_level')));
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocalizationService.tr('add'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._cv.languages.asMap().entries.map((entry) {
          final index = entry.key;
          final lang = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🌐 #${index + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lang.language.isNotEmpty
                                  ? lang.language
                                  : _cvTr('cv_new_language'),
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.accentRose, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _cv.languages.removeAt(index)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildModernInput(
                  label: _cvTr('cv_lang_name'),
                  initialValue: lang.language,
                  icon: Icons.language_rounded,
                  isDark: isDark,
                  hint: _cvTr('hint_language_name'),
                  onChanged: (val) => lang.language = val,
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cvTr('cv_lang_level'),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: subColor,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                          'lang_lvl_${index}_${_cvLanguage}_${LocalizationService.normalizeLanguageLevel(lang.level, _cvLanguage)}'),
                      initialValue: LocalizationService.normalizeLanguageLevel(
                          lang.level, _cvLanguage),
                      dropdownColor: cardBg,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1B2032)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF38415C)
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF2563EB), width: 2.0),
                        ),
                      ),
                      items: _languageLevels.map((lvl) {
                        return DropdownMenuItem(
                          value: lvl,
                          child: Text(lvl,
                              style: TextStyle(color: textColor, fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => lang.level = val);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // TAB 7: PROJECTS (SEAMLESS PRO CARD)
  Widget _buildProjectsTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_cvTr('cv_projects_title')} (${_cv.projects.length})',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  Text(_cvTr('cv_projects_sub'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: subColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cv.projects.add(ProjectItem(
                    name: '',
                    role: '',
                    description: '',
                    technologies: '',
                  ));
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocalizationService.tr('add'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._cv.projects.asMap().entries.map((entry) {
          final index = entry.key;
          final proj = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentEmerald
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🚀 #${index + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accentEmerald),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              proj.name.isNotEmpty
                                  ? proj.name
                                  : _cvTr('cv_new_project'),
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.accentRose, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _cv.projects.removeAt(index)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildModernInput(
                  label: _cvTr('cv_proj_title'),
                  initialValue: proj.name,
                  icon: Icons.title_rounded,
                  isDark: isDark,
                  hint: _cvTr('hint_project_title'),
                  onChanged: (val) => proj.name = val,
                ),
                const SizedBox(height: 8),
                _buildModernInput(
                  label: _cvTr('cv_proj_tech'),
                  initialValue: proj.technologies,
                  icon: Icons.code_rounded,
                  isDark: isDark,
                  hint: _cvTr('hint_project_tech'),
                  onChanged: (val) => proj.technologies = val,
                ),
                const SizedBox(height: 8),
                _buildModernInput(
                  label: _cvTr('cv_proj_desc'),
                  initialValue: proj.description,
                  icon: Icons.subject_rounded,
                  isDark: isDark,
                  maxLines: null,
                  minLines: 2,
                  hint: _cvTr('cv_hint_project_desc'),
                  onChanged: (val) => proj.description = val,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // TAB: CERTIFICATES & LICENSES (SEAMLESS PRO CARD)
  Widget _buildCertificatesTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${_cvTr('cv_certificates_title')} (${_cv.certificates.length})',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  Text(
                    _cvTr('cv_certificates_sub'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: subColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cv.certificates.add(CertificateItem(
                    name: '',
                    issuer: '',
                    date: '',
                    credentialUrl: '',
                  ));
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocalizationService.tr('add'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_cv.certificates.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 40, color: subColor.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                Text(
                  _cvTr('cv_certificates_sub'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ..._cv.certificates.asMap().entries.map((entry) {
          final index = entry.key;
          final cert = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEAB308).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🏅 #${index + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 190),
                          child: Text(
                            cert.name.isNotEmpty
                                ? cert.name
                                : _cvTr('cv_new_certificate'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.accentRose, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _cv.certificates.removeAt(index)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildModernInput(
                  label: _cvTr('cv_cert_name'),
                  initialValue: cert.name,
                  icon: Icons.workspace_premium_outlined,
                  isDark: isDark,
                  hint: _cvTr('hint_cert_name'),
                  onChanged: (val) => cert.name = val,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernInput(
                        label: _cvTr('cv_cert_issuer'),
                        initialValue: cert.issuer,
                        icon: Icons.business_rounded,
                        isDark: isDark,
                        hint: _cvTr('hint_cert_issuer'),
                        onChanged: (val) => cert.issuer = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModernInput(
                        label: _cvTr('cv_cert_date'),
                        initialValue: cert.date,
                        icon: Icons.calendar_today_rounded,
                        isDark: isDark,
                        hint: _cvTr('hint_cert_date'),
                        onChanged: (val) => cert.date = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildModernInput(
                  label: _cvTr('cv_cert_url'),
                  initialValue: cert.credentialUrl,
                  icon: Icons.link_rounded,
                  isDark: isDark,
                  hint: _cvTr('hint_cert_url'),
                  onChanged: (val) => cert.credentialUrl = val,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // TAB 9: REFERENCES (SEAMLESS PRO CARD)
  Widget _buildReferencesTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${_cvTr('cv_references_title')} (${_cv.references.length})',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  Text(
                    _cvTr('cv_references_sub'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: subColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cv.references.add(ReferenceItem(
                    name: '',
                    position: '',
                    company: '',
                    phone: '',
                    email: '',
                  ));
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocalizationService.tr('add'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._cv.references.asMap().entries.map((entry) {
          final index = entry.key;
          final ref = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '👤 #${index + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ref.name.isNotEmpty
                                  ? ref.name
                                  : _cvTr('cv_new_reference'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.accentRose, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _cv.references.removeAt(index)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildModernInput(
                  label: _cvTr('cv_ref_name'),
                  initialValue: ref.name,
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  hint: _cvTr('hint_ref_name'),
                  onChanged: (val) => ref.name = val,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernInput(
                        label: _cvTr('cv_ref_position'),
                        initialValue: ref.position,
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                        hint: _cvTr('hint_ref_position'),
                        onChanged: (val) => ref.position = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModernInput(
                        label: _cvTr('cv_ref_company'),
                        initialValue: ref.company,
                        icon: Icons.business_rounded,
                        isDark: isDark,
                        hint: _cvTr('hint_ref_company'),
                        onChanged: (val) => ref.company = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernInput(
                        label: _cvTr('cv_ref_phone'),
                        initialValue: ref.phone,
                        icon: Icons.phone_outlined,
                        isDark: isDark,
                        hint: _cvTr('hint_ref_phone'),
                        onChanged: (val) => ref.phone = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModernInput(
                        label: _cvTr('cv_ref_email'),
                        initialValue: ref.email,
                        icon: Icons.mail_outline_rounded,
                        isDark: isDark,
                        hint: _cvTr('hint_ref_email'),
                        onChanged: (val) => ref.email = val,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // TAB 9: CUSTOM SECTIONS (SEAMLESS PRO CARD)
  Widget _buildCustomSectionsTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          '${_cvTr('cv_custom_sections_title')} (${_cv.customSections.length})',
          style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w800, color: textColor),
        ),
        Text(
          _cvTr('cv_custom_sections_sub'),
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w600, color: subColor),
        ),
        const SizedBox(height: 12),

        // Quick Preset Title Chips
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _quickCustomTitles.length,
            itemBuilder: (context, i) {
              final title = _quickCustomTitles[i];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _cv.customSections.add(
                      CustomCvSection(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title
                            .replaceAll(
                                RegExp(
                                    r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1FA00}-\u{1FAFF}]|[\u{2300}-\u{23FF}]|[\u{FE00}-\u{FE0F}]|[\u{200D}]',
                                    unicode: true),
                                '')
                            .trim(),
                        items: [LocalizationService.tr('cv_default_bullet')],
                      ),
                    );
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B2032)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newSectionTitleController,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: _cvTr('hint_custom_section_title'),
                  hintStyle: TextStyle(
                      color: subColor.withValues(alpha: 0.65), fontSize: 12.5),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1B2032)
                      : const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF38415C)
                          : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_newSectionTitleController.text.trim().isNotEmpty) {
                    setState(() {
                      _cv.customSections.add(
                        CustomCvSection(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: _newSectionTitleController.text.trim(),
                          items: [_cvTr('cv_default_bullet_short')],
                        ),
                      );
                      _newSectionTitleController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 16),
                label: Text(_cvTr('cv_create_section'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ..._cv.customSections.asMap().entries.map((entry) {
          final sectionIndex = entry.key;
          final sec = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sec.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryLight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              color: AppColors.accentEmerald, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(
                              () => sec.items.add(_cvTr('cv_new_bullet'))),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.accentRose, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(
                              () => _cv.customSections.removeAt(sectionIndex)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sec.items.asMap().entries.map((itemEntry) {
                  final itemIndex = itemEntry.key;
                  final itemText = itemEntry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: itemText,
                            scrollPadding: const EdgeInsets.only(bottom: 140),
                            style: TextStyle(
                                color: textColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1B2032)
                                  : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF38415C)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2563EB), width: 2.0),
                              ),
                            ),
                            onChanged: (val) => sec.items[itemIndex] = val,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.accentRose),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => sec.items.removeAt(itemIndex)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // TAB 10: SECTION ORDERING (PRO DRAG & DROP)
  Widget _buildSectionOrderingTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_vert_circle_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _cvTr('cv_ordering_title'),
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _cvTr('cv_ordering_sub'),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: subColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final item = _cv.sectionOrder.removeAt(oldIndex);
              _cv.sectionOrder.insert(newIndex, item);
            });
          },
          children: _cv.sectionOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final sectionType = entry.value;

            return Container(
              key: ValueKey(sectionType),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
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
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(_getSectionIcon(sectionType),
                      color: AppColors.primaryLight, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getSectionTitle(sectionType),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                    ),
                  ),
                  Icon(Icons.drag_handle_rounded, color: subColor, size: 20),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getSectionTitle(CvSectionType type) {
    switch (type) {
      case CvSectionType.summary:
        return _cvTr('cv_summary');
      case CvSectionType.experiences:
        return _cvTr('cv_experiences_title');
      case CvSectionType.educations:
        return _cvTr('cv_educations_title');
      case CvSectionType.skills:
        return _cvTr('cv_tab_skills');
      case CvSectionType.personalTraits:
        return _cvTr('cv_soft_skills_title');
      case CvSectionType.languages:
        return _cvTr('cv_languages_title');
      case CvSectionType.projects:
        return _cvTr('cv_projects_title');
      case CvSectionType.certificates:
        return _cvTr('cv_certificates_title');
      case CvSectionType.references:
        return _cvTr('cv_references_title');
      case CvSectionType.customSections:
        return _cvTr('cv_custom_sections_title');
    }
  }

  IconData _getSectionIcon(CvSectionType type) {
    switch (type) {
      case CvSectionType.summary:
        return Icons.notes_rounded;
      case CvSectionType.experiences:
        return Icons.work_outline_rounded;
      case CvSectionType.educations:
        return Icons.school_outlined;
      case CvSectionType.skills:
        return Icons.bolt_rounded;
      case CvSectionType.personalTraits:
        return Icons.auto_awesome_rounded;
      case CvSectionType.languages:
        return Icons.translate_rounded;
      case CvSectionType.projects:
        return Icons.rocket_launch_outlined;
      case CvSectionType.certificates:
        return Icons.workspace_premium_outlined;
      case CvSectionType.references:
        return Icons.people_outline_rounded;
      case CvSectionType.customSections:
        return Icons.playlist_add_rounded;
    }
  }

  // TAB 11: TEMPLATE & THEME STUDIO
  Widget _buildTemplateAndThemeTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Current Selected Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(_cv.primaryColorHex).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Color(_cv.primaryColorHex).withValues(alpha: 0.4),
                width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.palette_rounded,
                  color: Color(_cv.primaryColorHex), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_cvTr('cv_active_layout'),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: subColor)),
                    Text(
                      _getTemplateName(_cv.template),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _navigateToPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(_cv.primaryColorHex),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(_cvTr('cv_inspect_pdf'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          _cvTr('cv_template_title'),
          style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w800, color: textColor),
        ),
        const SizedBox(height: 10),

        _buildTemplateCard(
          title: _cvTr('template_sidebar_modern'),
          subtitle: _cvTr('cv_tpl_subtitle_modern'),
          template: CvTemplate.sidebarModern,
          badge: _cvTr('cv_tpl_badge_popular'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_modern_tech'),
          subtitle: _cvTr('cv_tpl_subtitle_tech'),
          template: CvTemplate.modernTech,
          badge: _cvTr('cv_tpl_badge_ats'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_executive_classic'),
          subtitle: _cvTr('cv_tpl_subtitle_exec'),
          template: CvTemplate.executiveClassic,
          badge: _cvTr('cv_tpl_badge_exec'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_creative_designer'),
          subtitle: _cvTr('cv_tpl_subtitle_design'),
          template: CvTemplate.creativeDesigner,
          badge: _cvTr('cv_tpl_badge_design'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_minimalist_pure'),
          subtitle: _cvTr('cv_tpl_subtitle_elegant'),
          template: CvTemplate.minimalistPure,
          badge: _cvTr('cv_tpl_badge_elegant'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_harvard_academic'),
          subtitle: _cvTr('cv_tpl_subtitle_academic'),
          template: CvTemplate.harvardAcademic,
          badge: _cvTr('cv_tpl_badge_academic'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_compact_grid'),
          subtitle: _cvTr('cv_tpl_subtitle_engineering'),
          template: CvTemplate.compactGrid,
          badge: _cvTr('cv_tpl_badge_engineering'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_infographic_modern'),
          subtitle: _cvTr('cv_tpl_subtitle_metric'),
          template: CvTemplate.infographicModern,
          badge: _cvTr('cv_tpl_badge_metric'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_corporate_gold'),
          subtitle: _cvTr('cv_tpl_subtitle_luxury'),
          template: CvTemplate.corporateGold,
          badge: _cvTr('cv_tpl_badge_luxury'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_clean_nordic'),
          subtitle: _cvTr('cv_tpl_subtitle_nordic'),
          template: CvTemplate.cleanNordic,
          badge: _cvTr('cv_tpl_badge_nordic'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_elite_executive'),
          subtitle: _cvTr('template_elite_executive_desc'),
          template: CvTemplate.eliteExecutive,
          badge: _cvTr('cv_tpl_badge_exec'),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTemplateCard(
          title: _cvTr('template_silicon_tech'),
          subtitle: _cvTr('template_silicon_tech_desc'),
          template: CvTemplate.siliconTech,
          badge: _cvTr('cv_tpl_badge_engineering'),
          isDark: isDark,
        ),

        const SizedBox(height: 18),

        Text(
          _cvTr('cv_theme_title'),
          style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w800, color: textColor),
        ),
        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: _themePalette.length,
          itemBuilder: (context, index) {
            final item = _themePalette[index];
            final color = item['color'] as Color;
            final hex = item['hex'] as int;
            final name = item['name'] as String;
            final isSelected = _cv.primaryColorHex == hex;

            return GestureDetector(
              onTap: () => setState(() => _cv.primaryColorHex = hex),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: isSelected ? 2.0 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check,
                                  size: 10, color: Colors.white))
                          : null,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark && hex == 0xFF0F172A
                                  ? Colors.white
                                  : color)
                              : textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getTemplateName(CvTemplate template) {
    switch (template) {
      case CvTemplate.sidebarModern:
        return _cvTr('template_sidebar_modern');
      case CvTemplate.executiveClassic:
        return _cvTr('template_executive_classic');
      case CvTemplate.modernTech:
        return _cvTr('template_modern_tech');
      case CvTemplate.creativeDesigner:
        return _cvTr('template_creative_designer');
      case CvTemplate.minimalistPure:
        return _cvTr('template_minimalist_pure');
      case CvTemplate.harvardAcademic:
        return _cvTr('template_harvard_academic');
      case CvTemplate.compactGrid:
        return _cvTr('template_compact_grid');
      case CvTemplate.infographicModern:
        return _cvTr('template_infographic_modern');
      case CvTemplate.corporateGold:
        return _cvTr('template_corporate_gold');
      case CvTemplate.cleanNordic:
        return _cvTr('template_clean_nordic');
      case CvTemplate.eliteExecutive:
        return _cvTr('template_elite_executive');
      case CvTemplate.siliconTech:
        return _cvTr('template_silicon_tech');
    }
  }

  // Helper: Get template preview visual widget
  Widget _getTemplatePreviewVisual(CvTemplate template, bool isDark) {
    final accentColor = Color(_cv.primaryColorHex);
    const lightBg = Color(0xFFF1F5F9);
    const darkBg = Color(0xFF1E293B);
    final dividerColor =
        isDark ? const Color(0xFF2D3E52) : const Color(0xFFCBD5E1);

    switch (template) {
      case CvTemplate.sidebarModern:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  color: isDark ? darkBg : lightBg,
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1, thickness: 1),
                        Divider(height: 1, thickness: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case CvTemplate.executiveClassic:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 4,
                  width: 20,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Divider(height: 1, thickness: 0.8, color: dividerColor),
                const SizedBox(height: 3),
                Divider(height: 1, thickness: 0.8, color: dividerColor),
              ],
            ),
          ),
        );
      case CvTemplate.creativeDesigner:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.12),
                          accentColor.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case CvTemplate.minimalistPure:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: 2,
                    width: 18,
                    child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFF64748B)))),
                SizedBox(
                    height: 1.5,
                    width: 25,
                    child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFCBD5E1)))),
                SizedBox(
                    height: 1.5,
                    width: 20,
                    child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFCBD5E1)))),
              ],
            ),
          ),
        );
      case CvTemplate.harvardAcademic:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(height: 2, width: 22, color: accentColor),
                Container(height: 1, width: 30, color: dividerColor),
                Container(height: 1, width: 25, color: dividerColor),
              ],
            ),
          ),
        );
      case CvTemplate.compactGrid:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: [
                Container(color: accentColor.withValues(alpha: 0.2)),
                Container(color: accentColor.withValues(alpha: 0.1)),
                Container(color: accentColor.withValues(alpha: 0.1)),
                Container(color: accentColor.withValues(alpha: 0.2)),
              ],
            ),
          ),
        );
      case CvTemplate.modernTech:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 2, width: 24, color: accentColor),
                SizedBox(
                  height: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Container(
                            height: 1,
                            color: dividerColor,
                            margin: const EdgeInsets.symmetric(horizontal: 1)),
                      ),
                      Expanded(
                        child: Container(
                            height: 1,
                            color: dividerColor,
                            margin: const EdgeInsets.symmetric(horizontal: 1)),
                      ),
                      Expanded(
                        child: Container(
                            height: 1,
                            color: dividerColor,
                            margin: const EdgeInsets.symmetric(horizontal: 1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case CvTemplate.infographicModern:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 2,
                    backgroundColor: dividerColor,
                    valueColor: AlwaysStoppedAnimation(accentColor),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 2,
                    backgroundColor: dividerColor,
                    valueColor: AlwaysStoppedAnimation(
                        accentColor.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
        );
      case CvTemplate.corporateGold:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  border:
                      Border.all(color: isDark ? darkBg : lightBg, width: 1.5),
                ),
              ),
            ),
          ),
        );
      case CvTemplate.cleanNordic:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dividerColor, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 1.5, width: 16, color: const Color(0xFF64748B)),
                const SizedBox(height: 2),
                Container(height: 1, width: 24, color: dividerColor),
                Container(height: 1, width: 20, color: dividerColor),
              ],
            ),
          ),
        );
      case CvTemplate.eliteExecutive:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7),
                      bottomLeft: Radius.circular(7),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFD4AF37), width: 1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                          height: 1, width: 10, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Container(
                  color: isDark ? darkBg : lightBg,
                  padding: const EdgeInsets.all(3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 1.5,
                          width: 16,
                          color: const Color(0xFF0F172A)),
                      Container(height: 1, width: 18, color: dividerColor),
                      Container(height: 1, width: 14, color: dividerColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case CvTemplate.siliconTech:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0EA5E9), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                        height: 2, width: 16, color: const Color(0xFF0EA5E9)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Container(
                      height: 1, width: 26, color: const Color(0xFF0EA5E9)),
                ),
                Row(
                  children: [
                    Container(width: 4, height: 4, color: dividerColor),
                    const SizedBox(width: 2),
                    Container(height: 1, width: 16, color: dividerColor),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildTemplateCard({
    required String title,
    required String subtitle,
    required CvTemplate template,
    required String badge,
    required bool isDark,
  }) {
    final isSelected = _cv.template == template;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final primaryColor = Color(_cv.primaryColorHex);

    return GestureDetector(
      onTap: () => setState(() => _cv.template = template),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 14,
          vertical: isSelected ? 14 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.16),
                    primaryColor.withValues(alpha: 0.08),
                    cardBg,
                  ],
                )
              : null,
          color: cardBg,
          borderRadius: BorderRadius.circular(isSelected ? 20 : 16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
              spreadRadius: isSelected ? 0.5 : 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Premium Checkbox
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE8EEF7)),
                  borderRadius: BorderRadius.circular(isSelected ? 8 : 6),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFD1D5DB)),
                    width: isSelected ? 0 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                  size: isSelected ? 14 : 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Template Preview Visual
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: _getTemplatePreviewVisual(template, isDark),
            ),
            const SizedBox(width: 12),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: isSelected ? 14 : 13.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: isSelected ? 0.3 : 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(
                              alpha: isSelected ? 0.16 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: primaryColor.withValues(
                                alpha: isSelected ? 0.3 : 0.15,
                              ),
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 0: AI GENERATOR (Now File/Dosya Tab)
  Widget _buildAiGeneratorTab(bool isDark, Color cardBg, Color borderColor,
      Color textColor, Color subColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // File Import Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3147) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _cvTr('cv_tab_file'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildMultiModalAiBar(
                isDark: isDark,
                textColor: textColor,
                subColor: subColor,
                borderColor: borderColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAiGenerate() async {
    if (_isAiGenerating) return;
    final prompt = _summaryController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('cv_ai_prompt_placeholder')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAiGenerating = true);

    try {
      final enhancedText = await AiCvService.enhanceSummary(
        rawSummary: prompt,
        locale: LocalizationService.currentLocale,
      );

      if (!mounted) return;

      if (enhancedText != null && enhancedText.isNotEmpty) {
        setState(() {
          _summaryController.text = enhancedText;
          _cv.summary = enhancedText;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            content: Text(
              LocalizationService.tr('cv_ai_summary_updated'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text(
              LocalizationService.tr('cv_ai_request_failed'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text(
              LocalizationService.tr(
                  e is AiCvException ? e.messageKey : 'cv_ai_request_failed'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAiGenerating = false);
      }
    }
  }

  void _clearAllFields() {
    setState(() {
      _cv = CvModel.createEmpty();
      _nameController.clear();
      _titleController.clear();
      _emailController.clear();
      _phoneController.clear();
      _locationController.clear();
      _linkedinController.clear();
      _githubController.clear();
      _portfolioController.clear();
      _summaryController.clear();
    });
  }

  void _showAiImportError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(LocalizationService.tr(
          error is AiCvException ? error.messageKey : 'cv_ai_request_failed')),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _completeAiImport(AiCvParseResult result) {
    if (!mounted) return;
    if (!result.isSuccess || result.totalExtractedItems == 0) {
      throw const AiCvException('cv_ai_request_failed');
    }
    _clearAllFields();
    _applyAiParseResult(result);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(LocalizationService.tr(result.source == 'gemini_api'
          ? 'cv_ai_extracted_success'
          : 'cv_ai_local_extraction')),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @visibleForTesting
  void applyAiParseResultForTesting(AiCvParseResult result) =>
      _applyAiParseResult(result);

  @visibleForTesting
  CvModel get cvForTesting => _cv;

  /// Mevcut verileri KESİNLİKLE silmeden üzerine akıllıca ekleyen (Non-Destructive Merge) motoru
  void _applyAiParseResult(AiCvParseResult result) {
    if (!result.isSuccess) return;

    setState(() {
      // 1. Kişisel Bilgiler (Mevcut olanlar silinmez, sadece yeni gelen dolu alanlar güncellenir)
      if (result.fullName.isNotEmpty) {
        _nameController.text = result.fullName;
        _cv.fullName = result.fullName;
      }
      if (result.jobTitle.isNotEmpty) {
        _titleController.text = result.jobTitle;
        _cv.jobTitle = result.jobTitle;
      }
      if (result.email.isNotEmpty) {
        _emailController.text = result.email;
        _cv.email = result.email;
      }
      if (result.phone.isNotEmpty) {
        _phoneController.text = result.phone;
        _cv.phone = result.phone;
      }
      if (result.location.isNotEmpty) {
        _locationController.text = result.location;
        _cv.location = result.location;
      }
      if (result.linkedin.isNotEmpty) {
        _linkedinController.text = result.linkedin;
        _cv.linkedin = result.linkedin;
      }
      if (result.github.isNotEmpty) {
        _githubController.text = result.github;
        _cv.github = result.github;
      }
      if (result.portfolioUrl.isNotEmpty) {
        _portfolioController.text = result.portfolioUrl;
        _cv.portfolioUrl = result.portfolioUrl;
      }

      // 2. Profesyonel Özet tekil alandır; yeni AI sonucu eski dilli özeti değiştirmelidir.
      final summaryToStream = result.summary.trim();
      if (summaryToStream.isNotEmpty) {
        _cv.summary = summaryToStream;
        _summaryController.text = _cv.summary;
        _isTypewritingSummary = true;
      }

      // 3. Eğitimler (Mevcut okullar korunur, yeni gelenler listenin başına eklenir)
      if (result.educations.isNotEmpty) {
        _cv.educations.removeWhere((e) =>
            e.school.trim().isEmpty &&
            e.field.trim().isEmpty &&
            e.degree.trim().isEmpty);
        for (final edu in result.educations.reversed) {
          final exists = _cv.educations.any((e) =>
              e.school.toLowerCase().trim() ==
                  edu.school.toLowerCase().trim() &&
              e.degree.toLowerCase().trim() ==
                  edu.degree.toLowerCase().trim() &&
              e.field.toLowerCase().trim() == edu.field.toLowerCase().trim());
          final hasData = edu.school.trim().isNotEmpty ||
              edu.degree.trim().isNotEmpty ||
              edu.field.trim().isNotEmpty;
          if (!exists && hasData) {
            _cv.educations.insert(0, edu);
          }
        }
      }

      // 4. Deneyimler (Mevcut şirketler korunur, yeni gelenler listenin başına eklenir)
      if (result.experiences.isNotEmpty) {
        _cv.experiences.removeWhere((e) =>
            e.company.trim().isEmpty &&
            e.position.trim().isEmpty &&
            e.description.trim().isEmpty);
        for (final exp in result.experiences.reversed) {
          final exists = _cv.experiences.any((e) =>
              e.company.toLowerCase().trim() ==
                  exp.company.toLowerCase().trim() &&
              e.position.toLowerCase().trim() ==
                  exp.position.toLowerCase().trim() &&
              e.startDate.toLowerCase().trim() ==
                  exp.startDate.toLowerCase().trim());
          final hasData = exp.company.trim().isNotEmpty ||
              exp.position.trim().isNotEmpty ||
              exp.description.trim().isNotEmpty;
          if (!exists && hasData) {
            _cv.experiences.insert(0, exp);
          }
        }
      }

      // 5. Yetenekler (Mevcut yetenekler korunur, yenileri listeye ilave edilir)
      for (final sk in result.skills) {
        final exists = _cv.skills.any(
            (s) => s.name.toLowerCase().trim() == sk.name.toLowerCase().trim());
        if (!exists && sk.name.trim().isNotEmpty) {
          _cv.skills.add(sk);
        }
      }

      // 6. Sertifikalar (Mevcut olanlar korunur)
      if (result.certificates.isNotEmpty) {
        _cv.certificates.removeWhere(
            (c) => c.name.trim().isEmpty && c.issuer.trim().isEmpty);
        for (final cert in result.certificates.reversed) {
          final exists = _cv.certificates.any((c) =>
              c.name.toLowerCase().trim() == cert.name.toLowerCase().trim());
          if (!exists && cert.name.trim().isNotEmpty) {
            _cv.certificates.insert(0, cert);
          }
        }
      }

      // 7. Diller (Mevcut olanlar korunur, seviyeler normalize edilir)
      if (result.languages.isNotEmpty) {
        _cv.languages.removeWhere((l) => l.language.trim().isEmpty);
        for (final lang in result.languages.reversed) {
          final exists = _cv.languages.any((l) =>
              l.language.toLowerCase().trim() ==
              lang.language.toLowerCase().trim());
          if (!exists && lang.language.trim().isNotEmpty) {
            final normalizedLevel =
                LocalizationService.normalizeLanguageLevel(lang.level);
            _cv.languages.insert(
              0,
              LanguageItem(
                language: lang.language.trim(),
                level: normalizedLevel,
              ),
            );
          }
        }
      }

      // 8. Projeler (Mevcut olanlar korunur)
      if (result.projects.isNotEmpty) {
        _cv.projects.removeWhere((p) =>
            p.name.trim().isEmpty &&
            p.role.trim().isEmpty &&
            p.description.trim().isEmpty);
        for (final proj in result.projects.reversed) {
          final exists = _cv.projects.any((p) =>
              p.name.toLowerCase().trim() == proj.name.toLowerCase().trim());
          if (!exists && proj.name.trim().isNotEmpty) {
            _cv.projects.insert(0, proj);
          }
        }
      }

      // 9. Kişisel Özellikler / Nitelikler
      for (final trait in result.personalTraits) {
        final exists = _cv.personalTraits
            .any((t) => t.toLowerCase().trim() == trait.toLowerCase().trim());
        if (!exists && trait.trim().isNotEmpty) {
          _cv.personalTraits.add(trait);
        }
      }

      // 10. Referanslar
      if (result.references.isNotEmpty) {
        _cv.references.removeWhere(
            (r) => r.name.trim().isEmpty && r.company.trim().isEmpty);
        for (final ref in result.references.reversed) {
          final exists = _cv.references.any((r) =>
              r.name.toLowerCase().trim() == ref.name.toLowerCase().trim() &&
              r.company.toLowerCase().trim() ==
                  ref.company.toLowerCase().trim());
          final hasData = ref.name.trim().isNotEmpty ||
              ref.company.trim().isNotEmpty ||
              ref.phone.trim().isNotEmpty ||
              ref.email.trim().isNotEmpty;
          if (!exists && hasData) {
            _cv.references.insert(0, ref);
          }
        }
      }

      // 11. Aurora Glow Işıltı Vurguları
      _glowingItemKeys.clear();
      if (result.fullName.isNotEmpty ||
          result.jobTitle.isNotEmpty ||
          result.email.isNotEmpty ||
          result.phone.isNotEmpty ||
          result.location.isNotEmpty) {
        _glowingItemKeys.add('personal');
      }
      if (summaryToStream.isNotEmpty) {
        _glowingItemKeys.add('summary');
      }
      if (result.experiences.isNotEmpty) {
        _glowingItemKeys.add('experience_0');
      }
      if (result.educations.isNotEmpty) {
        _glowingItemKeys.add('education_0');
      }
      if (result.skills.isNotEmpty) {
        _glowingItemKeys.add('skills');
      }
      if (result.certificates.isNotEmpty) {
        _glowingItemKeys.add('certificate_0');
      }
      if (result.languages.isNotEmpty) {
        _glowingItemKeys.add('language_0');
      }
      if (result.references.isNotEmpty) {
        _glowingItemKeys.add('reference_0');
      }

      _syncCvData();
    });

    // Otomatik olarak 1. Sekmeye (Kişisel Bilgiler) geç
    _tabController.animateTo(1);

    // Daktilo efekti ile özet akışı
    if (result.summary.isNotEmpty) {
      TypewriterHelper.streamToController(
        _summaryController,
        _cv.summary,
        wordDelay: const Duration(milliseconds: 25),
        onTick: () {
          if (mounted) setState(() {});
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _isTypewritingSummary = false;
              _syncCvData();
            });
          }
        },
      );
    }

    // Başarı bildirimi
    final summaryText = LocalizationService.tr('cv_ai_success_summary');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summaryText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: LocalizationService.tr('cv_ai_btn_view_cv'),
          textColor: Colors.amberAccent,
          onPressed: () {
            _tabController.animateTo(1);
          },
        ),
      ),
    );
  }

  Future<void> _handlePickDocumentForCv() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
      );
      if (file == null) return;

      if (!mounted) return;

      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocalizationService.tr('cv_ai_overwrite_title')),
          content: Text(LocalizationService.tr('cv_ai_overwrite_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(LocalizationService.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(LocalizationService.tr('confirm'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      if (!mounted) return;
      setState(() => _isAiGenerating = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(LocalizationService.tr('cv_ai_file_processing'))),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      String extractedText = '';
      final ext = file.extension?.toLowerCase() ?? '';
      if (ext == 'pdf') {
        final result = await AiCvService.parseCvDocument(
            bytes: bytes,
            mimeType: 'application/pdf',
            locale: LocalizationService.currentLocale);
        _completeAiImport(result);
        return;
      }
      if (ext == 'docx' || ext == 'doc') {
        extractedText = await DocumentParserService.parseDocx(bytes);
      } else if (ext == 'txt') {
        extractedText = utf8.decode(bytes, allowMalformed: true);
      } else if (ext == 'pdf') {
        extractedText = await DocumentParserService.parsePdf(bytes);
      } else {
        extractedText = utf8.decode(bytes, allowMalformed: true);
      }

      if (extractedText.trim().isEmpty) {
        if (mounted) {
          setState(() => _isAiGenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.tr('docs_empty_bytes_error')),
            ),
          );
        }
        return;
      }

      final parseResult = await AiCvService.parseCvPrompt(
        prompt: extractedText,
        locale: LocalizationService.currentLocale,
        isStrictExtraction: true,
      );

      _completeAiImport(parseResult);
    } catch (e) {
      _showAiImportError(e);
    } finally {
      if (mounted) setState(() => _isAiGenerating = false);
    }
  }

  Future<void> _handleCapturePhotoForCv() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.accentEmerald),
                ),
                title: Text(
                  LocalizationService.tr('cv_ai_source_camera'),
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: textColor),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final hasCam =
                      await AppPermissionService.requestCameraPermission(
                          context);
                  if (!hasCam || !mounted) return;
                  final photo =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  if (photo != null) _processCvPhoto(photo);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primaryLight),
                ),
                title: Text(
                  LocalizationService.tr('cv_ai_source_gallery'),
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: textColor),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final hasGallery =
                      await AppPermissionService.requestGalleryPermission(
                          context);
                  if (!hasGallery || !mounted) return;
                  final photo = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (photo != null) _processCvPhoto(photo);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processCvPhoto(XFile photo) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.tr('cv_ai_overwrite_title')),
        content: Text(LocalizationService.tr('cv_ai_overwrite_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(LocalizationService.tr('confirm'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isAiGenerating = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(LocalizationService.tr('cv_ai_ocr_processing'))),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      final extension = photo.name.split('.').last.toLowerCase();
      final mimeType = photo.mimeType ??
          const {
            'png': 'image/png',
            'webp': 'image/webp',
            'heic': 'image/heic',
            'heif': 'image/heif',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
          }[extension] ??
          'image/jpeg';
      final result = await AiCvService.parseCvDocument(
          bytes: await photo.readAsBytes(),
          mimeType: mimeType,
          locale: LocalizationService.currentLocale);
      _completeAiImport(result);
    } catch (e) {
      _showAiImportError(e);
    } finally {
      if (mounted) setState(() => _isAiGenerating = false);
    }
  }

  Future<void> _handleImportLinkForCv() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF161A28) : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final linkController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.link_rounded, color: Color(0xFF8B5CF6)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocalizationService.tr('cv_ai_link_dialog_title'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              LocalizationService.tr('cv_ai_link_dialog_desc'),
              style: TextStyle(
                fontSize: 12.5,
                color: subColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkController,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: TextStyle(color: textColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: LocalizationService.tr('cv_ai_link_dialog_hint'),
                hintStyle: TextStyle(
                    color: subColor.withValues(alpha: 0.6), fontSize: 12.5),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0F1420) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final url = linkController.text.trim();
                  if (url.isNotEmpty) {
                    Navigator.pop(ctx);
                    _processProfileLink(url);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  LocalizationService.tr('cv_ai_link_dialog_btn'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processProfileLink(String rawUrl) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.tr('cv_ai_overwrite_title')),
        content: Text(LocalizationService.tr('cv_ai_overwrite_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(LocalizationService.tr('confirm'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    _clearAllFields();

    setState(() => _isAiGenerating = true);
    try {
      final lower = rawUrl.toLowerCase();
      setState(() {
        if (lower.contains('linkedin.com')) {
          _cv.linkedin = rawUrl;
          _linkedinController.text = rawUrl;
        } else if (lower.contains('github.com')) {
          _cv.github = rawUrl;
          _githubController.text = rawUrl;
        } else if (lower.contains('x.com') ||
            lower.contains('twitter.com') ||
            lower.contains('instagram.com') ||
            lower.startsWith('http')) {
          _cv.portfolioUrl = rawUrl;
          _portfolioController.text = rawUrl;
        }
        _syncCvData();
      });

      final pageText = await AiCvService.fetchReadableTextFromUrl(rawUrl);
      if (pageText.trim().isEmpty ||
          _looksLikeBlockedProfilePage(rawUrl, pageText)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.tr('cv_ai_link_unreadable')),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final parseResult = await AiCvService.parseCvPrompt(
        prompt: pageText,
        locale: LocalizationService.currentLocale,
        isStrictExtraction: true,
      );

      if (mounted) {
        if (parseResult.isSuccess && parseResult.totalExtractedItems > 0) {
          _applyAiParseResult(parseResult);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ ${LocalizationService.tr('cv_ai_extracted_success')}'),
              backgroundColor: AppColors.accentEmerald,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService.tr('cv_ai_link_unreadable')),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Profile link extract error: $e');
    } finally {
      if (mounted) setState(() => _isAiGenerating = false);
    }
  }

  bool _looksLikeBlockedProfilePage(String rawUrl, String pageText) {
    final url = rawUrl.toLowerCase();
    final text = pageText.toLowerCase();
    final isSocialProfile = url.contains('linkedin.com') ||
        url.contains('instagram.com') ||
        url.contains('x.com') ||
        url.contains('twitter.com');
    if (!isSocialProfile) return false;

    final authWallMarkers = [
      'sign in',
      'log in',
      'login',
      'join now',
      'create account',
      'giriş yap',
      'oturum aç',
      'kaydol',
      'üye ol',
      'melden sie sich',
      'einloggen',
      'anmelden',
      'войдите',
      'зарегистрируйтесь',
    ];
    final markerCount =
        authWallMarkers.where((marker) => text.contains(marker)).length;
    return markerCount >= 2 && pageText.length < 2500;
  }

  Widget _buildMultiModalAiBar({
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 13, color: AppColors.primaryLight),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                LocalizationService.tr('cv_ai_import_title'),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildImportChip(
                icon: Icons.upload_file_rounded,
                label: LocalizationService.tr('cv_ai_btn_upload_file'),
                color: const Color(0xFF0284C7),
                isDark: isDark,
                borderColor: borderColor,
                onTap: _isAiGenerating ? null : _handlePickDocumentForCv,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildImportChip(
                icon: Icons.camera_alt_rounded,
                label: LocalizationService.tr('cv_ai_btn_camera_scan'),
                color: const Color(0xFF10B981),
                isDark: isDark,
                borderColor: borderColor,
                onTap: _isAiGenerating ? null : _handleCapturePhotoForCv,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildImportChip(
                icon: Icons.link_rounded,
                label: LocalizationService.tr('cv_ai_btn_link_import'),
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                borderColor: borderColor,
                onTap: _isAiGenerating ? null : _handleImportLinkForCv,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCvLanguageSelector(
          isDark: isDark,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
      ],
    );
  }

  Widget _buildImportChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required Color borderColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCvLanguageSelector({
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    final currentOption = LocalizationService.getLanguageOption(_cvLanguage);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2032) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.translate_rounded,
                    size: 16, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('cv_language_prompt'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocalizationService.tr('cv_language_subtitle'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Active Selected Language Banner (tappable to open full sheet)
          InkWell(
            onTap: () =>
                _showCvLanguageSheet(isDark, textColor, subColor, borderColor),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:
                    AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    currentOption.flag,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(builder: (context, constraints) {
                          final name = Text(currentOption.name,
                              softWrap: true,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: textColor));
                          final badge = Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(_cvTr('cv_language_selected_badge'),
                                style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          );
                          if (constraints.maxWidth < 180) {
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  name,
                                  const SizedBox(height: 4),
                                  badge
                                ]);
                          }
                          return Row(children: [
                            Expanded(child: name),
                            const SizedBox(width: 8),
                            badge
                          ]);
                        }),
                        const SizedBox(height: 2),
                        Text(
                          currentOption.nativeName,
                          style: TextStyle(
                            fontSize: 11,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.unfold_more_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Horizontal scroll of all 19 language chips for instant 1-tap switching
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LocalizationService.supportedLanguages.map((lang) {
                final isSelected = lang.code == _cvLanguage;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => _onCvLanguageSelected(lang.code),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? const Color(0xFF22283E)
                                : const Color(0xFFEBF1F8)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : borderColor.withValues(alpha: 0.6),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            lang.name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showCvLanguageSheet(
      bool isDark, Color textColor, Color subColor, Color borderColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = LocalizationService.supportedLanguages.where((l) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return l.name.toLowerCase().contains(q) ||
                  l.nativeName.toLowerCase().contains(q) ||
                  l.code.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131827) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          LocalizationService.tr('cv_language_sheet_title'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: LocalizationService.tr('search_placeholder'),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1B2032)
                          : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = _cvLanguage == item.code;

                        return InkWell(
                          onTap: () {
                            _onCvLanguageSelected(item.code);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                      .withValues(alpha: isDark ? 0.2 : 0.1)
                                  : (isDark
                                      ? const Color(0xFF1B2032)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : borderColor,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(item.flag,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primaryLight
                                              : textColor,
                                        ),
                                      ),
                                      Text(
                                        item.nativeName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onCvLanguageSelected(String langCode) {
    if (_cvLanguage == langCode) return;
    setState(() {
      _cvLanguage = langCode;
      _cv.targetLanguage = langCode;
    });
    CvStorageService.saveActiveCv(_cv);
    final opt = LocalizationService.getLanguageOption(langCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${opt.flag} ${opt.name}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAiGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAiGenerating ? null : _handleAiGenerate,
        icon: _isAiGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 17),
        label: Text(
          _isAiGenerating
              ? LocalizationService.tr('cv_ai_analyzing')
              : LocalizationService.tr('cv_ai_generate_btn'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required String initialValue,
    required IconData icon,
    required bool isDark,
    String? hint,
    int? maxLines = 1,
    int? minLines,
    required Function(String) onChanged,
  }) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: subColor,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: initialValue,
            maxLines: maxLines,
            minLines: minLines,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            style: TextStyle(
                color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(
                  color: subColor.withValues(alpha: 0.65), fontSize: 12.5),
              prefixIcon: Icon(icon,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB)),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1B2032) : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF38415C)
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 2.0),
              ),
            ),
            onChanged: (val) {
              onChanged(val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    int? maxLines = 1,
    int? minLines,
    String? hint,
  }) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: subColor,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            onChanged: (val) => setState(() {}),
            maxLines: maxLines,
            minLines: minLines,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: subColor.withValues(alpha: 0.65), fontSize: 12.5),
              prefixIcon: Icon(icon,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB),
                  size: 18),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1B2032) : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF38415C)
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      String message, IconData icon, bool isDark, Color subColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: subColor.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: subColor),
          ),
        ],
      ),
    );
  }
}
