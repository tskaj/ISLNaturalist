import 'package:flutter/foundation.dart';

class PlatformService {
  static bool isWeb() {
    return kIsWeb;
  }

  static bool isMobile() {
    return !kIsWeb;
  }
}