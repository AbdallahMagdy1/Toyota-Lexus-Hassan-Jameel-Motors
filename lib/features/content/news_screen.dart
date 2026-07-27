import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/navigation/sheet_routes.dart';
import '../../shared/widgets/app_header.dart';
import '../home/presentation/widgets/home_bits.dart';
import '../settings/bloc/locale_cubit.dart';
import '../settings/bloc/theme_cubit.dart';
import 'content_models.dart';
import 'content_repository.dart';

/// News — the website's /news for mobile: one payload, brand-filtered
/// client-side, article opens as a sheet.
final class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _NewsCubit(ContentRepository(sl<ApiClient>())),
      child: const _NewsView(),
    );
  }
}

final class _NewsState extends Equatable {
  const _NewsState({this.loading = true, this.items = const []});

  final bool loading;
  final List<NewsItem> items;

  @override
  List<Object?> get props => [loading, items];
}

final class _NewsCubit extends Cubit<_NewsState> {
  _NewsCubit(this._repo) : super(const _NewsState()) {
    load();
  }

  final ContentRepository _repo;

  Future<void> load() async {
    emit(const _NewsState());
    final items = await _repo.news();
    if (!isClosed) emit(_NewsState(loading: false, items: items));
  }
}

final class _NewsView extends StatelessWidget {
  const _NewsView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<_NewsCubit>().state;
    final cubit = context.read<_NewsCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    final wantedDbId = brandKey == 'lexus' ? '2' : '1';
    final scheme = Theme.of(context).colorScheme;
    final items =
        state.items.where((n) => n.visibleForBrand(wantedDbId)).toList();

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(context.rs(16),
                        context.rs(18), context.rs(16), context.rs(110)),
                    children: [
                      Text(t.newsTitle,
                          style: TextStyle(
                              fontSize: context.rf(24),
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: context.rs(2)),
                      Text(t.newsSubtitle,
                          style: TextStyle(
                              fontSize: context.rf(12),
                              color:
                                  scheme.onSurface.withValues(alpha: 0.55))),
                      SizedBox(height: context.rs(16)),
                      if (items.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(context.rs(30)),
                          child: Center(child: Text(t.newsEmpty)),
                        ),
                      for (final (i, n) in items.indexed)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rs(14)),
                          child: HomeCard(
                            onTap: () => _openArticle(context, n, lang),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HomeImage(
                                    url: n.image,
                                    aspectRatio: 16 / 8,
                                    logicalWidth: 400),
                                Padding(
                                  padding: EdgeInsets.all(context.rs(14)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.title(lang),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: context.rf(15),
                                            fontWeight: FontWeight.w800,
                                            height: 1.3),
                                      ),
                                      if (n.excerpt(lang).isNotEmpty) ...[
                                        SizedBox(height: context.rs(4)),
                                        Text(
                                          n.excerpt(lang),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: context.rf(11.5),
                                              height: 1.45,
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.6)),
                                        ),
                                      ],
                                      if (n.createdDate != null) ...[
                                        SizedBox(height: context.rs(6)),
                                        Text(
                                          n.createdDate!
                                              .toIso8601String()
                                              .substring(0, 10),
                                          textDirection: TextDirection.ltr,
                                          style: TextStyle(
                                              fontSize: context.rf(10),
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.45)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: (35 * (i % 5)).ms).fadeIn(
                              duration: 220.ms),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _openArticle(BuildContext context, NewsItem n, String lang) {
    showHeroBottomSheet<void>(
      context,
      builder: (_) => _ArticleSheet(item: n, lang: lang),
    );
  }
}

final class _ArticleSheet extends StatefulWidget {
  const _ArticleSheet({required this.item, required this.lang});

  final NewsItem item;
  final String lang;

  @override
  State<_ArticleSheet> createState() => _ArticleSheetState();
}

final class _ArticleSheetState extends State<_ArticleSheet> {
  NewsItem? _detail;
  bool _loading = false;

  NewsItem get item => _detail ?? widget.item;
  String get lang => widget.lang;

  @override
  void initState() {
    super.initState();
    // The list rows don't carry the body — fetch the full article by slug
    // exactly like the website's /news/[slug].
    final slug = widget.item.slug;
    if (widget.item.content(lang).trim().isEmpty && (slug ?? '').isNotEmpty) {
      _loading = true;
      ContentRepository(sl<ApiClient>()).newsDetail(slug!).then((d) {
        if (!mounted) return;
        setState(() {
          _detail = d;
          _loading = false;
        });
      });
    }
  }

  /// The body is CKEditor HTML — strip it into readable paragraphs.
  static List<String> _paragraphs(String html) {
    var s = html
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
            RegExp(r'</\s*(p|div|h[1-6]|li|tr)\s*>', caseSensitive: false),
            '\n')
        .replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return s
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paragraphs = _paragraphs(item.content(lang));

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: context.rs(24)),
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: HomeImage(
                    url: item.image, aspectRatio: 16 / 9, logicalWidth: 480),
              ),
              const Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(child: SheetHandle()),
              ),
            ]),
            Padding(
              padding: EdgeInsets.all(context.rs(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title(lang),
                      style: TextStyle(
                          fontSize: context.rf(20),
                          fontWeight: FontWeight.w800,
                          height: 1.3)),
                  if (item.createdDate != null) ...[
                    SizedBox(height: context.rs(6)),
                    Text(
                      item.createdDate!.toIso8601String().substring(0, 10),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          fontSize: context.rf(11),
                          color: scheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                  SizedBox(height: context.rs(14)),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (paragraphs.isEmpty && item.excerpt(lang).isNotEmpty)
                    Text(item.excerpt(lang),
                        style: TextStyle(
                            fontSize: context.rf(13),
                            height: 1.7,
                            color: scheme.onSurface.withValues(alpha: 0.8)))
                  else
                    for (final p in paragraphs)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.rs(10)),
                        child: Text(p,
                            style: TextStyle(
                                fontSize: context.rf(13),
                                height: 1.7,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.8))),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
