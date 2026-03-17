import 'dart:io';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceMessageService {
  // Connect to the nam5 database instance where all users are stored
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentlyPlayingId;

  // Request microphone permission using permission_handler (required for Android 13+)
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;

      // Request the permission - this shows the system dialog
      final result = await Permission.microphone.request();
      if (result.isGranted) return true;

      // If permanently denied, user needs to go to settings
      if (result.isPermanentlyDenied) {
        logger.warning('Microphone permission permanently denied - user must enable in settings');
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      logger.error('Error requesting microphone permission: $e');
      return false;
    }
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      // Use permission_handler for reliable permission request on Android 13+
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        logger.warning('Microphone permission not granted');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      logger.info('Voice recording started at: $filePath');
      return true;
    } catch (e) {
      logger.error('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        logger.warning('[VoiceRecord] stopRecording called but not recording');
        return null;
      }
      final path = await _recorder.stop();
      _isRecording = false;
      logger.info('[VoiceRecord] Recording stopped, path: $path');
      return path;
    } catch (e) {
      logger.error('[VoiceRecord] Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;
    } catch (e) {
      logger.error('Error canceling recording: $e');
    }
  }

  // Get recording state
  bool get isRecording => _isRecording;

  // Get recording amplitude (for waveform visualization)
  Future<double> getAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      return amplitude.current;
    } catch (e) {
      return 0.0;
    }
  }

  // Upload voice message to Firebase Storage
  // matchId is required to match storage rules: voice_messages/{matchId}/{fileName}
  Future<Map<String, dynamic>?> uploadVoiceMessage(
    String filePath,
    int duration, {
    String? matchId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.error('[VoiceUpload] No authenticated user');
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        logger.error('[VoiceUpload] File does not exist at path: $filePath');
        return null;
      }

      final fileSize = await file.length();
      logger.info('[VoiceUpload] File exists, size: $fileSize bytes');

      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // Storage rules require: voice_messages/{matchId}/{fileName}
      final storagePath = matchId != null
          ? 'voice_messages/$matchId/$fileName'
          : 'voice_messages/${user.uid}/$fileName';
      final ref = _storage.ref(storagePath);

      logger.info('[VoiceUpload] Uploading to $storagePath');
      // Must set content type explicitly - putFile doesn't detect m4a as audio
      await ref.putFile(file, SettableMetadata(contentType: 'audio/mp4'));
      final url = await ref.getDownloadURL();
      logger.info('[VoiceUpload] Upload complete, URL obtained');

      return {
        'url': url,
        'duration': duration,
        'fileName': fileName,
      };
    } catch (e) {
      logger.error('[VoiceUpload] Error uploading voice message: $e');
      return null;
    }
  }

  // Send voice message to chat
  Future<void> sendVoiceMessage(
    String matchId,
    String voiceUrl,
    int duration,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'type': 'voice',
        'voiceUrl': voiceUrl,
        'duration': duration,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat's last message
      await _firestore.collection('chats').doc(matchId).update({
        'lastMessage': 'Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': user.uid,
      });
    } catch (e) {
      logger.error('Error sending voice message: $e');
    }
  }

  // Play voice message
  Future<void> playVoiceMessage(String messageId, String url) async {
    try {
      if (_isPlaying && _currentlyPlayingId == messageId) {
        // Pause if currently playing this message
        await _player.pause();
        _isPlaying = false;
        _currentlyPlayingId = null;
      } else {
        // Stop any currently playing message
        if (_isPlaying) {
          await _player.stop();
        }

        // Play new message
        await _player.play(UrlSource(url));
        _isPlaying = true;
        _currentlyPlayingId = messageId;

        // Listen for completion
        _player.onPlayerComplete.listen((_) {
          _isPlaying = false;
          _currentlyPlayingId = null;
        });
      }
    } catch (e) {
      logger.error('Error playing voice message: $e');
    }
  }

  // Pause playback
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      logger.error('Error pausing playback: $e');
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentlyPlayingId = null;
    } catch (e) {
      logger.error('Error stopping playback: $e');
    }
  }

  // Get playback state
  bool isPlayingMessage(String messageId) {
    return _isPlaying && _currentlyPlayingId == messageId;
  }

  // Stream playback position
  Stream<Duration> get positionStream => _player.onPositionChanged;

  // Get audio duration from file
  Future<int> getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setSourceDeviceFile(filePath);

      final duration = await player.getDuration();
      await player.dispose();

      return duration?.inSeconds ?? 0;
    } catch (e) {
      logger.error('Error getting audio duration: $e');
      return 0;
    }
  }

  // Format duration for display
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Dispose
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }

  // Check permission using permission_handler (reliable on Android 13+)
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
}
