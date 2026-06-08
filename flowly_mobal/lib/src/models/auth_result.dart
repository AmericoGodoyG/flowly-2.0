class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.name,
    this.userType,
    this.requiresVerification = false,
    this.requiresFaceVerification = false,
    this.requiresFaceEnrollmentOffer = false,
    this.faceSessionToken,
    this.userId,
    this.userPhoto,
  });

  final bool success;
  final String message;
  final String? token;
  final String? name;
  final String? userType;
  final bool requiresVerification;
  final bool requiresFaceVerification;
  final bool requiresFaceEnrollmentOffer;
  final String? faceSessionToken;
  final String? userId;
  final String? userPhoto;
}
