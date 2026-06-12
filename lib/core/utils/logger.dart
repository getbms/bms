import 'package:logger/logger.dart';

/// App-wide structured logger.
/// In production, swap PrettyPrinter for a JSON printer that emits to a log file.
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: Level.debug,
);
