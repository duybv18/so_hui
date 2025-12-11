class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName phải là số';
    }
    if (double.parse(value) <= 0) {
      return '$fieldName phải lớn hơn 0';
    }
    return null;
  }

  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName phải là số nguyên';
    }
    if (int.parse(value) <= 0) {
      return '$fieldName phải lớn hơn 0';
    }
    return null;
  }

  static String? validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Phải là số';
    }
    if (number < 0 || number > 100) {
      return 'Phải từ 0 đến 100';
    }
    return null;
  }
}
