class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacter = RegExp(r'[@$!%*?&]').hasMatch(password);

    return password.length >= 8 &&
        hasLowercase &&
        hasUppercase &&
        hasNumber &&
        hasSpecialCharacter;
  }
}
