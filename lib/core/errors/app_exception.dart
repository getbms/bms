/// Typed application exceptions.
/// Every layer re-throws as one of these so callers always catch a known type.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class AuthException extends AppException {
  const AuthException(super.message, {this.code = AuthErrorCode.unknown});
  final AuthErrorCode code;
}

enum AuthErrorCode { invalidCredentials, accountLocked, sessionExpired, unauthorized, unknown }

final class ValidationException extends AppException {
  const ValidationException(super.message, {this.field});
  final String? field;
}

final class NotFoundException extends AppException {
  const NotFoundException(String entity, String id)
      : super('$entity with id $id not found');
}

final class ConflictException extends AppException {
  const ConflictException(super.message);
}

final class DatabaseException extends AppException {
  const DatabaseException(super.message, {this.cause});
  final Object? cause;
}

final class BusinessRuleException extends AppException {
  const BusinessRuleException(super.message);
}
