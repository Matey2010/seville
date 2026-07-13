import 'package:flutter/foundation.dart';

abstract final class CommonUtilities {
  static void log(Object? message) {
    debugPrint(message?.toString());
  }
}
