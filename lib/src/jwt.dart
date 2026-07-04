import 'dart:convert';

/// Decode a JWT payload without verifying its signature.
///
/// Returns an empty map for tokens that are not three-part JWTs (e.g. opaque
/// API keys). Used to read the Hanzo IAM token's `exp` claim locally.
Map<String, dynamic> getTokenPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    return const {};
  }
  try {
    final decoded =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final data = jsonDecode(decoded);
    return data is Map<String, dynamic> ? data : const {};
  } catch (_) {
    return const {};
  }
}

/// Whether a Bearer token is currently usable.
///
/// A three-part JWT is valid until its `exp` claim (minus
/// [expirationThreshold] seconds) passes. An opaque API key — anything that is
/// not a decodable JWT — is valid whenever it is non-empty, since it carries no
/// local expiry.
bool isTokenValid(String token, [int expirationThreshold = 0]) {
  if (token.isEmpty) {
    return false;
  }
  final payload = getTokenPayload(token);
  final exp = payload['exp'];
  if (exp is! num) {
    return true; // opaque API key or JWT without exp
  }
  final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
  return exp - expirationThreshold > nowSeconds;
}
