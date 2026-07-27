import '../constants/api_paths.dart';

/// CDN image URLs coming from the ERP contain raw Arabic characters and
/// sometimes control characters (\r\n) in the file names. Browsers encode
/// these transparently (so the website works); Flutter's NetworkImage does
/// not — it either throws on parse or requests the raw bytes and 404s.
/// Normalize every media URL through here before handing it to Image.network.
String? cleanMediaUrl(String? url) {
  if (url == null) return null;
  // Strip control characters, normalize legacy backslashes, trim whitespace.
  final s = url
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .replaceAll(r'\', '/')
      .trim();
  if (s.isEmpty) return null;
  final uri = Uri.tryParse(s);
  // Uri.toString() percent-encodes non-ASCII path characters (UTF-8), which
  // is exactly what the CDN expects.
  if (uri != null) return uri.toString();
  return Uri.encodeFull(s);
}

/// Route a CDN image through the backend's /api/app/img optimizer — the
/// mobile equivalent of the website's Next.js image pipeline. It fixes the
/// ERP's malformed PNG-as-webp files (Flutter's codec rejects them),
/// resizes multi-MB artwork server-side, and re-encodes clean lossy WebP.
/// Non-http URLs (assets, data) pass through untouched.
String? optimizedImageUrl(String? url, {int? width}) {
  final cleaned = cleanMediaUrl(url);
  if (cleaned == null) return null;
  if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
    return cleaned;
  }
  final w = width == null || width <= 0 ? '' : '&w=$width';
  return '${ApiPaths.baseUrl}/api/app/img?u=${Uri.encodeComponent(cleaned)}$w';
}
