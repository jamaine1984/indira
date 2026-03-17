import 'package:flutter/material.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/gift_model.dart';
import 'package:indira_love/core/models/subscription_tier.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/services/encryption_service.dart';
import 'package:indira_love/core/services/rate_limiter_service.dart';
import 'package:indira_love/core/services/usage_service.dart';
import 'package:indira_love/core/widgets/watch_ads_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/features/video_call/services/video_call_service.dart';
import 'package:indira_love/features/video_call/presentation/screens/video_call_screen.dart';
import 'package:indira_love/features/icebreakers/services/icebreaker_service.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';
import 'package:indira_love/features/messaging/services/voice_message_service.dart';
import 'package:indira_love/features/messaging/presentation/widgets/voice_recorder_widget.dart';
import 'package:indira_love/features/messaging/presentation/widgets/voice_message_widget.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ConversationScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final EncryptionService _encryption = EncryptionService();
  final RateLimiterService _rateLimiter = RateLimiterService();
  SubscriptionTier _userTier = SubscriptionTier.free;
  bool _showGiftPicker = false;
  bool _isUploading = false;
  bool _isRecording = false;
  final VoiceMessageService _voiceService = VoiceMessageService();

  @override
  void initState() {
    super.initState();
    _initializeEncryption();
    _loadUserTier();
    _markMessagesAsRead();
  }

  Future<void> _initializeEncryption() async {
    await _encryption.initialize();
    logger.info('[Encryption] Service initialized: ${_encryption.isEncryptionEnabled()}');
  }

  Future<void> _loadUserTier() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final tierString = doc.data()?['subscriptionTier'] as String?;
        setState(() {
          _userTier = tierString == 'silver'
              ? SubscriptionTier.silver
              : tierString == 'gold'
                  ? SubscriptionTier.gold
                  : SubscriptionTier.free;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadIcebreakerData() async {
    final currentUser = AuthService().currentUser;
    final currentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .get();
    final otherDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();
    return {
      'current': currentDoc.data() ?? {},
      'other': otherDoc.data() ?? {},
    };
  }

  Future<void> _initiateCall({required bool audioOnly}) async {
    try {
      // Check video minute balance first
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final usageService = UsageService();
      final hasMinutes = await usageService.canMakeCall(currentUser.uid);
      if (!mounted) return;

      if (!hasMinutes) {
        AppSnackBar.info(context, 'No video minutes available. Watch ads or upgrade to earn minutes!');
        return;
      }

      // Check if user is allowed to call (mutual match or messaging history required)
      final permission = await VideoCallService().canCall(widget.otherUserId);
      if (!mounted) return;

      if (permission['allowed'] != true) {
        AppSnackBar.info(context, permission['reason'] as String? ?? 'You cannot call this user yet');
        return;
      }

      final result = await VideoCallService().initiateCall(
        targetUserId: widget.otherUserId,
        targetUserName: widget.otherUserName,
        audioOnly: audioOnly,
      );
      if (!mounted) return;

      if (result['success'] != true) {
        AppSnackBar.error(context, result['error'] as String? ?? 'Could not start call');
        return;
      }

      final sessionId = result['sessionId'] as String;

      // Show "Calling..." dialog and listen for session status changes
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('video_sessions')
                  .doc(sessionId)
                  .snapshots(),
              builder: (context, snapshot) {
                final sessionData = snapshot.data?.data() as Map<String, dynamic>?;
                final status = sessionData?['status'] ?? 'ringing';

                // Handle accepted - navigate to VideoCallScreen
                if (status == 'active') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (context) => VideoCallScreen(
                          sessionId: sessionId,
                          targetUserId: widget.otherUserId,
                          targetUserName: widget.otherUserName,
                          isAudio: audioOnly,
                        ),
                      ),
                    );
                  });
                }

                // Handle rejected
                if (status == 'rejected') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    AppSnackBar.info(this.context, '${widget.otherUserName} declined the call');
                  });
                }

                // Handle cancelled by callee or timeout
                if (status == 'cancelled' || status == 'ended') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                  });
                }

                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryRose),
                      const SizedBox(height: 16),
                      Text(
                        'Calling ${widget.otherUserName}...',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waiting for ${widget.otherUserName} to answer...',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Cancel the call
                        VideoCallService().cancelCall(sessionId);
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not start call: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    try {
      // Mark all unread messages from the other user as read
      final messages = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.otherUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      logger.error('Error marking messages as read: $e');
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload image to Firebase Storage
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.matchId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Send image message
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'receiverId': widget.otherUserId,
        'type': 'image',
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update last message
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        AppSnackBar.error(context, 'Failed to send image: $e');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRose,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () => _initiateCall(audioOnly: true),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () => _initiateCall(audioOnly: false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .doc(widget.matchId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMessagesYet,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hi to ${widget.otherUserName}!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // AI Icebreaker Suggestions
                        FutureBuilder<Map<String, dynamic>>(
                          future: _loadIcebreakerData(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox.shrink();
                            final data = snap.data!;
                            final suggestions = IcebreakerService().generateIcebreakers(
                              currentUser: data['current'] as Map<String, dynamic>,
                              otherUser: data['other'] as Map<String, dynamic>,
                            );
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('\u{1F4A1}', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Text(l10n.suggestedIcebreakers, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...suggestions.take(3).map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        _messageController.text = s;
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.primaryRose.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(s, style: const TextStyle(fontSize: 13, height: 1.3))),
                                            const SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryRose.withOpacity(0.5)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),

          // Gift Picker (if shown)
          if (_showGiftPicker) _buildGiftPicker(),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final currentUser = AuthService().currentUser;
    final isMe = message['senderId'] == currentUser?.uid;
    final messageType = message['type'] ?? 'text';
    final isRead = message['read'] ?? false;

    Widget messageContent;

    if (messageType == 'image') {
      messageContent = ClipRRectGestureDetector(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show full screen image
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: Center(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: message['imageUrl'] ?? '',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 300,
          ),
          child: CachedNetworkImage(
            imageUrl: message['imageUrl'] ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        ),
      );
    } else if (messageType == 'gift') {
      messageContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message['giftEmoji'] ?? '🎁',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 8),
          Text(
            message['giftName'] ?? 'Gift',
            style: TextStyle(
              color: isMe ? Colors.white : AppTheme.textCharcoal,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (messageType == 'voice') {
      final duration = message['duration'] as int? ?? 0;
      messageContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            color: isMe ? Colors.white : AppTheme.primaryRose,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '\u{1F3A4} ${_voiceService.formatDuration(duration)}',
            style: TextStyle(
              color: isMe ? Colors.white : AppTheme.textCharcoal,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final voiceUrl = message['voiceUrl'] as String?;
              if (voiceUrl != null) {
                _voiceService.playVoiceMessage('msg_${message.hashCode}', voiceUrl);
              }
            },
            child: Icon(
              Icons.play_circle_fill,
              color: isMe ? Colors.white : AppTheme.primaryRose,
              size: 28,
            ),
          ),
        ],
      );
    } else {
      // Get the message text directly - skip encryption for now
      final displayText = message['text'] ?? message['content'] ?? '';

      messageContent = Text(
        displayText,
        style: TextStyle(
          color: isMe ? Colors.white : AppTheme.textCharcoal,
          fontSize: 16,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: messageType == 'image'
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: messageType == 'image'
                  ? Colors.transparent
                  : (isMe ? AppTheme.primaryRose : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(messageType == 'image' ? 12 : 0),
              child: messageContent,
            ),
          ),
          // Read receipt for sent messages
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Icon(
                isRead ? Icons.done_all : Icons.done,
                size: 16,
                color: isRead ? Colors.blue : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget ClipRRectGestureDetector({
    required BorderRadius borderRadius,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  Widget _buildGiftPicker() {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.sendGift,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showGiftPicker = false;
                    });
                  },
                ),
              ],
            ),
          ),
          // Gift Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: GiftCatalog.allGifts.length,
              itemBuilder: (context, index) {
                final gift = GiftCatalog.allGifts[index];
                return GestureDetector(
                  onTap: () => _sendGift(gift),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRose.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            gift.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gift.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textCharcoal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Button
          IconButton(
            icon: const Icon(Icons.image, color: AppTheme.primaryRose),
            onPressed: _isUploading ? null : _pickAndSendImage,
          ),
          // Gift Button
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: AppTheme.primaryRose),
            onPressed: () {
              setState(() {
                _showGiftPicker = !_showGiftPicker;
              });
            },
          ),
          // Voice Note Button
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop_circle : Icons.mic,
              color: _isRecording ? Colors.red : AppTheme.primaryRose,
            ),
            onPressed: _isUploading
                ? null
                : () {
                    if (_isRecording) {
                      _stopAndSendVoiceNote();
                    } else {
                      _startVoiceRecording();
                    }
                  },
          ),
          // Message Input Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: l10n.typeMessage,
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button or Loading
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryRose,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _sendTextMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryRose,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _startVoiceRecording() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    // Request microphone permission via permission_handler (shows system dialog on Android 13+)
    final hasPermission = await _voiceService.requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        AppSnackBar.error(context, 'Microphone permission is required for voice notes. Please enable it in Settings.');
      }
      return;
    }

    // Check daily voice note limit
    final usageService = UsageService();
    final canSend = await usageService.canSendVoiceNote(currentUser.uid);
    if (!canSend) {
      if (mounted) {
        showWatchAdsDialog(
          context,
          type: 'voice_notes',
          adsRequired: 2,
          onComplete: () async {
            await usageService.refillVoiceNotes(currentUser.uid, 2);
            _startVoiceRecording(); // Retry
          },
        );
      }
      return;
    }

    final started = await _voiceService.startRecording();
    if (started && mounted) {
      setState(() => _isRecording = true);
      AppSnackBar.info(context, 'Recording... 15s max. Tap stop to send');
      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isRecording) {
          _stopAndSendVoiceNote();
        }
      });
    } else if (mounted) {
      AppSnackBar.error(context, 'Failed to start recording. Please try again.');
    }
  }

  Future<void> _stopAndSendVoiceNote() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    setState(() => _isRecording = false);

    final filePath = await _voiceService.stopRecording();
    if (filePath == null) return;

    setState(() => _isUploading = true);

    try {
      final duration = await _voiceService.getAudioDuration(filePath);
      final result = await _voiceService.uploadVoiceMessage(filePath, duration);

      if (result != null) {
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .collection('messages')
            .add({
          'senderId': currentUser.uid,
          'receiverId': widget.otherUserId,
          'type': 'voice',
          'voiceUrl': result['url'],
          'duration': result['duration'],
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        await FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .update({
          'lastMessage': '\u{1F3A4} Voice message',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        // Increment voice note usage
        await UsageService().incrementVoiceNoteCount(currentUser.uid);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to send voice note: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelVoiceRecording() async {
    await _voiceService.cancelRecording();
    if (mounted) setState(() => _isRecording = false);
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    // Check daily message limit FIRST
    final usageService = UsageService();
    final canSend = await usageService.canSendMessage(currentUser.uid);
    if (!canSend) {
      logger.info('[Usage] Daily message limit reached for user: ${currentUser.uid}');
      if (mounted) {
        // Show watch ads dialog to refill messages
        showWatchAdsDialog(
          context,
          type: 'messages',
          adsRequired: 2,
          onComplete: () async {
            await usageService.refillMessages(currentUser.uid, 2);
            // Try sending the message again after refill
            _sendTextMessage();
          },
        );
      }
      return;
    }

    // RATE LIMITING: Check if user can send message (rapid fire prevention)
    final messageLimit = await _rateLimiter.checkMessageLimit(currentUser.uid);
    if (!messageLimit.allowed) {
      logger.logSecurityEvent('[RateLimit] Message blocked: ${messageLimit.reason}');
      if (mounted) {
        AppSnackBar.error(context, 'Slow down! ${messageLimit.reason}');
      }
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Send message without encryption for now
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'receiverId': widget.otherUserId,
        'text': messageText,
        'encrypted': false, // No encryption for now
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Increment daily message count
      await usageService.incrementMessageCount(currentUser.uid);

      // Update last message in match doc
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'lastMessage': messageText,
        'lastMessageEncrypted': false,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to send message: $e');
      }
    }
  }

  Future<void> _sendGift(GiftModel gift) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    // Check tier and show ad if needed
    if (_userTier == SubscriptionTier.gold) {
      // Send directly
      await _sendGiftMessage(gift);
    } else {
      // Watch ad first
      showWatchAdsDialog(
        context,
        type: 'gift',
        adsRequired: 1,
        onComplete: () async {
          await _sendGiftMessage(gift);
        },
      );
    }
  }

  Future<void> _sendGiftMessage(GiftModel gift) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      if (mounted) {
        AppSnackBar.error(context, 'User not authenticated');
      }
      return;
    }

    try {
      // Save to messages collection
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'receiverId': widget.otherUserId,
        'type': 'gift',
        'giftId': gift.id,
        'giftName': gift.name,
        'giftEmoji': gift.emoji,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Save to user_gifts collection for inventory (don't fail if this errors)
      try {
        await FirebaseFirestore.instance
            .collection('user_gifts')
            .add({
          'senderId': currentUser.uid,
          'receiverId': widget.otherUserId,
          'giftId': gift.id,
          'giftName': gift.name,
          'giftEmoji': gift.emoji,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      } catch (e) {
        logger.warning('Warning: Could not save to user_gifts: $e');
      }

      // Update last message in match doc
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'lastMessage': '${gift.emoji} Sent a gift',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _showGiftPicker = false;
        });

        AppSnackBar.success(context, '${gift.emoji} ${gift.name} sent successfully!');
      }

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      logger.error('Error sending gift: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to send gift: $e');
      }
    }
  }
}
