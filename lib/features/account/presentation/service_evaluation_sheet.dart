import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../settings/bloc/locale_cubit.dart';

/// تقييم الخدمة — the post-service rating (PSFU), the same questionnaire the
/// website serves at /ServiceEvaluation/{guid}. It opens from the tracking
/// journey once the car is delivered and the ERP still has the rating open,
/// so the customer finishes the whole cycle inside the app instead of
/// chasing an SMS link.
///
/// Question types come straight from the ERP:
///   1 — rating 0..10 (rendered as a numeric scale)
///   2 — single choice, and when TextYesNoFlag is set choosing the FIRST
///       option reveals a free-text box
///   3 — multi choice (independent checkboxes)
/// plus one overall note posted as the synthetic type 5.
Future<bool?> showServiceEvaluationSheet(
  BuildContext context, {
  required String guid,
  String? title,
}) =>
    showHeroBottomSheet<bool>(
      context,
      builder: (_) => _EvaluationSheet(guid: guid, title: title),
    );

/* ----------------------------- models ----------------------------- */

final class _Question {
  const _Question({
    required this.guid,
    required this.qid,
    required this.type,
    required this.mandatory,
    required this.textFlag,
    this.descAr,
    this.descEn,
    this.a1Ar,
    this.a2Ar,
    this.a3Ar,
    this.a1En,
    this.a2En,
    this.a3En,
  });

  final String guid;
  final int qid;
  final int type; // 1 rating · 2 single choice · 3 multi choice
  final bool mandatory;
  final bool textFlag;
  final String? descAr, descEn, a1Ar, a2Ar, a3Ar, a1En, a2En, a3En;

  String text(String lang) =>
      ((lang == 'ar' ? descAr : descEn) ?? descEn ?? descAr ?? '').trim();

  /// The three options, in order, dropping the blanks the ERP leaves for
  /// yes/no questions.
  List<({int index, String ar, String en})> options() {
    final raw = [
      (index: 1, ar: (a1Ar ?? '').trim(), en: (a1En ?? '').trim()),
      (index: 2, ar: (a2Ar ?? '').trim(), en: (a2En ?? '').trim()),
      (index: 3, ar: (a3Ar ?? '').trim(), en: (a3En ?? '').trim()),
    ];
    return raw.where((o) => o.ar.isNotEmpty || o.en.isNotEmpty).toList();
  }

  static _Question? fromJson(Map<String, dynamic> j) {
    final g = (j['guid'] ?? j['GUID'])?.toString();
    if (g == null || g.isEmpty) return null;
    return _Question(
      guid: g,
      qid: (j['qid'] as num?)?.toInt() ?? 0,
      type: (j['qTypeID'] as num?)?.toInt() ?? 0,
      mandatory: j['mandatory'] == true,
      textFlag: j['textYesNoFlag'] == true,
      descAr: j['qDescAr'] as String?,
      descEn: j['qDescEn'] as String?,
      a1Ar: j['answer1Ar'] as String?,
      a2Ar: j['answer2Ar'] as String?,
      a3Ar: j['answer3Ar'] as String?,
      a1En: j['answer1En'] as String?,
      a2En: j['answer2En'] as String?,
      a3En: j['answer3En'] as String?,
    );
  }
}

final class _Load {
  const _Load({
    this.found = false,
    this.pending = false,
    this.orderNo,
    this.vehicleName,
    this.plateNo,
    this.questions = const [],
  });

  final bool found;
  final bool pending;
  final String? orderNo;
  final String? vehicleName;
  final String? plateNo;
  final List<_Question> questions;
}

/* ------------------------------ cubit ------------------------------ */

enum _Phase { loading, form, done, missing, failed }

final class _State {
  const _State({
    this.phase = _Phase.loading,
    this.load = const _Load(),
    this.ratings = const {},
    this.choices = const {},
    this.texts = const {},
    this.multi = const {},
    this.note = '',
    this.missingGuids = const {},
    this.submitting = false,
  });

  final _Phase phase;
  final _Load load;
  final Map<String, int> ratings; // questionGuid -> 0..10
  final Map<String, int> choices; // questionGuid -> option index
  final Map<String, String> texts; // questionGuid -> free text
  final Map<String, Set<int>> multi; // questionGuid -> checked options
  final String note;
  final Set<String> missingGuids;
  final bool submitting;

