import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hj_mobile/features/auth/presentation/widgets/auth_bits.dart';

void main() {
  Widget host(OtpStatus status, TextEditingController c) => MaterialApp(
        home: Scaffold(
          body: OtpField(
            controller: c,
            focusColor: Colors.red,
            status: status,
            successLabel: 'Verified',
            errorLabel: 'Incorrect',
            errorHint: 'try again',
          ),
        ),
      );

  testWidgets('error result morphs boxes into the ✕ pill', (tester) async {
    final c = TextEditingController(text: '1234');
    await tester.pumpWidget(host(OtpStatus.idle, c));
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    // Verification failed → status flips to error (same element position).
    await tester.pumpWidget(host(OtpStatus.error, c));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Incorrect'), findsOneWidget);

    // Back to idle (retry) → boxes return.
    await tester.pumpWidget(host(OtpStatus.idle, c));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    c.dispose();
  });

  testWidgets('success result shows the ✓ pill', (tester) async {
    final c = TextEditingController(text: '1234');
    await tester.pumpWidget(host(OtpStatus.idle, c));
    await tester.pumpWidget(host(OtpStatus.success, c));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    c.dispose();
  });
}
