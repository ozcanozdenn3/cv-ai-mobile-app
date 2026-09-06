import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/document_parser_service.dart';

void main() {
  test('parseDocx keeps heading and table cell data for PDF conversion', () async {
    const xml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
      <w:r><w:t>Başlık</w:t></w:r>
    </w:p>
    <w:p><w:r><w:t>Normal paragraf</w:t></w:r></w:p>
    <w:tbl>
      <w:tr>
        <w:tc><w:p><w:r><w:t>Hücre 1</w:t></w:r></w:p></w:tc>
        <w:tc><w:p><w:r><w:t>Hücre 2</w:t></w:r></w:p></w:tc>
      </w:tr>
    </w:tbl>
  </w:body>
</w:document>
''';

    final xmlBytes = utf8.encode(xml);
    final archive = Archive();
    archive.addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));
    final docxBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

    final parsed = await DocumentParserService.parseDocx(docxBytes);

    expect(parsed, contains('Başlık'));
    expect(parsed, contains('Normal paragraf'));
    expect(parsed, contains('Hücre 1'));
    expect(parsed, contains('Hücre 2'));
  });
}