  _State copyWith({
    _Phase? phase,
    _Load? load,
    Map<String, int>? ratings,
    Map<String, int>? choices,
    Map<String, String>? texts,
    Map<String, Set<int>>? multi,
    String? note,
    Set<String>? missingGuids,
    bool? submitting,
  }) =>
      _State(
        phase: phase ?? this.phase,
        load: load ?? this.load,
        ratings: ratings ?? this.ratings,
        choices: choices ?? this.choices,
        texts: texts ?? this.texts,
        multi: multi ?? this.multi,
        note: note ?? this.note,
        missingGuids: missingGuids ?? this.missingGuids,
        submitting: submitting ?? this.submitting,
      );
}

final class _EvalCubit extends Cubit<_State> {
  _EvalCubit(this._guid, this._lang) : super(const _State()) {
    _load();
  }

  final String _guid;
  final String _lang;

  Future<void> _load() async {
    try {
      final res = await sl<ApiClient>().get<Map<String, dynamic>>(
        '/api/app/service-evaluation/$_guid',
        query: {'lang': _lang},
      );
      final d = res.data;
      if (isClosed) return;
      if (d == null || d['found'] != true) {
        emit(state.copyWith(phase: _Phase.missing));
        return;
      }
      final qs = (d['questions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_Question.fromJson)
          .whereType<_Question>()
          .toList()
        ..sort((a, b) => a.qid.compareTo(b.qid));

      final load = _Load(
        found: true,
        pending: d['pending'] == true,
        orderNo: d['orderNo'] as String?,
        vehicleName: d['vehicleName'] as String?,
        plateNo: d['plateNo'] as String?,
        questions: qs,
      );
      emit(state.copyWith(
        load: load,
        // Already rated (or nothing to rate) → straight to the thank-you.
        phase: load.pending && qs.isNotEmpty ? _Phase.form : _Phase.done,
      ));
    } on DioException {
      if (!isClosed) emit(state.copyWith(phase: _Phase.failed));
    }
  }

  void rate(String g, int v) => emit(state.copyWith(
        ratings: {...state.ratings, g: v},
        missingGuids: {...state.missingGuids}..remove(g),
      ));

  void choose(String g, int option) => emit(state.copyWith(
        choices: {...state.choices, g: option},
        missingGuids: {...state.missingGuids}..remove(g),
      ));

  void setText(String g, String v) =>
      emit(state.copyWith(texts: {...state.texts, g: v}));

  void toggle(String g, int option, bool on) {
    final next = {...state.multi};
    final set = {...(next[g] ?? <int>{})};
    on ? set.add(option) : set.remove(option);
    next[g] = set;
    emit(state.copyWith(
      multi: next,
      missingGuids: {...state.missingGuids}..remove(g),
    ));
  }

  void setNote(String v) => emit(state.copyWith(note: v));

  bool _answered(_Question q) => switch (q.type) {
        1 => state.ratings.containsKey(q.guid),
        2 => state.choices.containsKey(q.guid),
        3 => (state.multi[q.guid] ?? const <int>{}).isNotEmpty,
        _ => true,
      };

  Future<bool> submit() async {
    if (state.submitting) return false;

    // Every mandatory question needs an answer — same rule as the website.
    final missing = state.load.questions
        .where((q) => q.mandatory && !_answered(q))
        .map((q) => q.guid)
        .toSet();
    if (missing.isNotEmpty) {
      emit(state.copyWith(missingGuids: missing));
      return false;
    }

    emit(state.copyWith(submitting: true));
    final answers = <Map<String, dynamic>>[];
    for (final q in state.load.questions) {
      switch (q.type) {
        case 1:
          final v = state.ratings[q.guid];
          if (v != null) {
            answers.add({
              'questionGuid': q.guid,
              'qTypeId': 1,
              'evaluation': '$v',
            });
          }
        case 2:
          final opt = state.choices[q.guid];
          if (opt != null) {
            final o = q.options().firstWhere((x) => x.index == opt,
                orElse: () => (index: opt, ar: '', en: ''));
            answers.add({
              'questionGuid': q.guid,
              'qTypeId': 2,
              'answerEn': o.en.isNotEmpty ? o.en : o.ar,
              // The free text only travels with the option that revealed it.
              'textYesNo': (q.textFlag && opt == 1)
                  ? (state.texts[q.guid] ?? '')
                  : '',
            });
          }
        case 3:
          final set = state.multi[q.guid] ?? const <int>{};
          if (set.isNotEmpty) {
            answers.add({
              'questionGuid': q.guid,
              'qTypeId': 3,
              'a1': set.contains(1) ? '1' : '0',
              'a2': set.contains(2) ? '1' : '0',
              'a3': set.contains(3) ? '1' : '0',
            });
          }
      }
    }
    if (state.note.trim().isNotEmpty) {
      answers.add({'qTypeId': 5, 'note': state.note.trim()});
    }

    try {
      final res = await sl<ApiClient>().post<Map<String, dynamic>>(
        '/api/app/service-evaluation/submit',
        body: {
          'guid': _guid,
          'orderNo': state.load.orderNo,
          'answers': answers,
        },
      );
      final ok = res.data?['ok'] == true;
      if (isClosed) return ok;
      emit(state.copyWith(
          submitting: false, phase: ok ? _Phase.done : state.phase));
      return ok;
    } on DioException {
      if (!isClosed) emit(state.copyWith(submitting: false));
      return false;
    }
  }
}

/* ------------------------------ view ------------------------------ */

final class _EvaluationSheet extends StatelessWidget {
  const _EvaluationSheet({required this.guid, this.title});

  final String guid;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return BlocProvider(
      create: (_) => _EvalCubit(guid, lang),
      child: _Body(title: title, lang: lang),
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body({required this.lang, this.title});

  final String lang;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<_EvalCubit>();
    final state = cubit.state;

    Widget body;
    switch (state.phase) {
      case _Phase.loading:
        body = const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
        );
      case _Phase.missing:
      case _Phase.failed:
        body = _Message(
          icon: Icons.link_off_rounded,
          title: t.evalUnavailable,
          message: t.evalUnavailableBody,
        );
      case _Phase.done:
        body = _Message(
          icon: Icons.verified_rounded,
          title: t.evalThanksTitle,
          message: t.evalThanksBody,
          tint: const Color(0xFF1E9E5A),
        );
      case _Phase.form:
        body = _Form(lang: lang);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rs(18), context.rs(6), context.rs(18), context.rs(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.star_rounded, color: scheme.primary, size: 22),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: Text(
                t.evalTitle,
                style: TextStyle(
                    fontSize: context.rf(16.5), fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ]),
          if (state.load.found &&
              (state.load.vehicleName ?? '').isNotEmpty) ...[
            Text(
              [
                state.load.vehicleName,
                state.load.plateNo,
                state.load.orderNo,
              ].where((s) => (s ?? '').trim().isNotEmpty).join(' • '),
              style: TextStyle(
                fontSize: context.rf(11),
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: context.rs(4)),
          ],
          Flexible(child: body),
        ],
      ),
    );
  }
}

