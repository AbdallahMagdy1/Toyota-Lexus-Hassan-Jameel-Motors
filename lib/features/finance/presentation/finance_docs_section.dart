import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';

/// The website's FinanceDocUploads block, shared by BOTH finance dialogs
/// (finance-page modal and the offers finance dialog):
/// "Required documents — optional now…", the Employment-sector segmented
/// toggle (tap again to unset; GOSI insurance shows only for private sector),
/// then National ID/CR, driving license, salary certificate, [insurance],
/// bank statement. Files are image OR PDF, max 4 MB, base64 without prefix.
final class FinanceDocsSection extends StatelessWidget {
  const FinanceDocsSection({
    super.key,
    required this.needIdentity,
    required this.sector,
    required this.onSector,
    required this.docs,
    required this.docNames,
    required this.onDoc,
  });

  final bool needIdentity;

  /// '' unset | 'private' | 'governmental' — website FinanceSector.
  final String sector;
  final ValueChanged<String> onSector;
  final Map<String, String> docs;
  final Map<String, String> docNames;
  final void Function(String kind, String? base64, String? fileName) onDoc;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final rows = <(String, String)>[
      ('identityImage', needIdentity ? t.finIdDoc : t.finCommercialReg),
      ('license', t.finLicenseDoc),
      ('salaryDefinitionLetter', t.finSalaryDoc),
      if (sector == 'private') ('insurance', t.finInsuranceDoc),
      ('accountStatement', t.finStatementDoc),
    ];

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.finDocs,
              style: TextStyle(
                  fontSize: context.rf(13.5), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(3)),
          Text(t.finDocsHint,
              style: TextStyle(
                  fontSize: context.rf(10.5),
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.55))),
          SizedBox(height: context.rs(11)),
          // جهة العمل — tap the selected sector again to unset (website
          // toggle behaviour: sector === val ? "" : val).
          Text(t.finWorkSector,
              style: TextStyle(
                  fontSize: context.rf(11),
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
          SizedBox(height: context.rs(6)),
          Row(
            children: [
              for (final (v, label) in [
                ('private', t.finPrivate),
                ('governmental', t.finGov),
              ]) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSector(sector == v ? '' : v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: context.rs(9)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sector == v ? scheme.primary : scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sector == v
                              ? scheme.primary
                              : scheme.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: context.rf(11.5),
                          fontWeight: FontWeight.w800,
                          color: sector == v
                              ? scheme.onPrimary
                              : scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                if (v == 'private') SizedBox(width: context.rs(8)),
              ],
            ],
          ),
          SizedBox(height: context.rs(12)),
          for (final (kind, label) in rows)
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(8)),
              child: _DocRow(
                kind: kind,
                label: label,
                attachedName: docs[kind]?.isNotEmpty == true
                    ? (docNames[kind] ?? kind)
                    : null,
                onDoc: onDoc,
              ),
            ),
        ],
      ),
    );
  }
}

final class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.kind,
    required this.label,
    required this.attachedName,
    required this.onDoc,
  });

  final String kind;
  final String label;
  final String? attachedName; // null = not attached
  final void Function(String kind, String? base64, String? fileName) onDoc;

  /// Image or PDF ≤ 4MB — the website FileField's accept + size cap.
  Future<void> _pick(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    final bytes = file?.bytes;
    if (bytes == null) return;
    if (bytes.lengthInBytes > 4 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.finFileTooBig)));
      }
      return;
    }
    onDoc(kind, base64Encode(bytes), file?.name);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final attached = attachedName != null;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(12), vertical: context.rs(9)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: attached
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outline.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            attached ? Icons.check_circle_rounded : Icons.description_outlined,
            size: 18,
            color: attached
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.4),
          ),
          SizedBox(width: context.rs(9)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        fontWeight: FontWeight.w700)),
                if (attached)
                  Text(
                    attachedName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(9.5), color: scheme.primary),
                  ),
              ],
            ),
          ),
          if (attached)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => onDoc(kind, null, null),
              icon: Icon(Icons.close_rounded,
                  size: 16, color: scheme.onSurface.withValues(alpha: 0.5)),
            )
          else
            TextButton.icon(
              onPressed: () => _pick(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: scheme.primary,
              ),
              icon: const Icon(Icons.upload_rounded, size: 15),
              label: Text(t.finUpload,
                  style: TextStyle(
                      fontSize: context.rf(11), fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
