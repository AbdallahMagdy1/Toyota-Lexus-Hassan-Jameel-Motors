/// Masked-phone display for the OTP screens.
///
/// The API's mask historically kept too many digits and, rendered inside an
/// RTL sentence, the '+' and digit runs shuffled into nonsense like
/// "567*****966565+". This rebuilds any server mask into a canonical
/// "+966 5*****123" and wraps it in a Unicode LTR isolate (U+2066…U+2069)
/// so Arabic text around it can never reorder the pieces.
String formatMaskedPhone(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';

  // Keep only digits, in order (drops '+', '*', spaces).
  var digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00966')) {
    digits = digits.substring(5);
  } else if (digits.startsWith('966')) {
    digits = digits.substring(3);
  }
  if (digits.startsWith('0')) digits = digits.substring(1);

  // digits is now what remains of the local number, e.g. "565567" (the
  // server mask keeps a head + last 3). Show first digit + stars + last 3.
  final String masked;
  if (digits.length >= 4) {
    masked = '+966 ${digits[0]}*****${digits.substring(digits.length - 3)}';
  } else if (digits.isNotEmpty) {
    masked = '+966 ${digits[0]}*****';
  } else {
    masked = s; // nothing recognizable — show as-is (still LTR-isolated)
  }
  return '\u2066$masked\u2069';
}
