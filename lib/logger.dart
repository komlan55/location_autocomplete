import 'dart:developer' as developer;

class Logger {
  final String name;

  Logger([this.name = 'App']);

  void d(String message) {
    _log(message, level: 500); // debug
  }

  void i(String message) {
    _log(message, level: 800); // info
  }

  void w(String message) {
    _log(message, level: 900); // warning
  }

  void e(String message, [Object? error, StackTrace? stackTrace]) {
    _log(message, level: 1000, error: error, stackTrace: stackTrace); // error
  }

  void _log(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
