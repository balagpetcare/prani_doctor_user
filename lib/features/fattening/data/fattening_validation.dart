class FatteningValidation {
  FatteningValidation._();

  static String? validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Name is required';
    if (trimmed.length > 120) return 'Name is too long';
    return null;
  }

  static String? validateGoal(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 500) return 'Goal is too long';
    return null;
  }
}
