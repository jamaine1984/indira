import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class VoiceMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentlyPlayingId;

  // Start recording
  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
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
        return true;
      }
      return false;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;
    } catch (e) {
      print('Error canceling recording: $e');
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
  Future<Map<String, dynamic>?> uploadVoiceMessage(
    String filePath,
    int duration,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final file = File(filePath);
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = _storage.ref('voice_messages/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      return {
        'url': url,
        'duration': duration,
        'fileName': fileName,
      };
    } catch (e) {
      print('Error uploading voice message: $e');
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
      print('Error sending voice message: $e');
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
      print('Error playing voice message: $e');
    }
  }

  // Pause playback
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentlyPlayingId = null;
    } catch (e) {
      print('Error stopping playback: $e');
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
      print('Error getting audio duration: $e');
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

  // Check permission
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }
}
