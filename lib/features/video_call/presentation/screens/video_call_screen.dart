import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/features/video_call/services/video_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String sessionId;
  final String targetUserId;
  final String targetUserName;
  final bool isAudio;

  const VideoCallScreen({
    super.key,
    required this.sessionId,
    required this.targetUserId,
    required this.targetUserName,
    this.isAudio = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Timer? _durationTimer;
  final VideoCallService _videoCallService = VideoCallService();
  int _callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _callDurationSeconds++);
    });
  }

  Future<void> _endCall() async {
    _durationTimer?.cancel();
    await _videoCallService.endCall(widget.sessionId, _callDurationSeconds);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _videoCallService.endCall(widget.sessionId, _callDurationSeconds);
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No authenticated user')),
      );
    }

    final displayName = currentUser.displayName?.isNotEmpty == true
        ? currentUser.displayName!
        : currentUser.email ?? currentUser.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) await _endCall();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              ZegoUIKitPrebuiltCall(
                appID: 2052516228,
                appSign: '73719726d5771b90798bca8777282976f396de31453f1ed517f86c1c4e686608',
                userID: currentUser.uid,
                userName: displayName,
                callID: widget.sessionId,
                config: widget.isAudio
                    ? ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
                    : (() {
                        final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();
                        config.audioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig(
                          showMicrophoneStateOnView: true,
                          showCameraStateOnView: true,
                          showUserNameOnView: true,
                          showSoundWavesInAudioMode: true,
                          useVideoViewAspectFill: true,
                        );
                        return config;
                      })(),
                events: ZegoUIKitPrebuiltCallEvents(
                  onCallEnd: (event, defaultAction) {
                    _endCall();
                    defaultAction.call();
                  },
                ),
              ),
              // Call duration overlay
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_callDurationSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