final class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = tint ?? scheme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rs(34)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.rs(66),
            height: context.rs(66),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: c),
          ),
          SizedBox(height: context.rs(14)),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.rf(15), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(6)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.rf(12),
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

final class _Form extends StatelessWidget {
  const _Form({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<_EvalCubit>();
    final state = context.watch<_EvalCubit>().state;

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.only(top: context.rs(10)),
      children: [
        for (final q in state.load.questions)
          _QuestionCard(question: q, lang: lang),
        SizedBox(height: context.rs(6)),
        Text(t.evalNote,
            style: TextStyle(
                fontSize: context.rf(12.5), fontWeight: FontWeight.w800)),
        SizedBox(height: context.rs(6)),
        TextField(
          maxLines: 3,
          onChanged: cubit.setNote,
          decoration: InputDecoration(
            hintText: t.evalNoteHint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          style: TextStyle(fontSize: context.rf(12.5)),
        ),
        SizedBox(height: context.rs(16)),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
            textStyle: TextStyle(
                fontSize: context.rf(13.5), fontWeight: FontWeight.w800),
          ),
          onPressed: state.submitting
              ? null
              : () async {
                  final ok = await cubit.submit();
                  if (!context.mounted) return;
                  if (!ok && cubit.state.missingGuids.isNotEmpty) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          SnackBar(content: Text(t.evalMissingAnswers)));
                  }
                },
          child: state.submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white))
              : Text(t.evalSubmit),
        ),
      ],
    );
  }
}

