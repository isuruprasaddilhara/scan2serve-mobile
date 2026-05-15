/// Shared sign-up / change-password rules.
class PasswordRequirements {
  const PasswordRequirements({
    required this.hasMinLength,
    required this.hasLettersAndNumbers,
    required this.hasSpecialChar,
  });

  final bool hasMinLength;
  final bool hasLettersAndNumbers;
  final bool hasSpecialChar;

  bool get allMet =>
      hasMinLength && hasLettersAndNumbers && hasSpecialChar;

  factory PasswordRequirements.evaluate(String password) {
    return PasswordRequirements(
      hasMinLength: password.length >= 8,
      hasLettersAndNumbers: RegExp('[A-Za-z]').hasMatch(password) &&
          RegExp('[0-9]').hasMatch(password),
      hasSpecialChar: RegExp(r'[^A-Za-z0-9\s]').hasMatch(password),
    );
  }
}
