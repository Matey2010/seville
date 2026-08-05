import 'dart:io';

String sevilleToken() =>
    Platform.environment['SEVILLE_TOKEN'] ?? 'local-seville-token';

String sevillePlayerSlug() =>
    Platform.environment['SEVILLE_PLAYER_SLUG'] ??
    const String.fromEnvironment('SEVILLE_PLAYER_SLUG');