final class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.lang});

  final _Question question;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<_EvalCubit>();
    final state = context.watch<_EvalCubit>().state;
    final q = question;
    final missing = state.missingGuids.contains(q.guid);

    return Container(
      margin: EdgeInsets.only(bottom: context.rs(12)),
      padding: EdgeInsets.all(context.rs(13)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: missing
              ? scheme.error
              : scheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(
                q.text(lang),
                style: TextStyle(
                    fontSize: context.rf(12.5),
                    fontWeight: FontWeight.w700,
                    height: 1.4),
              ),
            ),
            if (q.mandatory)
              Text(' *',
                  style: TextStyle(
                      color: scheme.error,
                      fontSize: context.rf(14),
                      fontWeight: FontWeight.w900)),
          ]),
          SizedBox(height: context.rs(10)),
          if (q.type == 1)
            _RatingScale(
              value: state.ratings[q.guid],
              onSelect: (v) => cubit.rate(q.guid, v),
            )
          else if (q.type == 2)
            _SingleChoice(question: q, lang: lang)
          else
            _MultiChoice(question: q, lang: lang),
        ],
      ),
    );
  }
}

/// 0..10 — the ERP stores the raw score, so the scale is numeric rather than
/// stars (the answer labels only describe the bands 0-6 / 7-9 / 10).
final class _RatingScale extends StatelessWidget {
  const _RatingScale({required this.value, required this.onSelect});

  final int? value;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i <= 10; i++)
          InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: context.rs(30),
              height: context.rs(34),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: value == i
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.05),
                border: Border.all(
                  color: value == i
                      ? scheme.primary
                      : scheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: context.rf(12),
                  fontWeight: FontWeight.w800,
                  color: value == i ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _SingleChoice extends StatelessWidget {
  const _SingleChoice({required this.question, required this.lang});

  final _Question question;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<_EvalCubit>();
    final state = context.watch<_EvalCubit>().state;
    final q = question;
    final selected = state.choices[q.guid];
    // The ERP flags questions whose FIRST option ("yes") should open a note.
    final reveal = q.textFlag && selected == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in q.options())
          RadioListTile<int>(
            value: o.index,
            groupValue: selected,
            onChanged: (v) => v == null ? null : cubit.choose(q.guid, v),
            title: Text(
              (lang == 'ar' ? o.ar : o.en).isNotEmpty
                  ? (lang == 'ar' ? o.ar : o.en)
                  : (o.en.isNotEmpty ? o.en : o.ar),
              style: TextStyle(fontSize: context.rf(12)),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        if (reveal) ...[
          SizedBox(height: context.rs(4)),
          TextField(
            maxLines: 2,
            onChanged: (v) => cubit.setText(q.guid, v),
            decoration: InputDecoration(
              hintText: t.evalTellUs,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
              isDense: true,
            ),
            style: TextStyle(fontSize: context.rf(12)),
          ),
        ],
      ],
    );
  }
}

final class _MultiChoice extends StatelessWidget {
  const _MultiChoice({required this.question, required this.lang});

  final _Question question;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<_EvalCubit>();
    final state = context.watch<_EvalCubit>().state;
    final q = question;
    final checked = state.multi[q.guid] ?? const <int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in q.options())
          CheckboxListTile(
            value: checked.contains(o.index),
            onChanged: (v) => cubit.toggle(q.guid, o.index, v ?? false),
            title: Text(
              (lang == 'ar' ? o.ar : o.en).isNotEmpty
                  ? (lang == 'ar' ? o.ar : o.en)
                  : (o.en.isNotEmpty ? o.en : o.ar),
              style: TextStyle(fontSize: context.rf(12)),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
