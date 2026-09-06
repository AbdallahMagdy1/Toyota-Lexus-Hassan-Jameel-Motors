import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hj_mobile/core/theme/app_brand.dart';
import 'package:hj_mobile/core/theme/theme_factory.dart';

/// The brand typeface has ONE non-obvious failure mode: the material2021
/// geometry styles are `inherit: false`, and TextStyle.merge returns a
/// non-inheriting `other` wholesale — so passing an explicit textTheme
/// silently drops ThemeData.fontFamily. These assert the family survives
/// all the way to what a widget actually renders.
void main() {
  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      final theme = ThemeFactory.build(kFallbackBrands['toyota']!, brightness);

      test('every textTheme style carries the brand family', () {
        final styles = <String, TextStyle?>{
          'displayLarge': theme.textTheme.displayLarge,
          'headlineMedium': theme.textTheme.headlineMedium,
          'titleMedium': theme.textTheme.titleMedium,
          'bodyLarge': theme.textTheme.bodyLarge,
          'bodyMedium': theme.textTheme.bodyMedium,
          'labelSmall': theme.textTheme.labelSmall,
        };
        for (final entry in styles.entries) {
          expect(
            entry.value?.fontFamily,
            kAppFontFamily,
            reason: '${entry.key} lost the brand family',
          );
        }
      });

      testWidgets('rendered Text resolves to the brand family', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: Text('مرحبا Hassan Jameel')),
          ),
        );
        final rendered = tester.widget<RichText>(find.byType(RichText));
        expect(rendered.text.style?.fontFamily, kAppFontFamily);
      });
    });
  }

  testWidgets('the riyal glyph still renders in icomoon, not the brand font', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeFactory.build(kFallbackBrands['toyota']!, Brightness.light),
        home: const Scaffold(
          body: Text('', style: TextStyle(fontFamily: 'icomoon')),
        ),
      ),
    );
    final rendered = tester.widget<RichText>(find.byType(RichText));
    expect(rendered.text.style?.fontFamily, 'icomoon');
  });
}
