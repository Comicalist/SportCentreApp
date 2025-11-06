/// Form validation ensuring secure user accounts and data integrity
class ValidationUtils {
  /// Enforces password security standards to protect user accounts
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp('[A-Z]'))) {
      return 'Password must contain at least 1 uppercase letter';
    }

    if (!password.contains(RegExp('[a-z]'))) {
      return 'Password must contain at least 1 lowercase letter';
    }

    if (!password.contains(RegExp('[0-9]'))) {
      return 'Password must contain at least 1 number';
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least 1 special character';
    }

    return null;
  }

  /// Validates user display names for professional presentation
  static String? validateDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Full name is required';
    }

    final trimmedName = name.trim();

    if (trimmedName.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (trimmedName.length > 40) {
      return 'Name must not exceed 40 characters';
    }

    if (!RegExp(r"^[a-zA-Z\s\-\']+$").hasMatch(trimmedName)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Ensures valid email format for communication and account verification
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Calculates password strength score for user feedback during registration
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    var score = 0;

    if (password.length >= 8) score += 10;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    if (password.contains(RegExp('[a-z]'))) score += 20;
    if (password.contains(RegExp('[A-Z]'))) score += 20;
    if (password.contains(RegExp('[0-9]'))) score += 20;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 20;

    return score.clamp(0, 100);
  }

  /// Provides user-friendly strength labels for password quality guidance
  static String getPasswordStrengthLabel(int strength) {
    if (strength < 40) return 'Weak';
    if (strength < 70) return 'Medium';
    if (strength < 90) return 'Strong';
    return 'Very Strong';
  }

  /// Generates checklist for password creation guidance
  static List<PasswordRequirement> getPasswordRequirements(String password) {
    return [
      PasswordRequirement('At least 8 characters', password.length >= 8),
      PasswordRequirement(
        'At least 1 uppercase letter (A-Z)',
        password.contains(RegExp('[A-Z]')),
      ),
      PasswordRequirement(
        'At least 1 lowercase letter (a-z)',
        password.contains(RegExp('[a-z]')),
      ),
      PasswordRequirement(
        'At least 1 number (0-9)',
        password.contains(RegExp('[0-9]')),
      ),
      PasswordRequirement(
        r'At least 1 special character (!@#$%^&*)',
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
  }
}

/// Individual password requirement for interactive feedback display
class PasswordRequirement {
  PasswordRequirement(this.text, this.isMet);
  final String text;
  final bool isMet;
}
