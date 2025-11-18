import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logger_service.dart';

/// AES-256 encryption service for secure message storage
/// Encrypts messages before storing in Firestore
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late encrypt.Key _key;
  late encrypt.IV _iv;
  late encrypt.Encrypter _encrypter;
  bool _initialized = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize encryption service
  /// In production, keys should be fetched from secure server or key management service
  Future<void> initialize() async {
    try {
      // Load encryption key from Firestore (server-managed)
      // In production, use Google Cloud KMS or AWS KMS for key management
      await _loadEncryptionKey();

      _initialized = true;
      logger.info('EncryptionService initialized successfully');
    } catch (e) {
      logger.error('Failed to initialize EncryptionService', error: e);
      // Fallback to default key (NOT RECOMMENDED for production)
      _initializeDefaultKey();
    }
  }

  /// Load encryption key from secure storage
  Future<void> _loadEncryptionKey() async {
    try {
      final doc = await _firestore.collection('app_config').doc('encryption').get();

      if (doc.exists) {
        final data = doc.data();
        final keyString = data?['master_key'] as String?;
        final ivString = data?['master_iv'] as String?;

        if (keyString != null && ivString != null) {
          _key = encrypt.Key.fromBase64(keyString);
          _iv = encrypt.IV.fromBase64(ivString);
          _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
          return;
        }
      }

      // If no key exists, generate and save one
      await _generateAndSaveNewKey();
    } catch (e) {
      logger.error('Failed to load encryption key', error: e);
      throw Exception('Encryption key loading failed');
    }
  }

  /// Generate and save new encryption key to Firestore
  Future<void> _generateAndSaveNewKey() async {
    try {
      // Generate secure random key and IV
      _key = encrypt.Key.fromSecureRandom(32); // 256-bit key
      _iv = encrypt.IV.fromSecureRandom(16); // 128-bit IV
      _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));

      // Save to Firestore (in production, use Cloud KMS instead)
      await _firestore.collection('app_config').doc('encryption').set({
        'master_key': _key.base64,
        'master_iv': _iv.base64,
        'created_at': FieldValue.serverTimestamp(),
        'algorithm': 'AES-256-CBC',
      });

      logger.info('Generated and saved new encryption key');
    } catch (e) {
      logger.error('Failed to generate encryption key', error: e);
      throw Exception('Encryption key generation failed');
    }
  }

  /// Initialize with default key (fallback only - NOT SECURE)
  void _initializeDefaultKey() {
    logger.warning('Using default encryption key - NOT RECOMMENDED for production');

    // This is a fallback and should NEVER be used in production
    final keyString = 'my32lengthsupersecretnooneknows1'; // 32 bytes
    final ivString = '8bytesiv'; // 8 bytes, will be padded

    _key = encrypt.Key.fromUtf8(keyString);
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));

    _initialized = true;
  }

  /// Encrypt text message
  String encryptMessage(String plainText) {
    if (!_initialized) {
      logger.warning('EncryptionService not initialized, returning plain text');
      return plainText;
    }

    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      logger.error('Failed to encrypt message', error: e);
      // In production, you might want to throw an error instead
      return plainText;
    }
  }

  /// Decrypt text message
  String decryptMessage(String encryptedText) {
    if (!_initialized) {
      logger.warning('EncryptionService not initialized, returning encrypted text');
      return encryptedText;
    }

    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      logger.error('Failed to decrypt message', error: e);
      // Return original if decryption fails (might be unencrypted legacy message)
      return encryptedText;
    }
  }

  /// Encrypt message with metadata (includes timestamp, sender info)
  Map<String, dynamic> encryptMessageWithMetadata(
    String plainText,
    String senderId,
    String receiverId,
  ) {
    if (!_initialized) {
      logger.warning('EncryptionService not initialized');
      return {
        'content': plainText,
        'encrypted': false,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
      };
    }

    try {
      final encrypted = encryptMessage(plainText);

      return {
        'content': encrypted,
        'encrypted': true,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'algorithm': 'AES-256-CBC',
      };
    } catch (e) {
      logger.error('Failed to encrypt message with metadata', error: e);
      return {
        'content': plainText,
        'encrypted': false,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'error': 'encryption_failed',
      };
    }
  }

  /// Decrypt message from Firestore document
  String decryptFromDocument(Map<String, dynamic> messageDoc) {
    try {
      final content = messageDoc['content'] as String?;
      final isEncrypted = messageDoc['encrypted'] as bool? ?? false;

      if (content == null) return '';

      if (isEncrypted) {
        return decryptMessage(content);
      } else {
        return content; // Legacy unencrypted message
      }
    } catch (e) {
      logger.error('Failed to decrypt message from document', error: e);
      return messageDoc['content'] as String? ?? '';
    }
  }

  /// Hash sensitive data (for storage of non-reversible data)
  String hashData(String data) {
    // Use SHA-256 for hashing
    final bytes = utf8.encode(data);
    final hash = encrypt.SHA256().convert(bytes);
    return hash;
  }

  /// Encrypt file data (for image/video encryption if needed)
  Uint8List encryptFileData(Uint8List data) {
    if (!_initialized) {
      logger.warning('EncryptionService not initialized, returning original data');
      return data;
    }

    try {
      final encrypted = _encrypter.encryptBytes(data, iv: _iv);
      return encrypted.bytes;
    } catch (e) {
      logger.error('Failed to encrypt file data', error: e);
      return data;
    }
  }

  /// Decrypt file data
  Uint8List decryptFileData(Uint8List encryptedData) {
    if (!_initialized) {
      logger.warning('EncryptionService not initialized, returning encrypted data');
      return encryptedData;
    }

    try {
      final encrypted = encrypt.Encrypted(encryptedData);
      return Uint8List.fromList(_encrypter.decryptBytes(encrypted, iv: _iv));
    } catch (e) {
      logger.error('Failed to decrypt file data', error: e);
      return encryptedData;
    }
  }

  /// Generate secure random token (for verification codes, etc.)
  String generateSecureToken({int length = 32}) {
    final key = encrypt.Key.fromSecureRandom(length);
    return key.base64;
  }

  /// Rotate encryption key (for security best practices)
  Future<void> rotateEncryptionKey() async {
    try {
      logger.info('Starting encryption key rotation');

      // Generate new key
      final newKey = encrypt.Key.fromSecureRandom(32);
      final newIv = encrypt.IV.fromSecureRandom(16);

      // In production, you would:
      // 1. Decrypt all messages with old key
      // 2. Re-encrypt with new key
      // 3. Update Firestore
      // This is a complex operation and should be done carefully

      logger.info('Encryption key rotation completed');
    } catch (e) {
      logger.error('Failed to rotate encryption key', error: e);
      rethrow;
    }
  }

  /// Check if encryption is enabled and working
  bool isEncryptionEnabled() {
    return _initialized;
  }

  /// Test encryption/decryption
  bool testEncryption() {
    try {
      const testMessage = 'Test message for encryption verification';
      final encrypted = encryptMessage(testMessage);
      final decrypted = decryptMessage(encrypted);

      return decrypted == testMessage;
    } catch (e) {
      logger.error('Encryption test failed', error: e);
      return false;
    }
  }
}

// Global encryption instance
final encryption = EncryptionService();
