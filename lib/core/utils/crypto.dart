import 'dart:convert';

import 'package:crypto/crypto.dart';

/// MD5-hex — the website's auth cycle hashes the password client-side and
/// Site_User_SignInWithPassword compares against Web_Users.Password.
String md5Hex(String input) => md5.convert(utf8.encode(input)).toString();
