import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/responsive.dart';
import '../../features/settings/bloc/theme_cubit.dart';
import '../../l10n/app_localizations.dart';

/// The website's floating contact (headphones) button — opens the same
/// "Customer service / Online now" tooltip card the website shows, with
/// WhatsApp + call actions.
final class ContactFab extends StatelessWidget {
  const ContactFab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PositionedDirectional(
      start: context.rs(14),
      bottom: context.rs(96),
      child: FloatingActionButton.small(
        heroTag: 'contact-fab',
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
        elevation: 0,
        highlightElevation: 0,
        onPressed: () => _showContactPopup(context),
        child: const Icon(Icons.headset_mic_rounded, size: 20),
      ),
    );
  }
}

/// Anchored popup card above the contact FAB — website's contact tooltip
/// translated to mobile: header (avatar + "Customer service" + online dot +
/// close X) and two action tiles (WhatsApp chat, call us).
void _showContactPopup(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'contact',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, _, _) => const _ContactPopupCard(),
    transitionBuilder: (ctx, anim, _, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          // bottom-start, resolved for RTL (ScaleTransition needs Alignment).
          alignment: Directionality.of(ctx) == TextDirection.rtl
              ? Alignment.bottomRight
              : Alignment.bottomLeft,
          child: child,
        ),
      );
    },
  );
}

final class _ContactPopupCard extends StatelessWidget {
  const _ContactPopupCard();

  static const _waUrl = 'https://wa.me/966920018996';
  static const _phone = '920018996';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: context.rs(14),
            bottom: context.rs(148),
            end: context.rs(40),
          ),
          child: Material(
            color: isDark ? const Color(0xFF1A1C21) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.rs(292)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header — brand strip like the website tooltip.
                  Container(
                    padding: EdgeInsetsDirectional.fromSTEB(context.rs(14),
                        context.rs(12), context.rs(6), context.rs(12)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          scheme.primary.withValues(alpha: 0.84),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: context.rs(40),
                          height: context.rs(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: const Icon(Icons.headset_mic_rounded,
                              color: Colors.white, size: 20),
                        ),
                        SizedBox(width: context.rs(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.contactPopTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: context.rs(2)),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF35D07F),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: context.rs(5)),
                                  Text(
                                    t.contactPopOnline,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  // Actions.
                  Padding(
                    padding: EdgeInsets.all(context.rs(10)),
                    child: Column(
                      children: [
                        _ContactActionTile(
                          color: const Color(0xFF25D366),
                          icon: Icons.chat_rounded,
                          title: t.contactPopWhatsApp,
                          subtitle: _phone,
                          onTap: () {
                            Navigator.of(context).pop();
                            launchUrl(Uri.parse(_waUrl),
                                mode: LaunchMode.externalApplication);
                          },
                        ),
                        SizedBox(height: context.rs(8)),
                        _ContactActionTile(
                          color: scheme.primary,
                          icon: Icons.call_rounded,
                          title: t.contactPopCall,
                          subtitle: _phone,
                          onTap: () {
                            Navigator.of(context).pop();
                            launchUrl(Uri.parse('tel:$_phone'));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ContactActionTile extends StatelessWidget {
  const _ContactActionTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF6F7F9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.rs(12), vertical: context.rs(10)),
          child: Row(
            children: [
              Container(
                width: context.rs(36),
                height: context.rs(36),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: scheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline Toyota ⇄ Lexus switch — the reference design's stacked header
/// control: a white vertical capsule with both brand roundels, the active
/// one lifted on a solid brand-colored circle. Not floating — callers
/// place it inline (home greeting, guest hero).
final class BrandSwitchCapsule extends StatelessWidget {
  const BrandSwitchCapsule({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.watch<ThemeCubit>().state.brandKey;
    final cubit = context.read<ThemeCubit>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLexus = brandKey == 'lexus';

    Widget roundel(String asset, bool active, String toBrand) =>
        GestureDetector(
          onTap: () => cubit.setBrand(toBrand),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: context.rs(38),
            height: context.rs(38),
            padding: EdgeInsets.all(context.rs(8)),
            decoration: BoxDecoration(
              color: active ? scheme.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: active
                // Active roundel: white emblem on the solid brand circle.
                ? Image.asset(asset,
                    fit: BoxFit.contain, color: scheme.onPrimary)
                : Opacity(
                    opacity: 0.45,
                    child: Image.asset(asset, fit: BoxFit.contain)),
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: EdgeInsets.all(context.rs(4)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B21) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          roundel('assets/logos/toyota-ico.png', !isLexus, 'toyota'),
          SizedBox(height: context.rs(4)),
          roundel('assets/logos/lexus-ico.png', isLexus, 'lexus'),
        ],
      ),
    );
  }
}
