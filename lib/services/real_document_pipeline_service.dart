import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'localization_service.dart';
import 'ocr_engine_service.dart';

class RealDocumentPipelineService {
  static Future<Map<String, dynamic>> runDocumentEnhancement({
    required Uint8List imageBytes,
    required String sourceName,
    String mode = 'document',
    String filterName = 'Magic AI',
  }) async {
    if (imageBytes.isEmpty) {
      return {
        'success': false,
        'enhancedBytes': imageBytes,
        'ocrText': '',
        'confidence': 0.0,
      };
    }

    try {
      final processed = await _preprocessDocumentImage(
        imageBytes,
        filterName: filterName,
        mode: mode,
      );
      if (processed.isEmpty) {
        return {
          'success': false,
          'enhancedBytes': imageBytes,
          'ocrText': '',
          'confidence': 0.0,
        };
      }

      String extractedText = '';
      double confidence = 0.0;

      // 1. Önce On-Device Google ML Kit ile yüksek hızlı ve yüksek doğruluklu metin okuma
      try {
        final localOcr = await OcrEngineService.processImageBytes(
          processed,
          fileName: sourceName,
        );
        if (localOcr.isSuccess && localOcr.text.trim().isNotEmpty) {
          extractedText = localOcr.text.trim();
          confidence = 0.98;
        }
      } catch (e) {
        debugPrint('Google ML Kit OCR hatası: $e');
      }

      // 2. Eğer yerel OCR metin bulamadıysa (Latin dışı alfabeler: Arapça, Rusça, Çince, Japonca, Korece, Hintçe vb.)
      // kullanıcının aktif dil koduna uygun dinamik bulut OCR motorunu devreye sok
      if (extractedText.isEmpty) {
        try {
          final cloudOcr = await _runOcr(
            processed,
            sourceName: sourceName,
            languageCode: _getOcrLanguageCode(),
          ).timeout(const Duration(seconds: 10));
          if ((cloudOcr['text'] as String?)?.isNotEmpty ?? false) {
            extractedText = (cloudOcr['text'] as String).trim();
            confidence = cloudOcr['confidence'] ?? 0.90;
          }
        } catch (_) {}
      }

      return {
        'success': true,
        'enhancedBytes': processed,
        'ocrText': extractedText,
        'confidence': confidence,
      };
    } catch (e) {
      debugPrint('RealDocumentPipelineService enhancement error: $e');
      return {
        'success': false,
        'enhancedBytes': imageBytes,
        'ocrText': '',
        'confidence': 0.0,
      };
    }
  }

  static Future<Uint8List> enhanceDocument({
    required Uint8List imageBytes,
    required String filterName,
    String mode = 'document',
  }) async {
    return _preprocessDocumentImage(
      imageBytes,
      filterName: filterName,
      mode: mode,
    );
  }

