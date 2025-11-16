import 'dart:async';
import 'package:flutter/material.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/messaging/services/voice_message_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath, int duration) onRecordingComplete;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final VoiceMessageService _voiceService = VoiceMessageService();
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _isRecording = false;
  late AnimationController _animationController;
  List<double> _amplitudes = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _voiceService.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onCancel();
      }
      return;
    }

    final started = await _voiceService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
      });

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });
        }

        // Auto-stop at 60 seconds
        if (_recordingSeconds >= 60) {
          _stopRecording();
        }
      });

      // Update amplitude for visualization
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }

        _voiceService.getAmplitude().then((amplitude) {
          if (mounted && _isRecording) {
            setState(() {
              _amplitudes.add(amplitude);
              if (_amplitudes.length > 30) {
                _amplitudes.removeAt(0);
              }
            });
          }
        });
      });
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final filePath = await _voiceService.stopRecording();

    setState(() {
      _isRecording = false;
    });

    if (filePath != null && mounted) {
      widget.onRecordingComplete(filePath, _recordingSeconds);
    }
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    _voiceService.cancelRecording();
    setState(() {
      _isRecording = false;
    });
    widget.onCancel();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryRose.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform Visualization
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildWaveformBars(),
            ),
          ),

          const SizedBox(height: 16),

          // Recording Time
          Text(
            _formatDuration(_recordingSeconds),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRose,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Recording voice message...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel Button
              GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              // Recording Indicator
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryRose,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRose.withOpacity(
                            0.5 + (_animationController.value * 0.5),
                          ),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),

              // Send Button
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Instructions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Cancel',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 40),
              Text(
                'Send',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWaveformBars() {
    if (_amplitudes.isEmpty) {
      return List.generate(
        20,
        (index) => _buildWaveformBar(0.1),
      );
    }

    return _amplitudes.map((amplitude) {
      return _buildWaveformBar(amplitude);
    }).toList();
  }

  Widget _buildWaveformBar(double amplitude) {
    final height = (amplitude * 50).clamp(4.0, 50.0);

    return Container(
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryRose,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
