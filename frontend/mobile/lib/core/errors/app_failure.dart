sealed class AppFailure {
  const AppFailure();
}

class AuthFailure extends AppFailure {
  final String code;
  const AuthFailure(this.code);

  @override
  bool operator ==(Object other) => other is AuthFailure && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'AuthFailure($code)';
}

class ServerFailure extends AppFailure {
  final String? code;
  const ServerFailure([this.code]);

  @override
  bool operator ==(Object other) =>
      other is ServerFailure && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

class PermissionFailure extends AppFailure {
  const PermissionFailure();
}

class CacheFailure extends AppFailure {
  const CacheFailure();
}

class ValidationFailure extends AppFailure {
  final String message;
  const ValidationFailure(this.message);

  @override
  bool operator ==(Object other) =>
      other is ValidationFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
