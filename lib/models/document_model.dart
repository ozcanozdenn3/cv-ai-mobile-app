import '../services/localization_service.dart';

enum DocumentType {
  cv,
  scannedDocument,
  imageToPdf,
  signedContract,
  invoice,
}

class DocumentModel {
  final String id;
  final String title;
  final DocumentType type;
  final DateTime createdAt;
  final int pageCount;
  final String fileSize;
  final String? previewImage;
  final String? filePath;
  final String? fileUrl;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.pageCount,
    required this.fileSize,
    this.previewImage,
    this.filePath,
    this.fileUrl,
  });

  DocumentModel copyWith({
    String? id,
    String? title,
    DocumentType? type,
    DateTime? createdAt,
    int? pageCount,
    String? fileSize,
    String? previewImage,
    String? filePath,
    String? fileUrl,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      previewImage: previewImage ?? this.previewImage,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  String get typeLabel {
    switch (type) {
      case DocumentType.cv:
        return '📄 ${LocalizationService.tr('doc_type_cv')}';
      case DocumentType.scannedDocument:
        return '📸 ${LocalizationService.tr('doc_type_scan')}';
      case DocumentType.imageToPdf:
        return '🖼️ ${LocalizationService.tr('doc_type_img')}';
      case DocumentType.signedContract:
        return '✍️ ${LocalizationService.tr('doc_type_contract')}';
      case DocumentType.invoice:
        return '🧾 ${LocalizationService.tr('doc_type_invoice')}';
    }
  }
}

