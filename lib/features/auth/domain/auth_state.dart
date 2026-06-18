import 'package:bms/data/models/user_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.authenticated({required UserModel user}) = Authenticated;
}
