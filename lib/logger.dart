import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

Logger getLogger(String className) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('$className:  ${record.message}');
    }
  });
  return Logger(className);
}
