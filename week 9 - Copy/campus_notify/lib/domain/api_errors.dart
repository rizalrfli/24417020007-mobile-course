/// Framework-independent failure value for repository results.
class ApiFailure {
  const ApiFailure(this.message, {this.isRetryable = false});

  final String message;
  final bool isRetryable;
}
