import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.signIn(event.email, event.password);
      result.fold(
        (failure) => emit(AuthError('Authentication failed')),
        (_) => emit(AuthSuccess()),
      );
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.signUp(event.email, event.password);
      result.fold(
        (failure) => emit(AuthError('Registration failed')),
        (_) => emit(AuthSuccess()),
      );
    });
  }
} 