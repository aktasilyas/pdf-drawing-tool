/// Input validators for forms.
library;

abstract class Validators {
  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    return null;
  }

  /// Validate password confirmation
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Şifre tekrarı gerekli';
      }
      if (value != password) {
        return 'Şifreler eşleşmiyor';
      }
      return null;
    };
  }

  /// Validate display name
  static String? displayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'İsim gerekli';
    }
    if (value.length < 2) {
      return 'İsim en az 2 karakter olmalı';
    }
    if (value.length > 50) {
      return 'İsim en fazla 50 karakter olabilir';
    }
    return null;
  }

  /// Validate document title
  static String? documentTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Başlık gerekli';
    }
    if (value.length > 100) {
      return 'Başlık en fazla 100 karakter olabilir';
    }
    return null;
  }

  /// Validate folder name
  static String? folderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Klasör adı gerekli';
    }
    if (value.length > 50) {
      return 'Klasör adı en fazla 50 karakter olabilir';
    }
    // Check for invalid characters
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(value)) {
      return 'Klasör adı geçersiz karakterler içeriyor';
    }
    return null;
  }

  /// Required field validator
  static String? required(String? value, [String fieldName = 'Bu alan']) {
    if (value == null || value.isEmpty) {
      return '$fieldName gerekli';
    }
    return null;
  }

  /// Min length validator
  static String? Function(String?) minLength(int min, [String fieldName = 'Bu alan']) {
    return (String? value) {
      if (value != null && value.length < min) {
        return '$fieldName en az $min karakter olmalı';
      }
      return null;
    };
  }

  /// Max length validator
  static String? Function(String?) maxLength(int max, [String fieldName = 'Bu alan']) {
    return (String? value) {
      if (value != null && value.length > max) {
        return '$fieldName en fazla $max karakter olabilir';
      }
      return null;
    };
  }

  /// Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
