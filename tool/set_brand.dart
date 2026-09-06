/// Switches the whole project between the Toyota and Lexus store apps.
///
///   dart run tool/set_brand.dart toyota   → "Toyota HJ", com.hassanjameel.toyota
///   dart run tool/set_brand.dart lexus    → "Lexus HJ",  com.hassanjameel.lexus
///
/// In one shot it rewrites the app display name (iOS Info.plist + Android
/// manifest), the iOS bundle identifier, and regenerates the launcher icons.
/// Afterwards build with the matching entry point, e.g.:
///   flutter build ipa -t lib/main_lexus.dart
library;

import 'dart:io';

const _brands = {
  'toyota': (name: 'Toyota HJ', bundleId: 'com.hassanjameel.toyota', icons: 'icons-toyota.yaml'),
  'lexus': (name: 'Lexus HJ', bundleId: 'com.hassanjameel.lexus', icons: 'icons-lexus.yaml'),
};

Future<void> main(List<String> args) async {
  final brand = _brands[args.isEmpty ? '' : args.first];
  if (brand == null) {
    stderr.writeln('Usage: dart run tool/set_brand.dart <toyota|lexus>');
    exitCode = 64;
    return;
  }

  _rewrite('ios/Runner/Info.plist', {
    RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'):
        '\${1}${brand.name}\${2}',
    RegExp(r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)'):
        '\${1}${brand.name}\${2}',
  });

  // Both brands' ids map onto the target id; the .RunnerTests suffix is
  // preserved because only the shared base id is replaced.
  _rewrite('ios/Runner.xcodeproj/project.pbxproj', {
    for (final b in _brands.values) RegExp(RegExp.escape(b.bundleId)): brand.bundleId,
  });

  _rewrite('android/app/src/main/AndroidManifest.xml', {
    RegExp(r'android:label="[^"]*"'): 'android:label="${brand.name}"',
  });

  // Android applicationId — same id as iOS, so ONE android/ folder serves
  // both store apps (Play package flips per brand before building).
  _rewrite('android/app/build.gradle.kts', {
    RegExp(r'applicationId = "[^"]*"'):
        'applicationId = "${brand.bundleId}"',
  });

  // iOS Firebase config — download each brand's GoogleService-Info.plist
  // from the Firebase console into ios/firebase/ (named per brand); the
  // active one is copied over ios/Runner/GoogleService-Info.plist. Push
  // notifications on iOS need the plist registered for the brand's bundle id.
  final plist = File('ios/firebase/GoogleService-Info-${args.first}.plist');
  if (plist.existsSync()) {
    plist.copySync('ios/Runner/GoogleService-Info.plist');
    stdout.writeln('Copied ${plist.path} -> ios/Runner/GoogleService-Info.plist');
  } else {
    stdout.writeln('NOTE: ${plist.path} not found - iOS Firebase config unchanged.');
  }

  stdout.writeln('Regenerating launcher icons (${brand.icons})…');
  final icons = await Process.run(
    'dart', ['run', 'flutter_launcher_icons', '-f', brand.icons],
    runInShell: true,
  );
  stdout.write(icons.stdout);
  stderr.write(icons.stderr);
  if (icons.exitCode != 0) {
    stderr.writeln('flutter_launcher_icons failed — run it manually.');
    exitCode = icons.exitCode;
    return;
  }

  stdout.writeln('✓ Project is now the ${brand.name} app (${brand.bundleId}).');
}

void _rewrite(String path, Map<RegExp, String> replacements) {
  final file = File(path);
  var text = file.readAsStringSync();
  replacements.forEach((pattern, replacement) {
    text = text.replaceAllMapped(
      pattern,
      (m) => replacement.replaceAllMapped(
        RegExp(r'\$\{(\d)\}'),
        (r) => m.group(int.parse(r.group(1)!))!,
      ),
    );
  });
  file.writeAsStringSync(text);
  stdout.writeln('Updated $path');
}