  static Future<Uint8List> _preprocessDocumentImage(
    Uint8List imageBytes, {
    required String filterName,
    String mode = 'document',
  }) async {
    if (imageBytes.isEmpty) {
      return imageBytes;
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return imageBytes;
    }

    // 1. EXIF rotasyonunu düzelt (telefon yatay/dikey açısı)
    img.Image source = img.bakeOrientation(decoded);

    // 2. Grayscale JPEG Kırmızı Kanalı Düzeltmesi:
    // iOS / Apple VNDocumentCamera veya tek kanallı gri JPEG'ler çözüldüğünde,
    // Dart image kütüphanesi gri tonu yalnızca R (kırmızı) kanalına yazıp G=0, B=0 bırakır.
    // Bu da görselin kıpkırmızı çıkmasına neden olur. Kanalları eşitliyoruz:
    if (source.numChannels == 1) {
      source = source.convert(numChannels: 3);
      for (final p in source) {
        final l = p.r;
        p.g = l;
        p.b = l;
      }
    } else {
      int sampleCount = 0;
      int redOnlyCount = 0;
      for (final p in source) {
        sampleCount++;
        if (p.r > 15 && p.g <= 3 && p.b <= 3) {
          redOnlyCount++;
        }
        if (sampleCount >= 200) break;
      }
      if (sampleCount > 0 && (redOnlyCount / sampleCount) > 0.8) {
        for (final p in source) {
          final l = p.r;
          p.g = l;
          p.b = l;
        }
      }
    }

    // 3. Maksimum boyutu dengeli ölçeklendir (Hızlı ve yüksek kaliteli işleme için)
    final maxSide = source.width > source.height ? source.width : source.height;
    if (maxSide > 2400) {
      source = img.copyResize(
        source,
        width: source.width >= source.height ? 2400 : null,
        height: source.height > source.width ? 2400 : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // 4. Yazı Kontur Keskinleştirme Çekirdeği (3x3 Unsharp Convolution Kernel)
    img.Image applySharpenKernel(img.Image input) {
      return img.convolution(
        input,
        filter: [
          0,
          -1,
          0,
          -1,
          5,
          -1,
          0,
          -1,
          0,
        ],
      );
    }

    // 5. Filtreye Göre Adaptif Kontrast ve Zemin Beyazlatma
    img.Image filtered;
    switch (filterName) {
      case 'Siyah-Beyaz':
        // Kusursuz Fotokopi Modu:
        // Harfleri kömür siyahı (0), kağıt ve gölgeleri saf beyaz (255) yapar.
        final sharp = applySharpenKernel(source);
        filtered = img.Image.from(sharp);
        for (final p in filtered) {
          final l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
          if (l > 140) {
            // Kağıt zemini -> Bembeyaz
            p.r = 255;
            p.g = 255;
            p.b = 255;
          } else {
            // Yazı ve mürekkep -> Simsiyah
            p.r = 0;
            p.g = 0;
            p.b = 0;
          }
        }
        break;

      case 'Gri Tonlama':
        // Pürüzsüz Ofis Tarayıcı Modu:
        final sharp = applySharpenKernel(source);
        filtered = img.Image.from(sharp);
        for (final p in filtered) {
          final l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
          int outVal;
          if (l > 155) {
            // Kağıdı beyaza doğru çek
            outVal = (l + (l - 155) * 1.8).clamp(0, 255).round();
          } else {
            // Yazıyı koyulaştır
            outVal = (l * 0.6).clamp(0, 255).round();
          }
          p.r = outVal;
          p.g = outVal;
          p.b = outVal;
        }
        break;

      case 'Orijinal HD':
        // Doğal renkler + Keskinleştirme
        filtered = applySharpenKernel(source);
        break;

      case 'Magic AI':
      default:
        // CamScanner Sihirli Netlik Modu:
        // Mühür ve renkli imzaları koru + Kağıdı bembeyaz yap + Yazıları koyulaştır!
        final sharp = applySharpenKernel(source);
        filtered = img.Image.from(sharp);
        for (final p in filtered) {
          final r = p.r;
          final g = p.g;
          final b = p.b;
          final l = (0.299 * r + 0.587 * g + 0.114 * b).round();
          final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
          final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
          final diff = maxC - minC;

          if (diff > 30) {
            // Renkli unsur (mavi tükenmez kalem, kırmızı mühür, renkli logo)
            final scale = l < 130 ? 0.8 : 1.15;
            p.r = (r * scale).clamp(0, 255).round();
            p.g = (g * scale).clamp(0, 255).round();
            p.b = (b * scale).clamp(0, 255).round();
          } else {
            // Gri/siyah yazı veya kağıt zemini
            if (l > 148) {
              // Kağıt zemini -> Bembeyaz (255)
              final boost = ((l - 148) * 2.4).round();
              final v = (l + boost).clamp(0, 255);
              p.r = v;
              p.g = v;
              p.b = v;
            } else {
              // Yazı / Mürekkep -> Belirgin ve koyu
              final v = (l * 0.45).clamp(0, 255).round();
              p.r = v;
              p.g = v;
              p.b = v;
            }
          }
        }
        break;
    }

    final jpgBytes = img.encodeJpg(filtered, quality: 94);
    if (jpgBytes.isEmpty) {
      return imageBytes;
    }
    return Uint8List.fromList(jpgBytes);
  }

  /// Aktif dile göre OCR dil kodunu belirler (Tüm 19 dili kapsar)
  static String _getOcrLanguageCode([String? locale]) {
    final active = (locale ?? LocalizationService.currentLocale).toLowerCase();
    if (active.startsWith('ar')) return 'ara';
    if (active.startsWith('ru')) return 'rus';
    if (active.startsWith('zh')) return 'chs';
    if (active.startsWith('ja')) return 'jpn';
    if (active.startsWith('ko')) return 'kor';
    if (active.startsWith('hi')) return 'hin';
    if (active.startsWith('tr')) return 'tur';
    if (active.startsWith('de')) return 'ger';
    if (active.startsWith('fr')) return 'fre';
    if (active.startsWith('es')) return 'spa';
    if (active.startsWith('pt')) return 'por';
    if (active.startsWith('it')) return 'ita';
    if (active.startsWith('nl')) return 'dut';
    if (active.startsWith('pl')) return 'pol';
    return 'eng';
  }

  /// Harici ekranlar için doğrudan görselden çok dilli metin ayrıştırma metodu
  static Future<Map<String, dynamic>> extractTextFromImageBytes(
    Uint8List imageBytes, {
    required String sourceName,
    String? languageCode,
    bool cvLayout = false,
    String fileType = 'JPG',
  }) async {
    return _runOcr(
      imageBytes,
      sourceName: sourceName,
      languageCode: languageCode,
      cvLayout: cvLayout,
      fileType: fileType,
    );
  }

  static Future<Map<String, dynamic>> _runOcr(
    Uint8List imageBytes, {
    required String sourceName,
    String? languageCode,
    bool cvLayout = false,
    String fileType = 'JPG',
  }) async {
    const apiKey = 'K83073189488957';
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/$sourceName-${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(imageBytes);

    final lang = languageCode ?? _getOcrLanguageCode();
    final isAsianOrArabic = ['chs', 'jpn', 'kor', 'ara', 'rus'].contains(lang);

    final uri = Uri.parse('https://api.ocr.space/parse/image');
    final request = http.MultipartRequest('POST', uri)
      ..fields['apikey'] = apiKey
      ..fields['language'] = cvLayout ? 'auto' : lang
      ..fields['isOverlayRequired'] = cvLayout ? 'true' : 'false'
      ..fields['filetype'] = fileType
      ..fields['OCREngine'] = cvLayout ? '3' : (isAsianOrArabic ? '1' : '2')
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response =
          await request.send().timeout(Duration(seconds: cvLayout ? 90 : 15));
      final body = await response.stream
          .bytesToString()
          .timeout(const Duration(seconds: 90));
      if (response.statusCode != 200) {
        return {'text': '', 'confidence': 0.0};
      }

      final decoded = jsonDecode(body);
      final parsed = decoded['ParsedResults'] as List? ?? const [];
      if (cvLayout &&
          (decoded['IsErroredOnProcessing'] == true ||
              decoded['OCRExitCode'].toString() != '1')) {
        return {'text': '', 'confidence': 0.0};
      }
      if (parsed.isEmpty) {
        return {'text': '', 'confidence': 0.0};
      }

      final first = parsed.first as Map<String, dynamic>;
      final text = cvLayout
          ? parsed
              .map((page) => (page['ParsedText'] ?? '').toString().trim())
              .join('\n\n')
          : (first['ParsedText'] ?? '').toString().trim();
      final confidence = (first['TextOverlay']?['Lines'] is List) ? 0.95 : 0.88;

      return {'text': text, 'confidence': confidence};
    } catch (e) {
      debugPrint('Cloud OCR error: $e');
      return {'text': '', 'confidence': 0.0};
    } finally {
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  static Future<Uint8List> _readConvertedFileResponse(
      dynamic decodedBody) async {
    final files = decodedBody['Files'];
    if (files is List && files.isNotEmpty) {
      final first = files.first;
      if (first is Map) {
        final fileData = first['FileData'];
        final fileUrl = first['Url'];
        if (fileData is String && fileData.isNotEmpty) {
          try {
            return base64Decode(fileData);
          } catch (_) {}
        }
        if (fileUrl is String && fileUrl.isNotEmpty) {
          final fileResponse = await http
              .get(Uri.parse(fileUrl))
              .timeout(const Duration(seconds: 45));
          if (fileResponse.statusCode == 200 &&
              fileResponse.bodyBytes.isNotEmpty) {
            return fileResponse.bodyBytes;
          }
        }
      }
    }

    final directFileData = decodedBody['FileData'];
    if (directFileData is String && directFileData.isNotEmpty) {
      try {
        return base64Decode(directFileData);
      } catch (_) {}
    }

    final directUrl = decodedBody['Url'];
    if (directUrl is String && directUrl.isNotEmpty) {
      final fileResponse = await http
          .get(Uri.parse(directUrl))
          .timeout(const Duration(seconds: 45));
      if (fileResponse.statusCode == 200 && fileResponse.bodyBytes.isNotEmpty) {
        return fileResponse.bodyBytes;
      }
    }

    throw Exception('ConvertAPI returned no valid file payload');
  }

  static Future<Uint8List> convertWordToPdfBytes(Uint8List fileBytes,
      {required String fileName}) async {
    try {
      const bearerToken = 'JovWahdJsfFwBpQ2AzWdiEgmyVAfoWol';
      final payload = {
        'Parameters': [
          {
            'Name': 'File',
            'FileValue': {
              'Name': fileName,
              'Data': base64Encode(fileBytes),
            },
          },
          {
            'Name': 'StoreFile',
            'Value': true,
          },
        ],
      };

      final response = await http
          .post(
            Uri.parse('https://v2.convertapi.com/convert/docx/to/pdf'),
            headers: {
              'Authorization': 'Bearer $bearerToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return await _readConvertedFileResponse(decoded);
      }

      debugPrint('ConvertAPI error: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('WordToPdf API conversion error: $e');
    }

    throw Exception('Word to PDF conversion API failed');
  }

  static Future<Uint8List> convertPdfToDocxBytes(Uint8List fileBytes,
      {required String fileName}) async {
    try {
      const bearerToken = 'BhWMs6993PdCe8nL6d06Z23xlxuxnsr1';
      final payload = {
        'Parameters': [
          {
            'Name': 'File',
            'FileValue': {
              'Name': fileName,
              'Data': base64Encode(fileBytes),
            },
          },
          {
            'Name': 'StoreFile',
            'Value': true,
          },
        ],
      };

      final response = await http
          .post(
            Uri.parse('https://v2.convertapi.com/convert/pdf/to/docx'),
            headers: {
              'Authorization': 'Bearer $bearerToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return await _readConvertedFileResponse(decoded);
      }

      debugPrint('ConvertAPI error: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('PdfToDocx API conversion error: $e');
    }

    throw Exception('PDF to DOCX conversion API failed');
  }
}
