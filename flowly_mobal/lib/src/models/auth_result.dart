class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.name,
    this.userType,
    this.requiresVerification = false,
  });

  final bool success;
  final String message;
  final String? token;
  final String? name;
  final String? userType;
  final bool requiresVerification;
}
