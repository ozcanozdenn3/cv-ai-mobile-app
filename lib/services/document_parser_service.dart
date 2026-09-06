import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:mobile_app/services/localization_service.dart';

class DocumentParserService {
  /// Gerçek Word (.docx) dosyasını arşivden açıp XML metinlerini ayrıştırır.
  static Future<String> parseDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentFile = archive.findFile('word/document.xml');

      if (documentFile == null) {
        return _fallbackTextDecode(bytes);
      }

      final xmlString = utf8.decode(documentFile.content as List<int>, allowMalformed: true);
      final document = XmlDocument.parse(xmlString);

      final buffer = StringBuffer();

      final tableBlocks = document.findAllElements('w:tbl');
      if (tableBlocks.isNotEmpty) {
        for (final table in tableBlocks) {
          final tableText = _extractTableText(table);
          if (tableText.trim().isNotEmpty) {
            buffer.writeln(tableText);
            buffer.writeln();
          }
        }
      }

      final paragraphs = document.findAllElements('w:p');
      for (final p in paragraphs) {
        if (p.parentElement?.name.local == 'w:tc') {
          continue;
        }

        final pText = _extractParagraphText(p).trim();
        if (pText.isEmpty) {
          continue;
        }

        final pStyle = p.findAllElements('w:pStyle').firstOrNull;
        final styleVal = pStyle?.getAttribute('w:val') ?? '';
        final normalizedStyle = styleVal.toLowerCase();

        if (normalizedStyle.contains('heading1') || normalizedStyle.contains('title')) {
          buffer.writeln('# $pText');
        } else if (normalizedStyle.contains('heading2') || normalizedStyle.contains('subtitle')) {
          buffer.writeln('## $pText');
        } else if (normalizedStyle.contains('list') || normalizedStyle.contains('bullet')) {
          buffer.writeln('- $pText');
        } else {
          buffer.writeln(pText);
        }
      }

