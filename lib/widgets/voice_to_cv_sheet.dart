import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/localization_service.dart';
import '../services/app_permission_service.dart';

/// Futuristic Siri / Gemini style Voice-to-CV modal sheet with real-time Speech-to-Text,
/// reactive audio waveform, glowing microphone, recording timer, and 100% localized interface across 19 languages.
class VoiceToCvSheet extends StatefulWidget {
  final Function(String voiceText) onApplyPrompt;

  const VoiceToCvSheet({
    super.key,
    required this.onApplyPrompt,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(String voiceText) onApplyPrompt,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceToCvSheet(onApplyPrompt: onApplyPrompt),
    );
  }

  @override
  State<VoiceToCvSheet> createState() => _VoiceToCvSheetState();
}

class _VoiceToCvSheetState extends State<VoiceToCvSheet>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late TextEditingController _transcriptController;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _selectedLocaleId = '';
  double _soundLevel = 0.0;
  String _baseTranscript = '';

  int _secondsRecorded = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat();

    // Start 100% empty - NO mock data!
    _transcriptController = TextEditingController(text: '');

    // Initialize real Speech Recognition
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          debugPrint('SpeechToText error: ${val.errorMsg}');
          if (mounted) {
            setState(() {
              if (val.permanent) {
                _isListening = false;
                _pulseController.stop();
                _timer?.cancel();
              }
            });
          }
        },
        onStatus: (status) {
          debugPrint('SpeechToText status: $status');
          if (mounted) {
            if (status == 'notListening' || status == 'done') {
              setState(() {
                _isListening = false;
                _pulseController.stop();
                _timer?.cancel();
                _baseTranscript = _transcriptController.text.trim();
              });
            }
          }
        },
      );

      if (_speechEnabled && mounted) {
        await _resolveLocale();
        await _startListening();
      }
    } catch (e) {
      debugPrint('Speech init exception: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  Future<void> _resolveLocale() async {
    try {
      final locales = await _speechToText.locales();
      final currentAppLocale =
          LocalizationService.currentLocale.replaceAll('-', '_').toLowerCase();
      final currentPrefix = currentAppLocale.split('_')[0];

      stt.LocaleName? matched;
      for (final loc in locales) {
        final locIdLower = loc.localeId.replaceAll('-', '_').toLowerCase();
        if (locIdLower == currentAppLocale) {
          matched = loc;
          break;
        }
      }
      if (matched == null) {
        for (final loc in locales) {
          final locIdLower = loc.localeId.replaceAll('-', '_').toLowerCase();
          if (locIdLower.startsWith('${currentPrefix}_') ||
              locIdLower == currentPrefix) {
            matched = loc;
            break;
          }
        }
      }

      if (matched != null) {
        _selectedLocaleId = matched.localeId;
      }
    } catch (e) {
      debugPrint('Locale resolve exception: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      final ok = await _speechToText.initialize();
      if (!ok) return;
      _speechEnabled = true;
    }

    _baseTranscript = _transcriptController.text.trim();

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              final words = result.recognizedWords.trim();
              if (words.isNotEmpty) {
                if (_baseTranscript.isNotEmpty) {
                  _transcriptController.text = '$_baseTranscript $words';
                } else {
                  _transcriptController.text = words;
                }
                _transcriptController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _transcriptController.text.length),
                );
              }
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _selectedLocaleId.isNotEmpty ? _selectedLocaleId : null,
          listenFor: const Duration(minutes: 5),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() {
              _soundLevel = level;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isListening = true;
        });
        _pulseController.repeat(reverse: true);
        _startTimer();
      }
    } catch (e) {
      debugPrint('Listen start exception: $e');
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
        _baseTranscript = _transcriptController.text.trim();
      });
      _pulseController.stop();
      _timer?.cancel();
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      final hasMic =
          await AppPermissionService.requestMicrophonePermission(context);
      if (!hasMic || !mounted) return;
      await _startListening();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRecorded = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _isListening) {
        setState(() {
          _secondsRecorded++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _speechToText.stop();
    _pulseController.dispose();
    _waveController.dispose();
    _transcriptController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle with Aurora Glow
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF06B6D4),
                      Color(0xFFD946EF)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Title & Subtitle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.tr('cv_ai_voice_title'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocalizationService.tr('cv_ai_voice_subtitle'),
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await _stopListening();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(Icons.close_rounded, color: subColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Glowing Center Microphone with Audio Waves
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial animated pulse glow
                      if (_isListening)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = 1.0 + 0.35 * _pulseController.value;
                            final alpha = 0.4 * (1.0 - _pulseController.value);
                            return Container(
                              width: 110 * scale,
                              height: 110 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7C3AED)
                                    .withValues(alpha: alpha),
                              ),
                            );
                          },
                        ),

                      // Microphone Button
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? const [
                                      Color(0xFF6366F1),
                                      Color(0xFF9333EA),
                                      Color(0xFFEC4899)
                                    ]
                                  : [
                                      Colors.grey.shade600,
                                      Colors.grey.shade800
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? const Color(0xFF7C3AED)
                                        : Colors.grey)
                                    .withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.mic_rounded
                                : Icons.mic_off_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Animated Waveform Bars with dynamic sound response
                  SizedBox(
                    height: 38,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final soundBoost = (_soundLevel.abs().clamp(0.0, 15.0) / 15.0) * 14.0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(15, (index) {
                            final waveSine = math.sin((index * 0.45) + (_waveController.value * 6.28)).abs();
                            final baseHeight = _isListening
                                ? (6.0 + 16.0 * waveSine + soundBoost)
                                : 4.0;
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2.2),
                              width: 3.8,
                              height: baseHeight.clamp(4.0, 36.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6366F1),
                                    index % 2 == 0
                                        ? const Color(0xFF06B6D4)
                                        : const Color(0xFFD946EF),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  ),
                                ),
                              );
                          }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Timer & Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening
                              ? '${LocalizationService.tr('cv_ai_voice_listening')} ${_formatDuration(_secondsRecorded)}'
                              : LocalizationService.tr('cv_ai_voice_stop'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Speech Transcript Live Text Field
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 16, color: subColor),
                      const SizedBox(width: 6),
                      Text(
                        LocalizationService.tr('cv_ai_voice_title'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                        ),
                      ),
                      const Spacer(),
                      if (_transcriptController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _transcriptController.clear();
                              _baseTranscript = '';
                            });
                          },
                          child: Text(
                            LocalizationService.tr('perm_cancel'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _transcriptController,
                    maxLines: 4,
                    minLines: 2,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: _isListening
                          ? '${LocalizationService.tr('cv_ai_voice_listening')}..'
                          : LocalizationService.tr('cv_ai_prompt_placeholder'),
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: subColor.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () async {
                      await _stopListening();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      LocalizationService.tr('perm_cancel'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF7C3AED),
                          Color(0xFFEC4899)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF7C3AED).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _stopListening();
                        if (!context.mounted) return;
                        final text = _transcriptController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(LocalizationService.tr(
                                  'cv_ai_prompt_placeholder')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          widget.onApplyPrompt(text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        LocalizationService.tr('cv_ai_voice_apply'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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
}
