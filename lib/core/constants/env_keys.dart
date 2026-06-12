/// All environment variable keys consumed by the app.
/// Values are read once at startup via AppConfig -- never scattered across the codebase.
abstract final class EnvKeys {
  static const String appEnv = 'APP_ENV';
  static const String dbEncryptionKey = 'DB_ENCRYPTION_KEY';
}
