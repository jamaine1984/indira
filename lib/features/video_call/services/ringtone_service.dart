import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:indira_love/core/services/logger_service.dart';

class RingtoneService {
  RingtoneService._();
  static final RingtoneService _instance = RingtoneService._();
  factory RingtoneService() => _instance;

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _initialized = false;

  static const List<String> _ttsCallPhrases = [
    'Someone special is calling you!',
    'Love is on the line!',
    'Your match is waiting to talk!',
    'Pick up! Someone wants to connect!',
    'A beautiful connection is calling!',
    'Don\'t miss this call!',
    'Your special someone is calling!',
    'Answer the call of love!',
    'Time to connect! Pick up!',
    'Someone is excited to hear your voice!',
    'A heartfelt call is coming in!',
    'Your match wants to see you!',
    'Love is calling, will you answer?',
    'Pick up, a new connection awaits!',
    'Someone can\'t wait to talk to you!',
  ];

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
      await _tts.setVolume(0.8);

      // Try to set a female voice for a warm tone
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (var voice in voices) {
          if (voice is Map) {
            final name = (voice['name'] ?? '').toString().toLowerCase();
            final locale = (voice['locale'] ?? '').toString().toLowerCase();
            if ((name.contains('female') || name.contains('zira') || name.contains('samantha')) &&
                locale.contains('en')) {
              await _tts.setVoice({'name': voice['name'], 'locale': voice['locale']});
              break;
            }
          }
        }
      }
      _initialized = true;
    } catch (e) {
      logger.error('RingtoneService init error: $e');
    }
  }

  /// Start playing the incoming call ringtone with TTS phrases
  Future<void> startRinging() async {
    if (_isPlaying) return;
    _isPlaying = true;

    await initialize();

    // Play ringtone loop
    _playRingtoneLoop();

    // Speak a random TTS phrase after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_isPlaying) _speakPhrase();
    });
  }

  Future<void> _playRingtoneLoop() async {
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      // Use Android default ringtone notification sound
      await _ringtonePlayer.play(
        AssetSource('audio/ringtone.mp3'),
        volume: 0.6,
      );
    } catch (e) {
      // If no ringtone asset, just rely on TTS
      logger.warning('No ringtone audio found, using TTS only: $e');
    }
  }

  Future<void> _speakPhrase() async {
    if (!_isPlaying) return;
    try {
      final phrase = _ttsCallPhrases[DateTime.now().second % _ttsCallPhrases.length];
      await _tts.speak(phrase);

      // Repeat after TTS completes + delay
      _tts.setCompletionHandler(() {
        if (_isPlaying) {
          Future.delayed(const Duration(seconds: 4), () {
            if (_isPlaying) _speakPhrase();
          });
        }
      });
    } catch (e) {
      logger.error('TTS speak error: $e');
    }
  }

  /// Stop all ringing sounds
  Future<void> stopRinging() async {
    _isPlaying = false;
    try {
      await _ringtonePlayer.stop();
      await _tts.stop();
    } catch (e) {
      logger.error('Error stopping ringtone: $e');
    }
  }

  void dispose() {
    _isPlaying = false;
    _ringtonePlayer.dispose();
    _tts.stop();
  }
}
