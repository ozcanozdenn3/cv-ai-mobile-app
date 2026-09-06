import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cv_model.dart';

/// Continuation layout for content that cannot fit in a template's fixed blocks.
class CvPdfFlow {
  static bool needsPagination(CvModel cv) => cv.summary.length > 900 ||
      cv.fullName.length > 65 || cv.email.length > 65 ||
      cv.experiences.any((e) => e.description.length > 1100 || e.position.length > 65) ||
      cv.projects.any((p) => p.description.length > 1100) ||
      cv.skills.length > 18 || cv.references.length > 4 ||
      cv.educations.length > 5 || cv.experiences.length > 6 ||
      cv.customSections.any((s) => s.items.join().length > 1000);

  static List<String> _paragraphs(String value) {
    final result = <String>[];
    for (final paragraph in value.split('\n')) {
      var rest = paragraph.trim();
      while (rest.length > 400) {
        var end = rest.lastIndexOf(' ', 400);
        if (end < 1) end = 400;
        result.add(rest.substring(0, end));
        rest = rest.substring(end).trimLeft();
      }
      if (rest.isNotEmpty) result.add(rest);
    }
    return result;
  }

  static void build(pw.Document pdf, CvModel cv, pw.ThemeData theme,
      String Function(CvSectionType) title, String present) {
    final color = PdfColor.fromInt(cv.primaryColorHex);
    final classic = [CvTemplate.executiveClassic, CvTemplate.harvardAcademic,
      CvTemplate.minimalistPure, CvTemplate.cleanNordic].contains(cv.template);
    final sections = <pw.Widget>[];
    void text(String value, {bool bold = false, double size = 9}) {
      for (final part in _paragraphs(value)) {
        sections.add(pw.Text(part, style: pw.TextStyle(fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          lineSpacing: 2), overflow: pw.TextOverflow.span));
        sections.add(pw.SizedBox(height: 3));
      }
    }
    void heading(String label) {
      sections.add(pw.SizedBox(height: 10));
      for (final part in _paragraphs(label)) {
        sections.add(pw.Text(part, style: pw.TextStyle(fontSize: 11,
            fontWeight: pw.FontWeight.bold, color: color)));
      }
      sections.add(pw.Divider(color: color, thickness: classic ? .5 : 1.5));
    }
    String joined(Iterable<String> values) => values.where((s) => s.trim().isNotEmpty).join(' | ');
    for (final section in cv.sectionOrder.toSet()) {
      switch(section) {
        case CvSectionType.summary:
          if(cv.summary.isNotEmpty) { heading(title(section)); text(cv.summary); }
          break;
        case CvSectionType.experiences:
          final items = cv.experiences.where((e) => joined([e.position,e.company,e.description]).isNotEmpty);
          if(items.isNotEmpty) heading(title(section));
          for(final e in items) {
            text(e.position, bold:true); text(e.company, bold:true);
            text(joined([e.startDate, e.isCurrent ? present : e.endDate]));
            text(e.description); sections.add(pw.SizedBox(height:6));
          }
          break;
        case CvSectionType.educations:
          final items=cv.educations.where((e)=>joined([e.school,e.degree,e.field]).isNotEmpty);
          if(items.isNotEmpty) heading(title(section));
          for(final e in items) {
            text(e.school,bold:true); text(joined([e.degree,e.field]));
            text(joined([e.startDate,e.endDate,e.gpa]));
          }
          break;
        case CvSectionType.skills:
          if(cv.skills.isNotEmpty) heading(title(section));
          for(final s in cv.skills) { text(joined([s.name,s.levelLabel])); }
          break;
        case CvSectionType.languages:
          final items=cv.languages.where((l)=>l.language.isNotEmpty);
          if(items.isNotEmpty) heading(title(section));
          for(final l in items) { text(joined([l.language,l.level])); }
          break;
        case CvSectionType.personalTraits:
          if(cv.personalTraits.isNotEmpty) heading(title(section));
          for(final t in cv.personalTraits) { text(t); }
          break;
        case CvSectionType.projects:
          final items=cv.projects.where((p)=>joined([p.name,p.description]).isNotEmpty);
          if(items.isNotEmpty) heading(title(section));
          for(final p in items) {
            text(p.name,bold:true); text(joined([p.role,p.date]));
            text(p.description); text(p.technologies); text(p.link);
          }
          break;
        case CvSectionType.certificates:
          final items=cv.certificates.where((c)=>c.name.isNotEmpty);
          if(items.isNotEmpty) heading(title(section));
          for(final c in items) { text(c.name,bold:true); text(joined([c.issuer,c.date])); text(c.credentialUrl); }
          break;
        case CvSectionType.references:
          final items=cv.references.where((r)=>joined([r.name,r.email,r.phone]).isNotEmpty);
          if(items.isNotEmpty) heading(title(section));
          for(final r in items) { text(r.name,bold:true); text(joined([r.position,r.company])); text(r.phone); text(r.email); }
          break;
        case CvSectionType.customSections:
          for(final s in cv.customSections) { heading(s.title); for(final item in s.items) { text(item); } }
          break;
      }
    }
    final header = <pw.Widget>[];
    if(cv.hasPhoto && cv.profilePhotoBytes != null && cv.profilePhotoBytes!.isNotEmpty) {
      header.add(pw.Image(pw.MemoryImage(cv.profilePhotoBytes!),width:64,height:64,fit:pw.BoxFit.cover));
    }
    for(final part in _paragraphs(cv.fullName)) {
      header.add(pw.Text(part,style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold,color:color)));
    }
    for(final value in [cv.jobTitle,cv.email,cv.phone,cv.location,cv.linkedin,cv.github,cv.portfolioUrl]) {
      for(final part in _paragraphs(value)) { header.add(pw.Text(part,style:const pw.TextStyle(fontSize:9))); }
    }
    pdf.addPage(pw.MultiPage(theme:theme,pageFormat:PdfPageFormat.a4,
      maxPages:1000,margin:const pw.EdgeInsets.all(32),
      footer:(context)=>pw.Align(alignment:pw.Alignment.centerRight,
        child:pw.Text('${context.pageNumber} / ${context.pagesCount}',style:const pw.TextStyle(fontSize:8))),
      build:(context)=>[...header,pw.Divider(color:color,thickness:classic?1:3),...sections]));
  }
}
