import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/features/video_call/services/video_call_service.dart';
import 'package:indira_love/core/services/usage_service.dart';

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
  Timer? _secondTracker;
  final VideoCallService _videoCallService = VideoCallService();
  int _callDurationSeconds = 0;
  int _secondsSinceLastSync = 0;
  int _remainingSeconds = -1; // -1 means loading
  int _consumableSeconds = 0;
  int _subscriptionSeconds = 0;
  bool _hasShownLowMinutesWarning = false;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadInitialBalance();
    _startPerSecondTracking();
  }

  Future<void> _loadInitialBalance() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        _consumableSeconds = (data?['consumableVideoMinutes'] as int?) ?? 0;
        _subscriptionSeconds = (data?['subscriptionVideoMinutes'] as int?) ?? 0;
        final totalSeconds = _consumableSeconds + _subscriptionSeconds;

        setState(() {
          _remainingSeconds = totalSeconds;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      setState(() {
        _remainingSeconds = 0;
        _consumableSeconds = 0;
        _subscriptionSeconds = 0;
        _isLoadingBalance = false;
      });
    }
  }

  void _startPerSecondTracking() {
    _secondTracker = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _callDurationSeconds++;
      _secondsSinceLastSync++;

      // Only deduct if balance is loaded and positive
      if (!_isLoadingBalance && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          // Deduct from subscription first, then consumable
          if (_subscriptionSeconds > 0) {
            _subscriptionSeconds--;
          } else if (_consumableSeconds > 0) {
            _consumableSeconds--;
          }
        });

        // Sync to Firestore every 10 seconds
        if (_secondsSinceLastSync >= 10) {
          await _syncMinutesToFirestore();
          _secondsSinceLastSync = 0;
        }

        // Show warning at 60 seconds remaining
        if (_remainingSeconds == 60 && !_hasShownLowMinutesWarning) {
          _hasShownLowMinutesWarning = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only 1 minute of call time remaining!'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        // Auto-hangup at 0 seconds
        if (_remainingSeconds <= 0) {
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your video minutes have run out.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            await _endCall();
          }
        }
      } else {
        // Still update the UI timer even if no balance
        setState(() {});
      }
    });
  }

  Future<void> _syncMinutesToFirestore() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'consumableVideoMinutes': _consumableSeconds,
        'subscriptionVideoMinutes': _subscriptionSeconds,
      });
    } catch (_) {}
  }

  Future<void> _endCall() async {
    _secondTracker?.cancel();

    // Final sync before ending
    await _syncMinutesToFirestore();

    // Track monthly usage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _callDurationSeconds > 0) {
      await UsageService().incrementCallMinutesUsed(user.uid, _callDurationSeconds);
    }

    await _videoCallService.endCall(widget.sessionId, _callDurationSeconds);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _secondTracker?.cancel();
    _syncMinutesToFirestore();
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
              // Call duration overlay (top left)
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
              // Remaining minutes overlay (top right)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 60
                        ? Colors.red.withOpacity(0.8)
                        : _remainingSeconds < 300
                            ? Colors.orange.withOpacity(0.8)
                            : Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isAudio ? Icons.phone : Icons.videocam,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLoadingBalance
                            ? 'Loading...'
                            : '${(_remainingSeconds / 60).floor()}m ${_remainingSeconds % 60}s left',
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
