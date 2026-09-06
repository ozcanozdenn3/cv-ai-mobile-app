import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/theme_constants.dart';
import 'localization_service.dart';

class AppPermissionService {
  /// Request Camera Permission. Returns true if granted/limited.
  /// If denied/permanently denied, shows the localized dialog leading to Settings.
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }

      final requestStatus = await Permission.camera.request();
      if (requestStatus.isGranted || requestStatus.isLimited) {
        return true;
      }

      if (context.mounted) {
        await showPermissionSettingsDialog(context, isCamera: true);
      }
      return false;
    } catch (_) {
      return true; // Fallback gracefully if permission check encounters native issue
    }
  }

  /// Request Gallery / Photos Permission. Returns true if granted/limited.
  /// If denied/permanently denied, shows the localized dialog leading to Settings.
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (Platform.isAndroid) {
        status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited) {
          // Fallback for older Android (SDK < 33)
          final storageStatus = await Permission.storage.request();
          if (storageStatus.isGranted || storageStatus.isLimited) {
            status = storageStatus;
          }
        }
      } else {
        status = await Permission.photos.request();
      }

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (context.mounted) {
        await showPermissionSettingsDialog(context, isCamera: false);
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Request Microphone and Speech Recognition Permission for Voice-to-CV input.
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    try {
      final micStatus = await Permission.microphone.status;
      final speechStatus = await Permission.speech.status;
      if ((micStatus.isGranted || micStatus.isLimited) &&
          (speechStatus.isGranted || speechStatus.isLimited)) {
        return true;
      }

      final micReq = await Permission.microphone.request();
      final speechReq = await Permission.speech.request();
      if ((micReq.isGranted || micReq.isLimited) &&
          (speechReq.isGranted || speechReq.isLimited)) {
        return true;
      }

      if (context.mounted) {
        await showPermissionSettingsDialog(
          context,
          isCamera: false,
          isMicrophone: true,
        );
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Show localized modern permission settings dialog directing the user to device Settings
  static Future<void> showPermissionSettingsDialog(
    BuildContext context, {
    bool isCamera = false,
    bool isMicrophone = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final String title;
    final String desc;
    if (isMicrophone) {
      title = LocalizationService.tr('perm_mic_title');
      desc = LocalizationService.tr('perm_mic_desc');
    } else if (isCamera) {
      title = LocalizationService.tr('perm_camera_title');
      desc = LocalizationService.tr('perm_camera_desc');
    } else {
      title = LocalizationService.tr('perm_gallery_title');
      desc = LocalizationService.tr('perm_gallery_desc');
    }

    final openSettingsText = LocalizationService.tr('perm_open_settings');
    final cancelText = LocalizationService.tr('perm_cancel');

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: isMicrophone
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : (isCamera
                            ? AppColors.emeraldGradient
                            : AppColors.blueGradient),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isMicrophone
                                ? const Color(0xFF8B5CF6)
                                : (isCamera
                                    ? AppColors.accentEmerald
                                    : AppColors.primaryLight))
                            .withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    isMicrophone
                        ? Icons.mic_rounded
                        : (isCamera
                            ? Icons.camera_alt_rounded
                            : Icons.photo_library_rounded),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),

                // Localized Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Localized Description
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: subColor,
                          side: BorderSide(color: borderColor, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Open Settings
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMicrophone
                              ? const Color(0xFF8B5CF6)
                              : (isCamera
                                  ? AppColors.accentEmerald
                                  : AppColors.primary),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          openSettingsText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
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
      },
    );
  }
}
