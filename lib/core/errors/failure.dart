import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Result type passed up to the UI layer.
/// Repositories return these; UI reads them via AsyncValue.
@freezed
sealed class Failure with _$Failure {
  const factory Failure.auth(String message, {String? code}) = AuthFailure;
  const factory Failure.validation(String message, {String? field}) = ValidationFailure;
  const factory Failure.notFound(String message) = NotFoundFailure;
  const factory Failure.conflict(String message) = ConflictFailure;
  const factory Failure.database(String message) = DatabaseFailure;
  const factory Failure.businessRule(String message) = BusinessRuleFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}
