/// Base failure class. Every use case returns Either<Failure, T>.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

final class ParseFailure extends Failure {
  const ParseFailure(super.message);
}
