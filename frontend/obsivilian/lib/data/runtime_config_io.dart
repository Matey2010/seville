import 'dart:io';

/// The API token from the process environment or `--dart-define`. There is no
/// default: a missing token is a setup error, not a guessable credential.
String sevilleToken() {
  final token =
      Platform.environment['SEVILLE_TOKEN'] ??
      const String.fromEnvironment('SEVILLE_TOKEN');
  if (token.isEmpty) {
    throw StateError('SEVILLE_TOKEN is not set; set it in .env.');
  }
  return token;
}
