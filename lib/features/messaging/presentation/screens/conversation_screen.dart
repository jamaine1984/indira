import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/gift_model.dart';
import 'package:indira_love/core/models/subscription_tier.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/widgets/watch_ads_dialog.dart';

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
  SubscriptionTier _userTier = SubscriptionTier.free;
  bool _showGiftPicker = false;

  @override
  void initState() {
    super.initState();
    _loadUserTier();
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryRose : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: messageType == 'gift'
            ? Row(
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
              )
            : Text(
                message['text'] ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.textCharcoal,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildGiftPicker() {
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
                const Text(
                  'Send a Gift',
                  style: TextStyle(
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
          // Gift Button
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: AppTheme.primaryRose),
            onPressed: () {
              setState(() {
                _showGiftPicker = !_showGiftPicker;
              });
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
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          GestureDetector(
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

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'receiverId': widget.otherUserId,
        'text': messageText,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update last message in match doc
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'lastMessage': messageText,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
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
    if (currentUser == null) return;

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

      // Save to user_gifts collection for inventory
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

      // Update last message in match doc
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'lastMessage': '${gift.emoji} Sent a gift',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      setState(() {
        _showGiftPicker = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${gift.emoji} ${gift.name} sent!'),
            backgroundColor: Colors.green,
          ),
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send gift: $e')),
        );
      }
    }
  }
}
