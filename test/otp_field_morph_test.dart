import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hj_mobile/features/auth/presentation/widgets/auth_bits.dart';
import 'package:otp_animated_fields/otp_animated_fields.dart';

void main() {
  testWidgets('OtpField renders the animated package field', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtpField(
          controller: controller,
          focusColor: Colors.red,
          onVerify: (_) async => true,
        ),
      ),
    ));
    expect(find.byType(OtpAnimatedField), findsOneWidget);
    controller.dispose();
  });
}
