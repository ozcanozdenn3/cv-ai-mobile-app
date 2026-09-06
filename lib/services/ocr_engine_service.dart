import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';

class OcrResult {
  final String text;
  final int blockCount;
  final int lineCount;
  final bool isSuccess;
  final String? errorMessage;

  const OcrResult({
    required this.text,
    required this.blockCount,
    required this.lineCount,
    required this.isSuccess,
    this.errorMessage,
  });
}

class OcrEngineService {
  static TextRecognizer? _recognizerInstance;

  static TextRecognizer get _recognizer {
    _recognizerInstance ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizerInstance!;
  }

  /// Doğrudan dosya yolundaki görseli Google ML Kit on-device yapay zeka ile ayrıştırır.
  static Future<OcrResult> processImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return OcrResult(
          text: '',
          blockCount: 0,
          lineCount: 0,
          isSuccess: false,
          errorMessage: LocalizationService.tr('file_not_found'),
        );
      }

      final inputImage = InputImage.fromFilePath(filePath);
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

      final buffer = StringBuffer();
      int lineCount = 0;

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          lineCount++;
          buffer.writeln(line.text);
        }
        buffer.writeln(); // Paragraf ayrımı
      }

      final extracted = buffer.toString().trim();
      final fullText = extracted.isNotEmpty ? extracted : recognizedText.text.trim();

      // Supabase OCR Geçmişine Kaydet
      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated && fullText.isNotEmpty) {
        SupabaseService.saveOcrExtraction(
          text: fullText,
          sourceFilename: filePath.split('/').last,
        );
      }

      return OcrResult(
        text: fullText,
        blockCount: recognizedText.blocks.length,
        lineCount: lineCount > 0 ? lineCount : recognizedText.blocks.length,
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('${LocalizationService.tr('ocr_error')}: $e');
      return OcrResult(
        text: '',
        blockCount: 0,
        lineCount: 0,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Görsel baytlarını diske yazıp Google ML Kit ile tam metin ayrıştırma yapar.
  static Future<OcrResult> processImageBytes(Uint8List bytes, {String? fileName}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final name = fileName ?? 'ocr_${DateTime.now().millisecondsSinceEpoch}';
      final file = File('${tempDir.path}/$name.jpg');
      await file.writeAsBytes(bytes);

      return await processImageFile(file.path);
    } catch (e) {
      debugPrint('${LocalizationService.tr('ocr_process_error')}: $e');
      return OcrResult(
        text: '',
        blockCount: 0,
        lineCount: 0,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  static void dispose() {
    _recognizerInstance?.close();
    _recognizerInstance = null;
  }
}
