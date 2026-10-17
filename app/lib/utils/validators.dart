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

  static bool isValidPetName(String name) {
    //name validation (45 characters max)
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= 45;
  }

  static bool isValidMicrochip(String? microchip) {
    //microchip validation (15 characters max)
    if (microchip == null || microchip.trim().isEmpty) {
      return true;
    }
    return microchip.trim().length <= 15;
  }

  //species validation (must be a valid species ID)
  static bool isValidSpecies(int? speciesId) {
    return speciesId != null;
  }

  //breed validation (must be a valid breed ID)
  static bool isValidBreed(int? breedId) {
    return breedId != null;
  }

  //color validation (must be a valid color ID)
  static bool isValidColor(int? colorId) {
    return colorId != null;
  }

  //gender validation (must be 'M' or 'F')
  static bool isValidGender(String? gender) {
    return gender == 'M' || gender == 'F';
  }

  static bool isValidLength(String? value, int min, int max) {
    final length = (value ?? '').trim().length;
    return length >= min && length <= max;
  }

  static bool isValidCellPhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^[1-9]{2}9[0-9]{8}$').hasMatch(digits);
  }

  static double? parseNumber(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  static bool isValidCoordinate(String? value, double limit) {
    final number = parseNumber(value);
    return number != null && number >= -limit && number <= limit;
  }

  static bool isValidPositiveInt(String? value) {
    final number = int.tryParse((value ?? '').trim());
    return number != null && number > 0;
  }
}
