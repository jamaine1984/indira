import 'package:cloud_firestore/cloud_firestore.dart';
import 'logger_service.dart';

/// Comprehensive input validation and sanitization service
/// Prevents XSS, injection attacks, and validates all user inputs
class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Profanity filter list (loaded from Firestore for easy updates)
  Set<String> _profanityList = {};
  bool _profanityLoaded = false;

  /// Initialize validation service and load profanity list
  Future<void> initialize() async {
    try {
      await _loadProfanityList();
      logger.info('ValidationService initialized successfully');
    } catch (e) {
      logger.error('Failed to initialize ValidationService', error: e);
    }
  }

  /// Load profanity list from Firestore
  Future<void> _loadProfanityList() async {
    try {
      final doc = await _firestore.collection('app_config').doc('profanity_filter').get();
      if (doc.exists) {
        final data = doc.data();
        final List<dynamic>? words = data?['words'];
        if (words != null) {
          _profanityList = words.map((w) => w.toString().toLowerCase()).toSet();
        }
      }

      // Fallback to basic profanity list if Firestore is empty
      if (_profanityList.isEmpty) {
        _profanityList = _getDefaultProfanityList();
      }

      _profanityLoaded = true;
      logger.info('Loaded ${_profanityList.length} profanity words');
    } catch (e) {
      logger.warning('Failed to load profanity list from Firestore, using defaults', error: e);
      _profanityList = _getDefaultProfanityList();
      _profanityLoaded = true;
    }
  }

  /// Get default profanity list (basic starter set)
  Set<String> _getDefaultProfanityList() {
    return {
      // Common profanity (add more as needed)
      'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'damn', 'hell',
      'cunt', 'dick', 'pussy', 'cock', 'slut', 'whore', 'fag', 'nigger',
      // Scam-related terms
      'sugar daddy', 'sugar mommy', 'bitcoin', 'crypto', 'investment',
      'wire transfer', 'send money', 'cash app', 'venmo', 'paypal',
      'onlyfans', 'premium snap', 'tribute',
      // Explicit sexual content
      'nude', 'nudes', 'naked', 'sex tape', 'porn', 'xxx',
    };
  }

  /// Validate and sanitize display name
  ValidationResult validateDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult(false, 'Display name is required');
    }

    final sanitized = sanitizeText(name);

    if (sanitized.length < 2) {
      return ValidationResult(false, 'Display name must be at least 2 characters');
    }

    if (sanitized.length > 50) {
      return ValidationResult(false, 'Display name must be less than 50 characters');
    }

    // Only allow letters, numbers, spaces, and basic punctuation
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s\-\'\.]+$');
    if (!nameRegex.hasMatch(sanitized)) {
      return ValidationResult(false, 'Display name contains invalid characters');
    }

    // Check for profanity
    if (containsProfanity(sanitized)) {
      return ValidationResult(false, 'Display name contains inappropriate content');
    }

    return ValidationResult(true, 'Valid', sanitized);
  }

  /// Validate and sanitize bio/about text
  ValidationResult validateBio(String? bio) {
    if (bio == null || bio.trim().isEmpty) {
      return ValidationResult(true, 'Valid', ''); // Bio is optional
    }

    final sanitized = sanitizeText(bio);

    if (sanitized.length > 500) {
      return ValidationResult(false, 'Bio must be less than 500 characters');
    }

    // Check for profanity
    if (containsProfanity(sanitized)) {
      return ValidationResult(false, 'Bio contains inappropriate content');
    }

    // Check for potential scam content
    if (containsScamKeywords(sanitized)) {
      return ValidationResult(false, 'Bio contains prohibited content');
    }

    // Check for URLs (not allowed in bio)
    if (containsUrl(sanitized)) {
      return ValidationResult(false, 'URLs are not allowed in bio');
    }

    // Check for contact information
    if (containsContactInfo(sanitized)) {
      return ValidationResult(false, 'Contact information is not allowed in bio');
    }

    return ValidationResult(true, 'Valid', sanitized);
  }

  /// Validate and sanitize message content
  ValidationResult validateMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return ValidationResult(false, 'Message cannot be empty');
    }

    final sanitized = sanitizeText(message);

    if (sanitized.length > 2000) {
      return ValidationResult(false, 'Message must be less than 2000 characters');
    }

    // Check for profanity (less strict for messages)
    if (containsExcessiveProfanity(sanitized)) {
      return ValidationResult(false, 'Message contains excessive inappropriate content');
    }

    // Check for scam patterns
    if (containsScamKeywords(sanitized)) {
      return ValidationResult(false, 'Message contains prohibited content');
    }

    return ValidationResult(true, 'Valid', sanitized);
  }

  /// Validate email format
  ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult(false, 'Email is required');
    }

    final sanitized = sanitizeText(email.toLowerCase());

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(sanitized)) {
      return ValidationResult(false, 'Invalid email format');
    }

    return ValidationResult(true, 'Valid', sanitized);
  }

  /// Validate password strength
  ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult(false, 'Password is required');
    }

    if (password.length < 8) {
      return ValidationResult(false, 'Password must be at least 8 characters');
    }

    if (password.length > 128) {
      return ValidationResult(false, 'Password is too long');
    }

    // Check for complexity
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUpperCase || !hasLowerCase || !hasDigit) {
      return ValidationResult(
        false,
        'Password must contain uppercase, lowercase, and numbers',
      );
    }

    return ValidationResult(true, 'Valid', password);
  }

  /// Validate age (must be 18+)
  ValidationResult validateAge(int? age) {
    if (age == null) {
      return ValidationResult(false, 'Age is required');
    }

    if (age < 18) {
      return ValidationResult(false, 'You must be at least 18 years old');
    }

    if (age > 120) {
      return ValidationResult(false, 'Invalid age');
    }

    return ValidationResult(true, 'Valid');
  }

  /// Validate phone number
  ValidationResult validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult(true, 'Valid', ''); // Phone is optional
    }

    // Remove all non-digit characters
    final sanitized = phone.replaceAll(RegExp(r'\D'), '');

    if (sanitized.length < 10 || sanitized.length > 15) {
      return ValidationResult(false, 'Invalid phone number');
    }

    return ValidationResult(true, 'Valid', sanitized);
  }

  /// Sanitize text input (remove HTML, scripts, etc.)
  String sanitizeText(String input) {
    String sanitized = input.trim();

    // Remove HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove script tags and content
    sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');

    // Remove potential XSS patterns
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // Remove null bytes
    sanitized = sanitized.replaceAll('\u0000', '');

    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    return sanitized;
  }

  /// Check if text contains profanity
  bool containsProfanity(String text) {
    if (!_profanityLoaded) return false;

    final lowerText = text.toLowerCase();
    final words = lowerText.split(RegExp(r'\s+'));

    for (final word in words) {
      if (_profanityList.contains(word)) {
        return true;
      }
    }

    // Check for partial matches (e.g., "f*ck" variations)
    for (final profanity in _profanityList) {
      if (lowerText.contains(profanity)) {
        return true;
      }
    }

    return false;
  }

  /// Check for excessive profanity (more than 2 instances)
  bool containsExcessiveProfanity(String text) {
    if (!_profanityLoaded) return false;

    final lowerText = text.toLowerCase();
    int count = 0;

    for (final profanity in _profanityList) {
      if (lowerText.contains(profanity)) {
        count++;
        if (count > 2) return true;
      }
    }

    return false;
  }

  /// Check if text contains scam keywords
  bool containsScamKeywords(String text) {
    final lowerText = text.toLowerCase();

    final scamKeywords = [
      'sugar daddy', 'sugar mommy', 'sugar baby',
      'send money', 'wire transfer', 'western union',
      'cash app', 'venmo', 'paypal', 'zelle',
      'bitcoin', 'crypto', 'investment opportunity',
      'onlyfans', 'premium snap', 'tribute',
      'verification fee', 'trust fund', 'inheritance',
      'bank account', 'routing number', 'ssn',
      'gift card', 'amazon card', 'itunes card',
    ];

    for (final keyword in scamKeywords) {
      if (lowerText.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Check if text contains URLs
  bool containsUrl(String text) {
    final urlRegex = RegExp(
      r'(https?:\/\/|www\.)[^\s]+',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(text);
  }

  /// Check if text contains contact information
  bool containsContactInfo(String text) {
    final lowerText = text.toLowerCase();

    // Check for email pattern
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(text)) {
      return true;
    }

    // Check for phone number patterns
    if (RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b').hasMatch(text)) {
      return true;
    }

    // Check for social media handles
    final socialPatterns = ['instagram', 'snapchat', 'whatsapp', 'telegram', 'kik', 'skype'];
    for (final pattern in socialPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Sanitize filename for storage
  String sanitizeFilename(String filename) {
    // Remove path traversal attempts
    String sanitized = filename.replaceAll(RegExp(r'[/\\]'), '_');

    // Remove dangerous characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>:"|?*]'), '_');

    // Limit length
    if (sanitized.length > 255) {
      final extension = sanitized.split('.').last;
      sanitized = '${sanitized.substring(0, 250)}.$extension';
    }

    return sanitized;
  }

  /// Check if input is likely spam
  bool isSpam(String text) {
    // Check for excessive repetition
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final uniqueWords = words.toSet();

    if (words.length > 10 && uniqueWords.length < words.length / 3) {
      return true; // Too much repetition
    }

    // Check for all caps (except short messages)
    if (text.length > 20 && text == text.toUpperCase()) {
      return true;
    }

    // Check for excessive special characters
    final specialCharCount = RegExp(r'[!?@#$%^&*]').allMatches(text).length;
    if (specialCharCount > text.length / 4) {
      return true;
    }

    return false;
  }

  /// Validate and sanitize interests/tags
  ValidationResult validateInterests(List<String> interests) {
    if (interests.isEmpty) {
      return ValidationResult(false, 'Please select at least one interest');
    }

    if (interests.length > 10) {
      return ValidationResult(false, 'Maximum 10 interests allowed');
    }

    final sanitized = <String>[];
    for (final interest in interests) {
      final clean = sanitizeText(interest);
      if (clean.isNotEmpty && clean.length <= 50) {
        sanitized.add(clean);
      }
    }

    return ValidationResult(true, 'Valid', sanitized);
  }
}

/// Validation result model
class ValidationResult {
  final bool isValid;
  final String message;
  final dynamic sanitizedValue;

  ValidationResult(this.isValid, this.message, [this.sanitizedValue]);
}

// Global validation instance
final validation = ValidationService();
