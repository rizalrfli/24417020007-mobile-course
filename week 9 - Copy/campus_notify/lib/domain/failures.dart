sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
