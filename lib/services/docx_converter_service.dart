import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'localization_service.dart';

class DocxConverterService {
  /// Generates a valid Microsoft Word (.docx) OpenXML binary archive from structured paragraphs
  static Uint8List createDocxFromText({
    required String title,
    required List<String> paragraphs,
    String? author,
  }) {
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    final contentTypesBytes = utf8.encode(contentTypesXml);
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes));

    // 2. _rels/.rels
    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    final relsBytes = utf8.encode(relsXml);
    archive.addFile(ArchiveFile('_rels/.rels', relsBytes.length, relsBytes));

    // 3. word/document.xml
    final docBuffer = StringBuffer();
    docBuffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    docBuffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n');
    docBuffer.write('  <w:body>\n');

    // Title Paragraph (Large, Bold, Blue Accent)
    final cleanTitle = _escapeXml(title);
    docBuffer.write('    <w:p>\n');
    docBuffer.write('      <w:pPr><w:jc w:val="center"/><w:spacing w:after="240"/></w:pPr>\n');
    docBuffer.write('      <w:r>\n');
    docBuffer.write('        <w:rPr><w:b/><w:sz w:val="36"/><w:color w:val="1E40AF"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
    docBuffer.write('        <w:t>$cleanTitle</w:t>\n');
    docBuffer.write('      </w:r>\n');
    docBuffer.write('    </w:p>\n');

    // Paragraphs
    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      final isHeading = trimmed.length < 50 && (trimmed.toUpperCase() == trimmed || trimmed.endsWith(':'));
      final cleanText = _escapeXml(trimmed);

      docBuffer.write('    <w:p>\n');
      if (isHeading) {
        docBuffer.write('      <w:pPr><w:spacing w:before="200" w:after="100"/></w:pPr>\n');
        docBuffer.write('      <w:r>\n');
        docBuffer.write('        <w:rPr><w:b/><w:sz w:val="26"/><w:color w:val="0F172A"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
        docBuffer.write('        <w:t>$cleanText</w:t>\n');
        docBuffer.write('      </w:r>\n');
      } else {
        docBuffer.write('      <w:pPr><w:spacing w:after="120"/><w:line w:line="276" w:lineRule="auto"/></w:pPr>\n');
        docBuffer.write('      <w:r>\n');
        docBuffer.write('        <w:rPr><w:sz w:val="22"/><w:color w:val="334155"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
        docBuffer.write('        <w:t>$cleanText</w:t>\n');
        docBuffer.write('      </w:r>\n');
      }
      docBuffer.write('    </w:p>\n');
    }

    docBuffer.write('    <w:sectPr/>\n');
    docBuffer.write('  </w:body>\n');
    docBuffer.write('</w:document>');

    final docBytes = utf8.encode(docBuffer.toString());
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    // Encode as Zip
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(zipBytes ?? []);
  }

  /// Extracts readable text strings from raw PDF binary data
  static List<String> extractTextLinesFromPdf(Uint8List pdfBytes) {
    try {
      final rawString = latin1.decode(pdfBytes);
      final lines = <String>[];

      // Regex matching PDF text blocks: (text) Tj or [(text)] TJ
      final tjRegex = RegExp(r'\((.*?)\)\s*Tj');
      final matches = tjRegex.allMatches(rawString);

      for (final m in matches) {
        final matchText = m.group(1) ?? '';
        final unescaped = _unescapePdfString(matchText);
        if (unescaped.trim().isNotEmpty) {
          lines.add(unescaped.trim());
        }
      }

      // If regex found blocks, return consolidated lines
      if (lines.isNotEmpty) {
        return lines;
      }

      // Fallback: split raw plain ascii chunks
      final chunkRegex = RegExp(r'BT\s+(.*?)\s+ET', dotAll: true);
      final chunkMatches = chunkRegex.allMatches(rawString);
      for (final cm in chunkMatches) {
        final block = cm.group(1) ?? '';
        final blockTjs = tjRegex.allMatches(block);
        for (final bt in blockTjs) {
          final t = _unescapePdfString(bt.group(1) ?? '').trim();
          if (t.isNotEmpty) lines.add(t);
        }
      }

      if (lines.isNotEmpty) {
        return lines;
      }

      // Last fallback: generic text lines
      return [LocalizationService.tr('converter_pdf_extracted')];
    } catch (_) {
      return [LocalizationService.tr('default_converted_doc_title')];
    }
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _unescapePdfString(String input) {
    return input
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\r', '\n')
        .replaceAll(r'\n', ' ');
  }
}
