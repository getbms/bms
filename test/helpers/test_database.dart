import 'package:bms/data/database/app_database.dart';
import 'package:drift/native.dart';

/// Opens a fresh in-memory Drift database for each test.
/// Schema is created via onCreate so all tables exist immediately.
AppDatabase openTestDatabase() => AppDatabase.forTesting(NativeDatabase.memory());
