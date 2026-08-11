/// Models for the maintenance hub — the mobile mirror of the website's
/// /maintenance page + /maintenance/periodic dataset.
library;

/// One row of the periodic payload (`DataType` "Detail" = a km tab,
/// "Note" = one of the four footnote blocks). Mirrors the website's
/// MaintenancePeriodicRowDto verbatim.
final class PeriodicRow {
  const PeriodicRow({
    required this.dataType,
    required this.id,
    this.maintenanceAr,
    this.maintenanceEn,
    this.titleAr,
    this.titleEn,
    this.contentAr,
    this.contentEn,
    this.subTitleAr,
    this.subTitleEn,
  });

  factory PeriodicRow.fromJson(Map<String, dynamic> j) => PeriodicRow(
        dataType: '${j['dataType'] ?? ''}',
        id: (j['id'] as num?)?.toInt() ?? 0,
        maintenanceAr: j['maintenanceAr'] as String?,
        maintenanceEn: j['maintenanceEn'] as String?,
        titleAr: j['titleAr'] as String?,
        titleEn: j['titleEn'] as String?,
        contentAr: j['contentAr'] as String?,
        contentEn: j['contentEn'] as String?,
        subTitleAr: j['subTitleAr'] as String?,
        subTitleEn: j['subTitleEn'] as String?,
      );

  final String dataType;
  final int id;
  final String? maintenanceAr;
  final String? maintenanceEn;
  final String? titleAr;
  final String? titleEn;
  final String? contentAr;
  final String? contentEn;
  final String? subTitleAr;
  final String? subTitleEn;

  String tab(String lang) =>
      (lang == 'ar' ? maintenanceAr : maintenanceEn) ?? maintenanceEn ?? '';
  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? '';
  String subTitle(String lang) =>
      (lang == 'ar' ? subTitleAr : subTitleEn) ?? subTitleEn ?? '';
  String content(String lang) =>
      (lang == 'ar' ? contentAr : contentEn) ?? contentEn ?? '';

  /// SUPRA / URBAN CRUISER / GR86 tabs group tasks by mileage sub-blocks —
  /// the same special-case the legacy site and the new website apply.
  bool get mileageGrouped =>
      maintenanceEn == 'SUPRA' ||
      maintenanceEn == 'URBAN CRUISER' ||
      maintenanceEn == 'GR86';
}

/// The `/maintenance/periodic` payload: tab details + footnote blocks.
final class PeriodicData {
  const PeriodicData({required this.details, required this.notes});

  factory PeriodicData.fromJson(Map<String, dynamic> j) => PeriodicData(
        details: [
          for (final d in (j['details'] as List? ?? const []))
            PeriodicRow.fromJson(d as Map<String, dynamic>)
        ],
        notes: [
          for (final n in (j['notes'] as List? ?? const []))
            PeriodicRow.fromJson(n as Map<String, dynamic>)
        ],
      );

  final List<PeriodicRow> details;
  final List<PeriodicRow> notes;
}

/// Guest testimonial — the website maintenance page's "Guest feedback" rows.
final class Testimonial {
  const Testimonial({
    required this.id,
    this.nameAr,
    this.nameEn,
    this.contentAr,
    this.contentEn,
    this.image,
  });

  factory Testimonial.fromJson(Map<String, dynamic> j) => Testimonial(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nameAr: j['nameAr'] as String?,
        nameEn: j['nameEn'] as String?,
        contentAr: j['contentAr'] as String?,
        contentEn: j['contentEn'] as String?,
        image: j['image'] as String?,
      );

  final int id;
  final String? nameAr;
  final String? nameEn;
  final String? contentAr;
  final String? contentEn;
  final String? image;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? '';
  String content(String lang) =>
      (lang == 'ar' ? contentAr : contentEn) ?? contentEn ?? '';
}

/// A subgroup inside a mileage-grouped section (e.g. "10,000 km:" bullets).
final class PeriodicSubgroup {
  const PeriodicSubgroup({required this.title, required this.items});

  final String title;
  final List<String> items;
}

/// One expandable panel of a tab: `\d-` header + its bullet lines.
final class PeriodicSection {
  const PeriodicSection({
    required this.title,
    required this.items,
    this.subgroups = const [],
  });

  final String title;
  final List<String> items;
  final List<PeriodicSubgroup> subgroups;
}

final _headerRe = RegExp(r'^\d-');
final _headerStripRe = RegExp(r'^\d-\s*');
final _bulletStripRe = RegExp(r'^[-•]\s*');
final _splitBlocksRe = RegExp(r'(?=\d-)');

/// Faithful port of the website's parseSections heuristic: `\d-` lines are
/// section headers, bullets join the current section; mileage-grouped tabs
/// (SUPRA / URBAN CRUISER / GR86) nest mileage sub-blocks instead.
List<PeriodicSection> parsePeriodicSections(
    String content, bool mileageGrouped) {
  if (content.isEmpty) return const [];

  if (mileageGrouped) {
    final blocks =
        content.split(_splitBlocksRe).where((b) => b.trim().isNotEmpty);
    final out = <PeriodicSection>[];
    for (final block in blocks) {
      final lines = block
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;
      final title = lines.first.replaceFirst(_headerStripRe, '').trim();
      final subgroups = <PeriodicSubgroup>[];
      String? currentTitle;
      var currentItems = <String>[];
      void flush() {
        if (currentTitle != null || currentItems.isNotEmpty) {
          subgroups.add(PeriodicSubgroup(
              title: currentTitle ?? '', items: currentItems));
        }
      }

      for (final line in lines.skip(1)) {
        final isBullet = line.startsWith('-') || line.startsWith('•');
        if (!isBullet) {
          flush();
          currentTitle =
              line.endsWith(':') ? line.substring(0, line.length - 1) : line;
          currentItems = <String>[];
        } else {
          currentTitle ??= '';
          currentItems.add(line.replaceFirst(_bulletStripRe, ''));
        }
      }
      flush();
      out.add(PeriodicSection(title: title, items: const [], subgroups: subgroups));
    }
    return out;
  }

  final lines = content
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty);
  final out = <PeriodicSection>[];
  String? currentTitle;
  var currentItems = <String>[];
  void flush() {
    final title = currentTitle;
    if (title != null) {
      out.add(PeriodicSection(title: title, items: currentItems));
    }
  }

  for (final line in lines) {
    if (_headerRe.hasMatch(line)) {
      flush();
      currentTitle = line.replaceFirst(_headerStripRe, '');
      currentItems = <String>[];
    } else if (currentTitle != null) {
      currentItems.add(line.replaceFirst(_bulletStripRe, ''));
    }
  }
  flush();
  return out;
}

/// Port of the website's parseNoteTable: blank-line-separated blocks, first
/// line = row title, rest = its detail bullets.
List<(String, List<String>)> parsePeriodicNoteTable(String content) {
  if (content.isEmpty) return const [];
  final out = <(String, List<String>)>[];
  for (final block in content.split(RegExp(r'\r?\n\r?\n'))) {
    final lines = block
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) continue;
    final title = lines.first.endsWith(':')
        ? lines.first.substring(0, lines.first.length - 1)
        : lines.first;
    out.add((
      title,
      [for (final l in lines.skip(1)) l.replaceFirst(_bulletStripRe, '')],
    ));
  }
  return out;
}
