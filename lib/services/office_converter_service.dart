import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'document_parser_service.dart';
import 'package:mobile_app/services/localization_service.dart';

class OfficeConverterService {
  /// Converts plain or structured text/paragraphs from Word into a styled Microsoft Excel (.xlsx) file
  static Uint8List createXlsxFromText({
    required String title,
    required List<String> paragraphs,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[defaultSheet];

    // 1. Title Row
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(title);
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1E40AF'),
    );

    // 2. Header Row
    final headers = [LocalizationService.tr('doc_table_no'), LocalizationService.tr('doc_table_section'), LocalizationService.tr('doc_table_content')];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        backgroundColorHex: ExcelColor.fromHexString('#2563EB'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // 3. Data Rows
    int rowIdx = 3;
    int itemNo = 1;
    String currentSection = 'Genel';

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      final isHeading = trimmed.length < 60 &&
          (trimmed.toUpperCase() == trimmed || trimmed.endsWith(':') || trimmed.startsWith('#'));

      if (isHeading) {
        currentSection = trimmed.replaceAll('#', '').replaceAll(':', '').trim();
      } else {
        // Col 0: No
        final noCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
        noCell.value = IntCellValue(itemNo);
        noCell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

        // Col 1: Section
        final sectionCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
        sectionCell.value = TextCellValue(currentSection);
        sectionCell.cellStyle = CellStyle(bold: true);

        // Col 2: Content
        final contentCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx));
        contentCell.value = TextCellValue(trimmed);

        itemNo++;
        rowIdx++;
      }
    }

    // Auto fit column widths roughly
    sheet.setColumnWidth(0, 8.0);
    sheet.setColumnWidth(1, 24.0);
    sheet.setColumnWidth(2, 65.0);

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Converts PowerPoint slides into a structured Microsoft Excel (.xlsx) file
  static Uint8List createXlsxFromSlides({
    required String title,
    required List<PptxSlide> slides,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sunum_Verileri';
    final sheet = excel[defaultSheet];

    // 1. Title Row
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(title);
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#D97706'),
    );

    // 2. Header Row
    final headers = [LocalizationService.tr('slide_no'), LocalizationService.tr('slide_title'), LocalizationService.tr('slide_content')];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        backgroundColorHex: ExcelColor.fromHexString('#D97706'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // 3. Data Rows
    int rowIdx = 3;
    for (final slide in slides) {
      final noCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
      noCell.value = IntCellValue(slide.index);
      noCell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

      final titleColCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
      titleColCell.value = TextCellValue(slide.title);
      titleColCell.cellStyle = CellStyle(bold: true);

      final contentColCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx));
      final joinedBullets = slide.bulletPoints.isNotEmpty
          ? slide.bulletPoints.map((b) => '• $b').join('\n')
          : '(Metin yok)';
      contentColCell.value = TextCellValue(joinedBullets);

      rowIdx++;
    }

    sheet.setColumnWidth(0, 12.0);
    sheet.setColumnWidth(1, 30.0);
    sheet.setColumnWidth(2, 60.0);

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Converts a 2D Excel matrix/grid into a genuine Microsoft Word (.docx) table document
  static Uint8List createDocxFromGrid({
    required String title,
    required List<List<String>> grid,
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

    // 3. word/document.xml with Table
    final docBuffer = StringBuffer();
    docBuffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    docBuffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n');
    docBuffer.write('  <w:body>\n');

    // Title
    final cleanTitle = _escapeXml(title);
    docBuffer.write('    <w:p>\n');
    docBuffer.write('      <w:pPr><w:jc w:val="center"/><w:spacing w:after="240"/></w:pPr>\n');
    docBuffer.write('      <w:r>\n');
    docBuffer.write('        <w:rPr><w:b/><w:sz w:val="36"/><w:color w:val="059669"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
    docBuffer.write('        <w:t>$cleanTitle</w:t>\n');
    docBuffer.write('      </w:r>\n');
    docBuffer.write('    </w:p>\n');

    // Table
    if (grid.isNotEmpty) {
      docBuffer.write('    <w:tbl>\n');
      docBuffer.write('      <w:tblPr>\n');
      docBuffer.write('        <w:tblW w:w="5000" w:type="pct"/>\n');
      docBuffer.write('        <w:tblBorders>\n');
      docBuffer.write('          <w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>\n');
      docBuffer.write('          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>\n');
      docBuffer.write('          <w:left w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>\n');
      docBuffer.write('          <w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>\n');
      docBuffer.write('          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>\n');
      docBuffer.write('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>\n');
      docBuffer.write('        </w:tblBorders>\n');
      docBuffer.write('      </w:tblPr>\n');

      for (int r = 0; r < grid.length; r++) {
        final row = grid[r];
        final isHeaderRow = r == 0;
        docBuffer.write('      <w:tr>\n');
        for (final cell in row) {
          final cleanCell = _escapeXml(cell);
          docBuffer.write('        <w:tc>\n');
          docBuffer.write('          <w:tcPr>\n');
          if (isHeaderRow) {
            docBuffer.write('            <w:shd w:val="clear" w:color="auto" w:fill="059669"/>\n');
          } else if (r % 2 == 1) {
            docBuffer.write('            <w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/>\n');
          }
          docBuffer.write('            <w:tcMar><w:top w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/><w:left w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/></w:tcMar>\n');
          docBuffer.write('          </w:tcPr>\n');
          docBuffer.write('          <w:p>\n');
          docBuffer.write('            <w:pPr><w:spacing w:after="0"/></w:pPr>\n');
          docBuffer.write('            <w:r>\n');
          if (isHeaderRow) {
            docBuffer.write('              <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="FFFFFF"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
          } else {
            docBuffer.write('              <w:rPr><w:sz w:val="20"/><w:color w:val="1E293B"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
          }
          docBuffer.write('              <w:t>$cleanCell</w:t>\n');
          docBuffer.write('            </w:r>\n');
          docBuffer.write('          </w:p>\n');
          docBuffer.write('        </w:tc>\n');
        }
        docBuffer.write('      </w:tr>\n');
      }

      docBuffer.write('    </w:tbl>\n');
    }

    docBuffer.write('    <w:sectPr/>\n');
    docBuffer.write('  </w:body>\n');
    docBuffer.write('</w:document>');

    final docBytes = utf8.encode(docBuffer.toString());
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(zipBytes ?? []);
  }

  /// Converts PowerPoint slides into a structured Microsoft Word (.docx) document
  static Uint8List createDocxFromSlides({
    required String title,
    required List<PptxSlide> slides,
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

    // 3. word/document.xml with slides
    final docBuffer = StringBuffer();
    docBuffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    docBuffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n');
    docBuffer.write('  <w:body>\n');

    // Title
    final cleanTitle = _escapeXml(title);
    docBuffer.write('    <w:p>\n');
    docBuffer.write('      <w:pPr><w:jc w:val="center"/><w:spacing w:after="300"/></w:pPr>\n');
    docBuffer.write('      <w:r>\n');
    docBuffer.write('        <w:rPr><w:b/><w:sz w:val="38"/><w:color w:val="D97706"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
    docBuffer.write('        <w:t>$cleanTitle</w:t>\n');
    docBuffer.write('      </w:r>\n');
    docBuffer.write('    </w:p>\n');

    // Slides
    for (final slide in slides) {
      final cleanSlideTitle = _escapeXml(slide.title);

      // Slide header banner
      docBuffer.write('    <w:p>\n');
      docBuffer.write('      <w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>\n');
      docBuffer.write('      <w:r>\n');
      docBuffer.write('        <w:rPr><w:b/><w:sz w:val="26"/><w:color w:val="D97706"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
      docBuffer.write('        <w:t>Slayt ${slide.index}: $cleanSlideTitle</w:t>\n');
      docBuffer.write('      </w:r>\n');
      docBuffer.write('    </w:p>\n');

      for (final bullet in slide.bulletPoints) {
        final cleanBullet = _escapeXml(bullet);
        docBuffer.write('    <w:p>\n');
        docBuffer.write('      <w:pPr><w:ind w:left="400"/><w:spacing w:after="80"/></w:pPr>\n');
        docBuffer.write('      <w:r>\n');
        docBuffer.write('        <w:rPr><w:sz w:val="22"/><w:color w:val="334155"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>\n');
        docBuffer.write('        <w:t>• $cleanBullet</w:t>\n');
        docBuffer.write('      </w:r>\n');
        docBuffer.write('    </w:p>\n');
      }
    }

    docBuffer.write('    <w:sectPr/>\n');
    docBuffer.write('  </w:body>\n');
    docBuffer.write('</w:document>');

    final docBytes = utf8.encode(docBuffer.toString());
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(zipBytes ?? []);
  }

  /// Converts Word/text paragraphs into a genuine Microsoft PowerPoint (.pptx) PresentationML archive
  static Uint8List createPptxFromParagraphs({
    required String title,
    required List<String> paragraphs,
  }) {
    final archive = Archive();

    // Group paragraphs into slides (3 to 5 bullet points each)
    final slideDataList = <_SlideData>[];
    String currentSlideTitle = title;
    final currentBullets = <String>[];

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      final isHeading = trimmed.length < 60 &&
          (trimmed.toUpperCase() == trimmed || trimmed.endsWith(':') || trimmed.startsWith('#'));

      if (isHeading) {
        if (currentBullets.isNotEmpty) {
          slideDataList.add(_SlideData(title: currentSlideTitle, bullets: List.from(currentBullets)));
          currentBullets.clear();
        }
        currentSlideTitle = trimmed.replaceAll('#', '').replaceAll(':', '').trim();
      } else {
        currentBullets.add(trimmed);
        if (currentBullets.length >= 4) {
          slideDataList.add(_SlideData(title: currentSlideTitle, bullets: List.from(currentBullets)));
          currentBullets.clear();
        }
      }
    }

    if (currentBullets.isNotEmpty || slideDataList.isEmpty) {
      slideDataList.add(_SlideData(
        title: currentSlideTitle.isNotEmpty ? currentSlideTitle : 'Sunum',
        bullets: currentBullets.isNotEmpty ? currentBullets : [LocalizationService.tr('general_overview_details')],
      ));
    }

    // 1. [Content_Types].xml
    final contentTypesBuffer = StringBuffer();
    contentTypesBuffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    contentTypesBuffer.write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n');
    contentTypesBuffer.write('  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n');
    contentTypesBuffer.write('  <Default Extension="xml" ContentType="application/xml"/>\n');
    contentTypesBuffer.write('  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>\n');

    for (int i = 1; i <= slideDataList.length; i++) {
      contentTypesBuffer.write('  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>\n');
    }
    contentTypesBuffer.write('</Types>');

    final contentTypesBytes = utf8.encode(contentTypesBuffer.toString());
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes));

    // 2. _rels/.rels
    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
    final rootRelsBytes = utf8.encode(rootRelsXml);
    archive.addFile(ArchiveFile('_rels/.rels', rootRelsBytes.length, rootRelsBytes));

    // 3. ppt/presentation.xml
    final presBuffer = StringBuffer();
    presBuffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    presBuffer.write('<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n');
    presBuffer.write('  <p:sldIdLst>\n');
    for (int i = 1; i <= slideDataList.length; i++) {
      presBuffer.write('    <p:sldId id="${255 + i}" r:id="rId$i"/>\n');
    }
    presBuffer.write('  </p:sldIdLst>\n');
    presBuffer.write('  <p:sldSz cx="9144000" cy="5143500"/>\n');
    presBuffer.write('</p:presentation>');

    final presBytes = utf8.encode(presBuffer.toString());
    archive.addFile(ArchiveFile('ppt/presentation.xml', presBytes.length, presBytes));

    // 4. ppt/_rels/presentation.xml.rels
    final presRelsBuffer = StringBuffer();
    presRelsBuffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    presRelsBuffer.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    for (int i = 1; i <= slideDataList.length; i++) {
      presRelsBuffer.write('  <Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>\n');
    }
    presRelsBuffer.write('</Relationships>');

    final presRelsBytes = utf8.encode(presRelsBuffer.toString());
    archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', presRelsBytes.length, presRelsBytes));

    // 5. ppt/slides/slideX.xml
    for (int i = 0; i < slideDataList.length; i++) {
      final s = slideDataList[i];
      final slideXml = _generatePptxSlideXml(s.title, s.bullets);
      final slideBytes = utf8.encode(slideXml);
      archive.addFile(ArchiveFile('ppt/slides/slide${i + 1}.xml', slideBytes.length, slideBytes));
    }

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(zipBytes ?? []);
  }

  static String _generatePptxSlideXml(String slideTitle, List<String> bullets) {
    final cleanTitle = _escapeXml(slideTitle);
    final buffer = StringBuffer();

    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">\n');
    buffer.write('  <p:cSld>\n');
    buffer.write('    <p:spTree>\n');
    buffer.write('      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>\n');
    buffer.write('      <p:grpSpPr/>\n');

    // Title Shape
    buffer.write('      <p:sp>\n');
    buffer.write('        <p:nvSpPr><p:cNvPr id="2" name="Title"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>\n');
    buffer.write('        <p:spPr><a:xfrm><a:off x="685800" y="609600"/><a:ext cx="7772400" cy="1000000"/></a:xfrm></p:spPr>\n');
    buffer.write('        <p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:pPr algn="ctr"/><a:r><a:rPr sz="3200" b="1"><a:solidFill><a:srgbClr val="2563EB"/></a:solidFill></a:rPr><a:t>$cleanTitle</a:t></a:r></a:p></p:txBody>\n');
    buffer.write('      </p:sp>\n');

    // Content Shape
    buffer.write('      <p:sp>\n');
    buffer.write('        <p:nvSpPr><p:cNvPr id="3" name="Content"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>\n');
    buffer.write('        <p:spPr><a:xfrm><a:off x="685800" y="1800000"/><a:ext cx="7772400" cy="3000000"/></a:xfrm></p:spPr>\n');
    buffer.write('        <p:txBody><a:bodyPr/><a:lstStyle/>\n');

    for (final b in bullets) {
      final cleanBullet = _escapeXml(b);
      buffer.write('          <a:p><a:pPr lvl="0"/><a:r><a:rPr sz="1800"><a:solidFill><a:srgbClr val="1E293B"/></a:solidFill></a:rPr><a:t>• $cleanBullet</a:t></a:r></a:p>\n');
    }

    buffer.write('        </p:txBody>\n');
    buffer.write('      </p:sp>\n');

    buffer.write('    </p:spTree>\n');
    buffer.write('  </p:cSld>\n');
    buffer.write('</p:sld>');

    return buffer.toString();
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _SlideData {
  final String title;
  final List<String> bullets;

  _SlideData({required this.title, required this.bullets});
}
