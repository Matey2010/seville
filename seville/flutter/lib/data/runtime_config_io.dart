import 'dart:io';

String sevilleToken() =>
    Platform.environment['SEVILLE_TOKEN'] ?? 'local-seville-token';
