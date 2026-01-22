/// Riverpod providers for auth state and actions.
import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:example_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:example_app/features/auth/domain/entities/user.dart';
import 'package:example_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:example_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:example_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:example_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:example_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remote);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

class AuthViewState {
  final bool isLoading;
  final String? errorMessage;

  const AuthViewState({
    this.isLoading = false,
    this.errorMessage,
  });

  AuthViewState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthViewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthViewState> {
  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthController({
    required AuthRepository repository,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _repository = repository,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AuthViewState());

  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _loginUseCase(email: email, password: password);
    state = state.copyWith(isLoading: false, errorMessage: _errorText(result));
    return result;
  }

  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _registerUseCase(
      email: email,
      password: password,
      displayName: displayName,
    );
    state = state.copyWith(isLoading: false, errorMessage: _errorText(result));
    return result;
  }

  Future<Either<Failure, User>> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.loginWithGoogle();
    state = state.copyWith(isLoading: false, errorMessage: _errorText(result));
    return result;
  }

  Future<Either<Failure, void>> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _logoutUseCase();
    state = state.copyWith(isLoading: false, errorMessage: _errorText(result));
    return result;
  }

  Future<Either<Failure, User?>> refreshCurrentUser() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _getCurrentUserUseCase();
    state = state.copyWith(isLoading: false, errorMessage: _errorText(result));
    return result;
  }

  String? _errorText<T>(Either<Failure, T> result) {
    return result.fold((failure) => failure.message, (_) => null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthViewState>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
});
