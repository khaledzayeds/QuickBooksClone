// safe_navigation.dart

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension SafeNavigation on BuildContext {
  void popOrGo(String fallbackLocation) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackLocation);
    }
  }
}
