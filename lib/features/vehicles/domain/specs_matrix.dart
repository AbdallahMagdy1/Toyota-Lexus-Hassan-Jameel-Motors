import 'vehicle_models.dart';

/// One spec line: label + value per trim slug ('✓' = plain checkmark row).
final class SpecRow {
  const SpecRow({required this.label, required this.values});

  final String label;
  final Map<String, String> values; // trimSlug -> value

  /// True when the selected trims don't all share the same value.
  bool differsAcross(Iterable<String> trimSlugs) {
    final vals = trimSlugs.map((s) => (values[s] ?? '—').trim()).toSet();
    return vals.length > 1;
  }
}

final class SpecSection {
  const SpecSection({required this.title, required this.rows});

  final String title;
  final List<SpecRow> rows;
}

/// The website's buildSpecsMatrix (VehicleDetail.tsx): each equipment
/// description+note line becomes a spec row — "label: value" splits on the
/// first colon, a colon-less line becomes a '✓' checkmark row, labels
/// longer than 80 chars are dropped. Row/section order = first-seen order.
List<SpecSection> buildSpecsMatrix(List<EquipmentRow> equipments, String lang) {
  final sectionOrder = <String>[];
  // section -> (label order, label -> trimSlug -> value)
  final sections = <String, (List<String>, Map<String, Map<String, String>>)>{};

  for (final e in equipments) {
    final sec = e.section(lang).trim();
    final slug = e.trimSlug ?? '';
    if (sec.isEmpty || slug.isEmpty) continue;

    final text = [e.description(lang), e.note(lang)]
        .where((s) => s.trim().isNotEmpty)
        .join('\n');

    for (var line in text.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;

      final ci = line.indexOf(':');
      String label;
      String value;
      if (ci > 0 && ci < line.length - 1) {
        label = line.substring(0, ci).trim();
        value = line.substring(ci + 1).trim();
      } else {
        label = line.replaceAll(':', '').trim();
        value = '✓';
      }
      if (label.isEmpty || label.length > 80) continue;

      final bucket = sections.putIfAbsent(sec, () {
        sectionOrder.add(sec);
        return (<String>[], <String, Map<String, String>>{});
      });
      final byLabel = bucket.$2.putIfAbsent(label, () {
        bucket.$1.add(label);
        return <String, String>{};
      });
      byLabel.putIfAbsent(slug, () => value);
    }
  }

  return [
    for (final sec in sectionOrder)
      SpecSection(
        title: sec,
        rows: [
          for (final label in sections[sec]!.$1)
            SpecRow(label: label, values: sections[sec]!.$2[label]!),
        ],
      ),
  ];
}

/// Trims that actually appear in the equipment matrix, in trims-list order.
List<VehicleTrim> trimsInMatrix(
    List<VehicleTrim> trims, List<EquipmentRow> equipments) {
  final present = equipments.map((e) => e.trimSlug).whereType<String>().toSet();
  final filtered = trims.where((t) => present.contains(t.slug)).toList();
  return filtered.isEmpty ? trims : filtered;
}
