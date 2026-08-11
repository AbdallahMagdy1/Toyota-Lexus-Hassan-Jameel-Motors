import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../shared/navigation/sheet_routes.dart' show SheetHandle;

/// Small building blocks shared by the profile-hub sheets.

/// Bilingual literal for the few strings that have no l10n key (the app
/// already does this for one-off strings, e.g. the side-menu group labels).
String bi(String lang, {required String ar, required String en}) =>
    lang == 'ar' ? ar : en;

/// Labeled input in the app's style: visible label ABOVE the field, themed
/// OutlineInputBorder field, error below.
final class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.suffix,
    this.textDirection,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final Widget? suffix;
  final TextDirection? textDirection;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4, bottom: context.rs(6)),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.rf(12),
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          textDirection: textDirection,
          maxLines: maxLines,
          autocorrect: false,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            errorMaxLines: 2,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Full-width primary action with a busy spinner — every sheet's save.
final class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: destructive ? scheme.error : null,
        foregroundColor: destructive ? scheme.onError : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle:
            TextStyle(fontSize: context.rf(14.5), fontWeight: FontWeight.w800),
      ),
      onPressed: (busy || !enabled) ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
          : Text(label),
    );
  }
}

/// Opens a profile sheet the app's way: root navigator (covers the shell's
/// bottom nav), scroll-controlled, top radius 24, keyboard-aware.
Future<T?> showProfileSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: builder,
  );
}

/// Handle + title row + scrollable body + pinned-in-scroll footer, padded
/// above the keyboard — the shared chrome of every profile sheet.
final class ProfileSheetShell extends StatelessWidget {
  const ProfileSheetShell({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.maxHeightFactor = 0.88,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height * maxHeightFactor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(8), context.rs(20), 0),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: context.rs(34),
                      height: context.rs(34),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 17, color: scheme.primary),
                    ),
                    SizedBox(width: context.rs(10)),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                          fontSize: context.rf(17),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
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
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(14),
                    context.rs(20), context.rs(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
