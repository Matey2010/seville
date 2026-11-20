/// The API token from `--dart-define`. There is no default: a missing token is
/// a setup error, not a guessable credential.
String sevilleToken() {
  const token = String.fromEnvironment('SEVILLE_TOKEN');
  if (token.isEmpty) {
    throw StateError('SEVILLE_TOKEN is not set; pass it with --dart-define.');
  }
  return token;
}
