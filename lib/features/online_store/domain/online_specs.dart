import '../../vehicles/domain/vehicle_models.dart';

/// One spec line: "label: value" pair, or a plain feature bullet (value null).
final class OnlineSpecLine {
  const OnlineSpecLine(this.label, [this.value]);

  final String label;
  final String? value;
}

/// One tab of the "مواصفات السيارة" section (عام / الاضافات الخارجية / …).
final class OnlineSpecSection {
  const OnlineSpecSection(this.title, this.lines);

  final String title;
  final List<OnlineSpecLine> lines;
}

/// This stock car's own trim rows — the website's OnlineDetail filter
/// (`trimSlug === slug || trimProductId === productId`); the endpoint returns
/// every trim of the model group + year.
List<EquipmentRow> equipmentsForTrim(
    List<EquipmentRow> rows, String? slug, String? productId) {
  final s = (slug ?? '').toLowerCase();
  final p = (productId ?? '').trim();
  return rows
      .where((r) =>
          (s.isNotEmpty && (r.trimSlug ?? '').toLowerCase() == s) ||
          (p.isNotEmpty && (r.trimProductId ?? '').trim() == p))
      .toList();
}

/// Port of the website's buildSpecSections (OnlineDetail.tsx): rows sorted by
/// sectionId and grouped by section title; each description/note line is
/// trimmed of a leading "-"/"•"; "Label: value" (label ≤ 60 chars) becomes a
/// pair, anything else a feature bullet; duplicates dropped.
List<OnlineSpecSection> buildOnlineSpecSections(
    List<EquipmentRow> rows, String lang) {
  final sorted = [...rows]
    ..sort((a, b) => (a.sectionId ?? 0).compareTo(b.sectionId ?? 0));
  final order = <String>[];
  final sections = <String, List<OnlineSpecLine>>{};
  final bullet = RegExp(r'^[-•]\s*');

  for (final r in sorted) {
    final title = r.section(lang).trim();
    if (title.isEmpty) continue;
    final lines = [r.description(lang), r.note(lang)]
        .where((s) => s.trim().isNotEmpty)
        .join('\n')
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim().replaceFirst(bullet, ''))
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) continue;

    final list = sections.putIfAbsent(title, () {
      order.add(title);
      return <OnlineSpecLine>[];
    });
    for (final line in lines) {
      final c = line.indexOf(':');
      final label = c > 0 ? line.substring(0, c).trim() : line;
      final value = c > 0 ? line.substring(c + 1).trim() : '';
      final next = value.isNotEmpty && label.length <= 60
          ? OnlineSpecLine(label, value)
          : OnlineSpecLine(line);
      if (!list.any((l) => l.label == next.label && l.value == next.value)) {
        list.add(next);
      }
    }
  }
  return [for (final t in order) OnlineSpecSection(t, sections[t]!)];
}

/// "GRAY METALLIC /BEIGE" → ("GRAY METALLIC", "BEIGE") — exterior / interior.
(String?, String?) splitColorName(String name) {
  if (name.trim().isEmpty) return (null, null);
  final i = name.indexOf('/');
  if (i < 0) return (name.trim(), null);
  final ext = name.substring(0, i).trim();
  final inner = name.substring(i + 1).trim();
  return (ext.isEmpty ? null : ext, inner.isEmpty ? null : inner);
}
