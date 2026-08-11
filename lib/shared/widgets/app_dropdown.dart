import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// One selectable option for [AppDropdown].
final class AppDropdownItem<T> {
  const AppDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.leading,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  /// Custom leading widget (e.g. a bank logo); wins over [icon].
  final Widget? leading;
}

/// The app's professional replacement for Material's default dropdown:
/// a soft-card field that opens a branded bottom-sheet picker (drag
/// handle, title, auto search for long lists, 48pt rows, selected row
/// tinted in the brand color with a check).
///
/// Drop-in shape: `AppDropdown<T>(label:, value:, items:, onChanged:)`.
/// Wrap in a [FormField] externally only if validation display is needed —
/// [errorText] renders the same way as InputDecoration errors.
final class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.sheetTitle,
    this.enabled = true,
    this.errorText,
    this.dense = false,
  });

  final String label;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final T? value;
  final String? hint;

  /// Title shown at the top of the picker sheet; defaults to [label].
  final String? sheetTitle;
  final bool enabled;
  final String? errorText;

  /// Tighter vertical padding for use inside crowded sheets.
  final bool dense;

  AppDropdownItem<T>? get _selected {
    for (final it in items) {
      if (it.value == value) return it;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showAppPicker<T>(
      context,
      title: sheetTitle ?? label,
      items: items,
      selected: value,
    );
    if (picked != null) onChanged(picked as T);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sel = _selected;
    final hasError = (errorText ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
              start: 4, bottom: context.rs(6)),
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.rf(12),
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && items.isNotEmpty ? () => _open(context) : null,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF181B21)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? scheme.error
                      : scheme.outline.withValues(alpha: 0.55),
                  width: hasError ? 1.4 : 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(14),
                  vertical: context.rs(dense ? 11 : 14),
                ),
                child: Row(
                  children: [
                    if (sel?.leading != null) ...[
                      SizedBox(width: 26, height: 26, child: sel!.leading),
                      SizedBox(width: context.rs(9)),
                    ] else if (sel?.icon != null) ...[
                      Icon(sel!.icon, size: 18, color: scheme.primary),
                      SizedBox(width: context.rs(9)),
                    ],
                    Expanded(
                      child: Opacity(
                        opacity: enabled ? 1 : 0.45,
                        child: Text(
                          sel?.label ?? hint ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rf(13.5),
                            fontWeight:
                                sel == null ? FontWeight.w400 : FontWeight.w700,
                            color: sel == null
                                ? scheme.onSurface.withValues(alpha: 0.45)
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsetsDirectional.only(
                start: 6, top: context.rs(5)),
            child: Text(
              errorText!,
              style: TextStyle(
                  fontSize: context.rf(11), color: scheme.error),
            ),
          ),
      ],
    );
  }
}

/// The branded picker sheet behind [AppDropdown]; usable directly for
/// one-off pickers. Returns the chosen value or null on dismiss.
Future<T?> showAppPicker<T>(
  BuildContext context, {
  required String title,
  required List<AppDropdownItem<T>> items,
  T? selected,
  bool searchable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickerSheet<T>(
      title: title,
      items: items,
      selected: selected,
      searchable: searchable || items.length > 8,
    ),
  );
}

final class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.searchable,
  });

  final String title;
  final List<AppDropdownItem<T>> items;
  final T? selected;
  final bool searchable;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

final class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where((i) =>
                i.label.toLowerCase().contains(_query.toLowerCase()) ||
                (i.subtitle ?? '')
                    .toLowerCase()
                    .contains(_query.toLowerCase()))
            .toList();
    final maxH = MediaQuery.of(context).size.height * 0.72;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15171C) : scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: context.rs(10)),
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(20), context.rs(14), context.rs(20), 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                        fontSize: context.rf(16),
                        fontWeight: FontWeight.w800),
                  ),
                ),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16),
                  ),
                ),
              ],
            ),
          ),
          if (widget.searchable)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(18), context.rs(12), context.rs(18), 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  filled: true,
                  fillColor: scheme.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                ),
              ),
            ),
          SizedBox(height: context.rs(8)),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(context.rs(14), context.rs(4),
                  context.rs(14), context.rs(18) + MediaQuery.of(context).padding.bottom),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => SizedBox(height: context.rs(6)),
              itemBuilder: (context, i) {
                final it = filtered[i];
                final isSel = it.value == widget.selected;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(it.value),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: isSel
                            ? scheme.primary.withValues(alpha: 0.09)
                            : scheme.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel
                              ? scheme.primary.withValues(alpha: 0.55)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(14),
                            vertical: context.rs(12)),
                        child: Row(
                          children: [
                            if (it.leading != null) ...[
                              SizedBox(
                                  width: 30, height: 30, child: it.leading),
                              SizedBox(width: context.rs(10)),
                            ] else if (it.icon != null) ...[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      scheme.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(it.icon,
                                    size: 17, color: scheme.primary),
                              ),
                              SizedBox(width: context.rs(10)),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: context.rf(13.5),
                                      fontWeight: isSel
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSel
                                          ? scheme.primary
                                          : scheme.onSurface,
                                    ),
                                  ),
                                  if ((it.subtitle ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        it.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: context.rf(11),
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSel)
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
