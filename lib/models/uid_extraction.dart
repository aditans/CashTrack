/// Utility class for extracting and manipulating Firebase Auth UIDs
/// Specifically designed to extract the last 6 digits/characters from Google-generated UIDs
class UidExtraction {

  /// Extracts the last 6 characters from a Firebase UID
  /// Returns the last 6 characters as a String
  /// If UID is shorter than 6 characters, returns the entire UID
  /// If UID is null or empty, returns empty string
  static String extractLast6Digits(String? uid) {
    // Handle null or empty UIDs
    if (uid == null || uid.isEmpty) {
      return '';
    }

    // If UID is shorter than 6 characters, return the entire UID
    if (uid.length < 6) {
      return uid;
    }

    // Extract last 6 characters using substring
    return uid.substring(uid.length - 6);
  }

  /// Extracts the last N characters from a Firebase UID
  /// More flexible version that allows custom length
  static String extractLastNChars(String? uid, int n) {
    // Validate inputs
    if (uid == null || uid.isEmpty || n <= 0) {
      return '';
    }

    // If UID is shorter than requested length, return the entire UID
    if (uid.length < n) {
      return uid;
    }

    // Extract last N characters
    return uid.substring(uid.length - n);
  }

  /// Extracts the last 6 digits and converts to uppercase
  /// Useful for generating consistent user IDs or display purposes
  static String extractLast6DigitsUppercase(String? uid) {
    return extractLast6Digits(uid).toUpperCase();
  }

  /// Extracts the last 6 digits and pads with zeros if UID is shorter
  /// Ensures the returned string is always exactly 6 characters
  static String extractLast6DigitsPadded(String? uid) {
    if (uid == null || uid.isEmpty) {
      return '000000';
    }

    if (uid.length >= 6) {
      return uid.substring(uid.length - 6);
    } else {
      // Pad with leading zeros to make it 6 characters
      return uid.padLeft(6, '0');
    }
  }

  /// Extracts the last 6 characters and removes any non-alphanumeric characters
  /// Returns only letters and numbers
  static String extractLast6AlphaNumeric(String? uid) {
    if (uid == null || uid.isEmpty) {
      return '';
    }

    // Remove non-alphanumeric characters
    String cleanUid = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Extract last 6 characters from cleaned UID
    return extractLast6Digits(cleanUid);
  }

  /// Validates if the extracted portion meets certain criteria
  /// Returns true if the last 6 characters are valid (alphanumeric)
  static bool isValidLast6Chars(String? uid) {
    String extracted = extractLast6Digits(uid);

    if (extracted.isEmpty) return false;

    // Check if all characters are alphanumeric
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(extracted);
  }

  /// Creates a user-friendly ID from the last 6 characters
  /// Format: Converts to uppercase and adds dashes for readability
  /// Example: abc123 becomes ABC-123
  static String createUserFriendlyId(String? uid) {
    String extracted = extractLast6Digits(uid);

    if (extracted.isEmpty || extracted.length < 6) {
      return extracted.toUpperCase();
    }

    // Split into two parts and add dash
    String firstPart = extracted.substring(0, 3).toUpperCase();
    String secondPart = extracted.substring(3, 6).toUpperCase();

    return '$firstPart-$secondPart';
  }

  /// Extracts numeric digits only from the last 6 characters
  /// Returns only the numeric characters, ignoring letters
  static String extractLast6NumericOnly(String? uid) {
    if (uid == null || uid.isEmpty) {
      return '';
    }

    // Extract last 6 characters first
    String last6 = extractLast6Digits(uid);

    // Keep only numeric characters
    return last6.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Extension method to safely extract last N characters with error handling
  /// Uses clamp to prevent RangeError
  static String safeExtractLastNChars(String? uid, int n) {
    if (uid == null || uid.isEmpty) {
      return '';
    }

    // Use clamp to prevent range errors
    int startIndex = (uid.length - n).clamp(0, uid.length);
    return uid.substring(startIndex);
  }

  /// Generates a hash-like identifier from the last 6 characters
  /// Useful for creating consistent short identifiers
  static String generateShortId(String? uid) {
    if (uid == null || uid.isEmpty) {
      return 'UNKNOWN';
    }

    String extracted = extractLast6Digits(uid);

    if (extracted.isEmpty) {
      return 'EMPTY';
    }

    // Convert to uppercase and ensure it's exactly 6 characters
    return extracted.toUpperCase().padLeft(6, '0');
  }

  /// Debug method to show UID information
  /// Useful for development and testing
  static Map<String, dynamic> getUidInfo(String? uid) {
    return {
      'originalUid': uid ?? '',
      'uidLength': uid?.length ?? 0,
      'last6Chars': extractLast6Digits(uid),
      'last6Uppercase': extractLast6DigitsUppercase(uid),
      'last6Padded': extractLast6DigitsPadded(uid),
      'last6AlphaNumeric': extractLast6AlphaNumeric(uid),
      'last6NumericOnly': extractLast6NumericOnly(uid),
      'userFriendlyId': createUserFriendlyId(uid),
      'shortId': generateShortId(uid),
      'isValid': isValidLast6Chars(uid),
    };
  }
}

/// Extension methods for String to add UID extraction capabilities
extension UidStringExtension on String? {
  /// Extension method to directly extract last 6 characters from any string
  String get last6Chars => UidExtraction.extractLast6Digits(this);

  /// Extension method to extract last N characters
  String lastNChars(int n) => UidExtraction.extractLastNChars(this, n);

  /// Extension method to check if last 6 characters are valid
  bool get isValidLast6 => UidExtraction.isValidLast6Chars(this);
}
