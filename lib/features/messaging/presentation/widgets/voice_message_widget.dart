import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/messaging/services/voice_message_service.dart';

class VoiceMessageWidget extends ConsumerStatefulWidget {
  final String messageId;
  final String voiceUrl;
  final int duration;
  final bool isSender;

  const VoiceMessageWidget({
    super.key,
    required this.messageId,
    required this.voiceUrl,
    required this.duration,
    required this.isSender,
  });

  @override
  ConsumerState<VoiceMessageWidget> createState() =>
      _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends ConsumerState<VoiceMessageWidget> {
  final VoiceMessageService _voiceService = VoiceMessageService();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _listenToPosition();
  }

  void _listenToPosition() {
    _voiceService.positionStream.listen((position) {
      if (_voiceService.isPlayingMessage(widget.messageId)) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      }
    });
  }

  Future<void> _togglePlayback() async {
    await _voiceService.playVoiceMessage(widget.messageId, widget.voiceUrl);
    setState(() {
      _isPlaying = _voiceService.isPlayingMessage(widget.messageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration > 0
        ? _currentPosition.inSeconds / widget.duration
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isSender
            ? AppTheme.primaryRose
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isSender ? Colors.white : AppTheme.primaryRose,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isSender ? AppTheme.primaryRose : Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform/Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: widget.isSender
                        ? Colors.white.withOpacity(0.3)
                        : AppTheme.primaryRose.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isSender ? Colors.white : AppTheme.primaryRose,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),

                // Duration
                Text(
                  _isPlaying
                      ? '${_formatDuration(_currentPosition.inSeconds)} / ${_formatDuration(widget.duration)}'
                      : _formatDuration(widget.duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isSender ? Colors.white : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Voice Icon
          Icon(
            Icons.mic,
            size: 20,
            color: widget.isSender ? Colors.white : AppTheme.primaryRose,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
