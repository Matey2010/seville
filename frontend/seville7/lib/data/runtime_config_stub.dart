String sevilleToken() => const String.fromEnvironment(
  'SEVILLE_TOKEN',
  defaultValue: 'local-seville-token',
);

String sevillePlayerSlug() =>
    const String.fromEnvironment('SEVILLE_PLAYER_SLUG');
