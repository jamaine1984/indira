import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/video_call/presentation/screens/video_call_screen.dart';
import 'package:indira_love/features/video_call/services/video_call_service.dart';
import 'package:indira_love/features/video_call/services/ringtone_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/usage_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String sessionId;
  final String callerId;
  final String callerName;
  final String callType; // 'video' or 'audio'
  final String? callerPhoto;

  const IncomingCallScreen({
    super.key,
    required this.sessionId,
    required this.callerId,
    required this.callerName,
    required this.callType,
    this.callerPhoto,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScaleAnimation;
  String? _callerPhoto;
  final RingtoneService _ringtone = RingtoneService();
  final VideoCallService _videoCallService = VideoCallService();
  bool _isHandled = false;

  @override
  void initState() {
    super.initState();

    _callerPhoto = widget.callerPhoto;

    // Pulse animation for avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Ripple animation for background
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Button scale animation (gentle bounce)
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut),
    );

    if (_callerPhoto == null) _loadCallerPhoto();

    // Start ringtone
    _ringtone.startRinging();

    // Auto-timeout: reject call after 45 seconds if not answered
    Future.delayed(const Duration(seconds: 45), () {
      if (mounted && !_isHandled) {
        _rejectCall();
      }
    });
  }

  Future<void> _loadCallerPhoto() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.callerId)
          .get();
      final photos = doc.data()?['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty && mounted) {
        setState(() => _callerPhoto = photos[0].toString());
      }
    } catch (_) {}
  }

  void _answerCall() async {
    if (_isHandled) return;
    _isHandled = true;

    await _ringtone.stopRinging();

    // Check if the answering user has video minutes
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final hasMinutes = await UsageService().canMakeCall(user.uid);
      if (!hasMinutes) {
        // No minutes - reject the call and show message
        await _videoCallService.rejectCall(widget.sessionId);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No available minutes. Watch ads or upgrade to earn minutes!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    await _videoCallService.answerCall(widget.sessionId);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          sessionId: widget.sessionId,
          targetUserId: widget.callerId,
          targetUserName: widget.callerName,
          isAudio: widget.callType == 'audio',
        ),
      ),
    );
  }

  void _rejectCall() async {
    if (_isHandled) return;
    _isHandled = true;

    await _ringtone.stopRinging();
    await _videoCallService.rejectCall(widget.sessionId);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _buttonScaleController.dispose();
    _ringtone.stopRinging();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.secondaryPlum,
                  AppTheme.primaryRose,
                  AppTheme.secondaryPlum.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // Ripple effect background
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _RipplePainter(
                  progress: _rippleController.value,
                  color: Colors.white.withOpacity(0.08),
                ),
              );
            },
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Call type label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.callType == 'video' ? Icons.videocam : Icons.call,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Incoming ${widget.callType == 'video' ? 'Video' : 'Voice'} Call',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Pulsing avatar with glow rings
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.06);
                    return Transform.scale(
                      scale: scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1 + (_pulseController.value * 0.15)),
                                width: 2,
                              ),
                            ),
                          ),
                          // Middle glow ring
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15 + (_pulseController.value * 0.2)),
                                width: 2,
                              ),
                            ),
                          ),
                          // Avatar container
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2 + (_pulseController.value * 0.15)),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: AppTheme.primaryRose.withOpacity(0.4),
                                  blurRadius: 40,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _callerPhoto != null
                                  ? CachedNetworkImage(
                                      imageUrl: _callerPhoto!,
                                      fit: BoxFit.cover,
                                      width: 140,
                                      height: 140,
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppTheme.primaryRose.withOpacity(0.3),
                                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                                      ),
                                    )
                                  : Container(
                                      color: AppTheme.primaryRose.withOpacity(0.3),
                                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Caller name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // "Calling..." text with dots animation
                Text(
                  'is calling you...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(flex: 3),

                // Answer / Reject buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reject button
                      _CallActionButton(
                        icon: Icons.call_end,
                        label: 'Decline',
                        color: Colors.red,
                        onTap: _rejectCall,
                        scaleAnimation: null,
                      ),
                      // Answer button (with bounce animation)
                      AnimatedBuilder(
                        animation: _buttonScaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _buttonScaleAnimation.value,
                            child: _CallActionButton(
                              icon: widget.callType == 'video'
                                  ? Icons.videocam
                                  : Icons.call,
                              label: 'Answer',
                              color: Colors.green,
                              onTap: _answerCall,
                              scaleAnimation: null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated call action button
class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Animation<double>? scaleAnimation;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for ripple background effect
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    final maxRadius = size.width * 0.8;

    for (int i = 0; i < 4; i++) {
      final rippleProgress = (progress + (i * 0.25)) % 1.0;
      final radius = maxRadius * rippleProgress;
      final opacity = (1.0 - rippleProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