      final result = buffer.toString().trim();
      return result.isNotEmpty ? result : _fallbackTextDecode(bytes);
    } catch (e) {
      debugPrint('Docx parser error: $e');
      return _fallbackTextDecode(bytes);
    }
  }

  static String _extractParagraphText(XmlElement paragraph) {
    final values = StringBuffer();

    for (final node in paragraph.descendants) {
      if (node is XmlElement) {
        final localName = node.name.local;
        if (localName == 't') {
          values.write(node.innerText);
        } else if (localName == 'tab') {
          values.write('\t');
        } else if (localName == 'br' || localName == 'cr') {
          values.write('\n');
        } else if (localName == 'pPr' || localName == 'rPr') {
          continue;
        }
      }
    }

    return values.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _extractTableText(XmlElement table) {
    final rows = <String>[];

    for (final row in table.findAllElements('w:tr')) {
      final cells = <String>[];

      for (final cell in row.findAllElements('w:tc')) {
        final cellText = cell.findAllElements('w:p').map(_extractParagraphText).where((value) => value.isNotEmpty).join(' | ');
        cells.add(cellText.trim());
      }

      final rowText = cells.where((value) => value.isNotEmpty).join('  \t  ');
      if (rowText.isNotEmpty) {
        rows.add(rowText);
      }
    }

    return rows.join('\n');
  }

  /// Gerçek Excel (.xlsx) dosyasını ayrıştırıp 2D tablo matrisine dönüştürür.
  static Future<List<List<String>>> parseXlsx(Uint8List bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final List<List<String>> tableRows = [];

      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        for (final row in sheet.rows) {
          final rowData = row.map((cell) {
            if (cell == null || cell.value == null) return '';
            return cell.value.toString().trim();
          }).toList();

          // Boş satırları filtrele
          if (rowData.any((c) => c.isNotEmpty)) {
            tableRows.add(rowData);
          }
        }

        // İlk dolu sayfayı al
        if (tableRows.isNotEmpty) break;
      }

      if (tableRows.isNotEmpty) {
        return tableRows;
      }
    } catch (e) {
      debugPrint('Xlsx parser error: $e');
    }

    return _fallbackCsvDecode(bytes);
  }

  /// CSV / TSV metin ayrıştırıcı
  static List<List<String>> parseCsv(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final List<List<String>> grid = [];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final cells = line.split(RegExp(r'[,;\t]')).map((c) => c.trim()).toList();
      grid.add(cells);
    }

    return grid;
  }

  /// Gerçek PowerPoint (.pptx) dosyasını ayrıştırıp sunum slaytlarına dönüştürür.
  static Future<List<PptxSlide>> parsePptx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final List<ArchiveFile> slideFiles = [];

      for (final file in archive.files) {
        if (RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(file.name)) {
          slideFiles.add(file);
        }
      }

      // Slayt numarasına göre sırala (slide1, slide2, slide3...)
      slideFiles.sort((a, b) {
        final numA = int.tryParse(RegExp(r'\d+').firstMatch(a.name)?.group(0) ?? '0') ?? 0;
        final numB = int.tryParse(RegExp(r'\d+').firstMatch(b.name)?.group(0) ?? '0') ?? 0;
        return numA.compareTo(numB);
      });

      final List<PptxSlide> slides = [];

      for (int i = 0; i < slideFiles.length; i++) {
        final sFile = slideFiles[i];
        final xmlString = utf8.decode(sFile.content as List<int>, allowMalformed: true);
        final doc = XmlDocument.parse(xmlString);

        String title = '';
        final List<String> bullets = [];

        final paragraphs = doc.findAllElements('a:p');
        for (final p in paragraphs) {
          final tElements = p.findAllElements('a:t');
          final pText = tElements.map((t) => t.innerText).join('').trim();
          if (pText.isEmpty) continue;

          if (title.isEmpty) {
            title = pText;
          } else {
            bullets.add(pText);
          }
        }

        slides.add(
          PptxSlide(
            index: i + 1,
            title: title.isNotEmpty ? title : 'Slayt ${i + 1}',
            bulletPoints: bullets,
          ),
        );
      }

      if (slides.isNotEmpty) {
        return slides;
      }
    } catch (e) {
      debugPrint('Pptx parser error: $e');
    }

    // Fallback: extract any plain text lines and make slides
    final lines = _fallbackTextDecode(bytes)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 2)
        .take(15)
        .toList();

    if (lines.isNotEmpty) {
      return [
        PptxSlide(
          index: 1,
          title: lines.first,
          bulletPoints: lines.skip(1).take(5).toList(),
        ),
      ];
    }

    return [
      PptxSlide(
        index: 1,
        title: 'PowerPoint Sunumu',
        bulletPoints: [LocalizationService.tr('pptx_bullet_1'), LocalizationService.tr('pptx_bullet_2'), LocalizationService.tr('pptx_bullet_3')],
      ),
    ];
  }

  /// Gerçek PDF dosyasını ayrıştırıp içindeki metinleri çıkarır.
  /// FlateDecode sıkıştırmalı akışları ve uncompressed BT...ET bloklarını çözer.
  /// Asla ham binary dökümünü rastgele metin diye döndürmez.
  static Future<String> parsePdf(Uint8List bytes) async {
    final buffer = StringBuffer();

    // 1. Doğrudan uncompressed metin bloklarını ara (BT ... ET)
    try {
      final rawStr = latin1.decode(bytes);
      _extractTextFromPdfContent(rawStr, buffer);
    } catch (_) {}

    // 2. Stream bloklarını bulup FlateDecode (zlib) açmayı dene
    try {
      final streamRegex = RegExp(r'stream\r?\n([\s\S]*?)\r?\nendstream');
      final rawStr = latin1.decode(bytes);
      for (final match in streamRegex.allMatches(rawStr)) {
        final streamData = match.group(1);
        if (streamData == null || streamData.isEmpty) continue;
        final streamBytes = Uint8List.fromList(latin1.encode(streamData));
        try {
          final decompressed = const ZLibDecoder().decodeBytes(streamBytes, verify: false);
          final decompressedStr = latin1.decode(decompressed);
          _extractTextFromPdfContent(decompressedStr, buffer);
        } catch (_) {
          // Decompression hatası veya şifreli/resim akışı, atla
        }
      }
    } catch (_) {}

    final extracted = buffer.toString().trim();
    if (extracted.length >= 10) {
      return _cleanPdfText(extracted);
    }

    // 3. Fallback: Eğer BT..ET yoksa, yalnızca temiz ve okunabilir kelime dizilimlerini topla.
    final fallbackText = _extractPrintableWords(bytes);
    return fallbackText;
  }

  static void _extractTextFromPdfContent(String content, StringBuffer buffer) {
    final btRegExp = RegExp(r'BT[\s\S]*?ET');
    for (final match in btRegExp.allMatches(content)) {
      final block = match.group(0) ?? '';

      // (Metin) Tj veya ' veya "
      final tjRegExp = RegExp(r'\((.*?)\)\s*(?:Tj|\x27|\x22)', dotAll: true);
      for (final tj in tjRegExp.allMatches(block)) {
        final txt = tj.group(1) ?? '';
        final unescaped = _unescapePdf(txt);
        if (unescaped.trim().isNotEmpty) {
          buffer.write('$unescaped ');
        }
      }

      // [(Metin1) 20 (Metin2)] TJ
      final arrayTjRegExp = RegExp(r'\[([\s\S]*?)\]\s*TJ');
      for (final atj in arrayTjRegExp.allMatches(block)) {
        final inner = atj.group(1) ?? '';
        final innerMatches = RegExp(r'\((.*?)\)', dotAll: true).allMatches(inner);
        for (final im in innerMatches) {
          final txt = im.group(1) ?? '';
          final unescaped = _unescapePdf(txt);
          if (unescaped.trim().isNotEmpty) {
            buffer.write('$unescaped ');
          }
        }
      }
    }
  }

  static String _unescapePdf(String input) {
    return input
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', r'\');
  }

  static String _cleanPdfText(String text) {
    return text
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _extractPrintableWords(Uint8List bytes) {
    try {
      final raw = latin1.decode(bytes);
      final wordMatches = RegExp(r'[A-Za-zçÇğĞıİöÖşŞüÜ0-9@.+_/-]{3,}').allMatches(raw);
      final words = <String>[];
      for (final m in wordMatches) {
        final w = m.group(0) ?? '';
        if (w.startsWith('/') || w.startsWith('obj') || w.startsWith('xref')) continue;
        if (w.contains('FlateDecode') || w.contains('FontDescriptor') || w.contains('MediaBox')) continue;
        words.add(w);
      }
      if (words.length >= 6) {
        return words.join(' ');
      }
    } catch (_) {}
    return '';
  }

  static String _fallbackTextDecode(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  static List<List<String>> _fallbackCsvDecode(Uint8List bytes) {
    final text = _fallbackTextDecode(bytes);
    return parseCsv(text);
  }
}

class PptxSlide {
  final int index;
  final String title;
  final List<String> bulletPoints;

  const PptxSlide({
    required this.index,
    required this.title,
    required this.bulletPoints,
  });
}
