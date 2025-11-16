# Integration Guide for New Features

## How to Integrate Voice Messages into ConversationScreen

### Step 1: Add Voice Message Service Provider
```dart
// At the top of conversation_screen.dart
import 'package:indira_love/features/messaging/services/voice_message_service.dart';
import 'package:indira_love/features/messaging/presentation/widgets/voice_message_widget.dart';
import 'package:indira_love/features/messaging/presentation/widgets/voice_recorder_widget.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  // ... existing code
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final VoiceMessageService _voiceService = VoiceMessageService();
  bool _showVoiceRecorder = false;

  // ... existing code
}
```

### Step 2: Add Microphone Button to Message Input
```dart
// In your message input Row widget
Row(
  children: [
    // Existing text field
    Expanded(
      child: TextField(
        controller: _messageController,
        // ... existing config
      ),
    ),

    // Add voice message button
    IconButton(
      icon: Icon(Icons.mic),
      onPressed: () {
        setState(() {
          _showVoiceRecorder = true;
        });
      },
    ),

    // Existing send button
    IconButton(
      icon: Icon(Icons.send),
      onPressed: _sendMessage,
    ),
  ],
)
```

### Step 3: Show Voice Recorder Modal
```dart
// Add this to your build method
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... existing scaffold content

    // Add bottom sheet for voice recorder
    bottomSheet: _showVoiceRecorder
        ? VoiceRecorderWidget(
            onRecordingComplete: (filePath, duration) async {
              setState(() {
                _showVoiceRecorder = false;
              });

              // Upload and send voice message
              final result = await _voiceService.uploadVoiceMessage(
                filePath,
                duration,
              );

              if (result != null) {
                await _voiceService.sendVoiceMessage(
                  widget.matchId,
                  result['url'],
                  result['duration'],
                );
              }
            },
            onCancel: () {
              setState(() {
                _showVoiceRecorder = false;
              });
            },
          )
        : null,
  );
}
```

### Step 4: Display Voice Messages in Chat
```dart
// In your message list builder
Widget _buildMessage(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final type = data['type'] as String? ?? 'text';

  if (type == 'voice') {
    return VoiceMessageWidget(
      messageId: doc.id,
      voiceUrl: data['voiceUrl'],
      duration: data['duration'],
      isSender: data['senderId'] == currentUserId,
    );
  }

  // Existing text message handling
  return _buildTextMessage(data);
}
```

### Step 5: Cleanup on Dispose
```dart
@override
void dispose() {
  _voiceService.dispose();
  super.dispose();
}
```

---

## How to Integrate Scam Detection into Messaging

### Step 1: Add Scam Detection Service
```dart
// At the top of conversation_screen.dart
import 'package:indira_love/core/services/scam_detection_service.dart';

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScamDetectionService _scamService = ScamDetectionService();

  // ... existing code
}
```

### Step 2: Check Messages Before Sending
```dart
Future<void> _sendMessage() async {
  final message = _messageController.text.trim();

  if (message.isEmpty) return;

  // Check for scam indicators
  final result = await _scamService.checkMessage(message);

  if (result['shouldBlock'] == true) {
    // Message blocked
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('This message cannot be sent due to suspicious content.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (result['shouldWarn'] == true) {
    // Show warning dialog
    final shouldSend = await _showScamWarningDialog(
      result['matchedKeywords'] as List<String>,
    );

    if (!shouldSend) return;
  }

  // Proceed with sending message
  await _firestore
      .collection('chats')
      .doc(widget.matchId)
      .collection('messages')
      .add({
    'senderId': currentUserId,
    'text': message,
    'type': 'text',
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': false,
  });

  _messageController.clear();
}
```

### Step 3: Create Warning Dialog
```dart
Future<bool> _showScamWarningDialog(List<String> keywords) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Warning'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_scamService.getWarningMessage(keywords)),
          SizedBox(height: 16),
          Text(
            'Safety Tips:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('• Never send money to people you haven\'t met'),
          Text('• Don\'t share financial information'),
          Text('• Report suspicious behavior'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: Text('Send Anyway'),
        ),
      ],
    ),
  ) ?? false;
}
```

---

## How to Integrate Scam Detection for Profiles

### Step 1: Check New User Profiles
```dart
// In signup_screen.dart or profile creation
Future<void> _createProfile() async {
  // After creating user profile in Firestore
  final userDoc = await _firestore.collection('users').doc(userId).get();
  final userData = userDoc.data()!;

  // Check for scam indicators
  final result = await _scamService.checkProfile(userId, userData);

  if (result['isScammer'] == true) {
    // Auto-report to admin
    await _scamService.autoReportProfile(
      userId,
      (result['reasons'] as List<String>).join(', '),
      result['suspicionScore'],
    );
  }

  if (result['shouldFlag'] == true) {
    // Flag for manual review
    await _firestore.collection('users').doc(userId).update({
      'flaggedForReview': true,
      'flaggedReason': (result['reasons'] as List<String>).join(', '),
    });
  }
}
```

### Step 2: Display Scam Logs in Admin Panel
```dart
// Add to admin_analytics_screen.dart
StreamBuilder<QuerySnapshot>(
  stream: _scamService.getScamLogs(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        final doc = snapshot.data!.docs[index];
        final data = doc.data() as Map<String, dynamic>;

        return Card(
          child: ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text('Scam Attempt: ${data['suspicionScore']} points'),
            subtitle: Text(
              'Keywords: ${(data['matchedKeywords'] as List).join(', ')}',
            ),
            trailing: Text(
              (data['timestamp'] as Timestamp).toDate().toString(),
            ),
          ),
        );
      },
    );
  },
)
```

---

## How to Show Verification Badge

### Step 1: Add Badge to User Profile Display
```dart
// In user_profile_detail_screen.dart or swipe_card.dart
StreamBuilder<DocumentSnapshot>(
  stream: _firestore.collection('users').doc(userId).snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final userData = snapshot.data!.data() as Map<String, dynamic>;
    final isVerified = userData['isVerified'] as bool? ?? false;

    return Column(
      children: [
        Row(
          children: [
            Text(
              userData['displayName'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isVerified) ...[
              SizedBox(width: 8),
              Icon(
                Icons.verified,
                color: Colors.blue,
                size: 24,
              ),
            ],
          ],
        ),
        // Rest of profile UI
      ],
    );
  },
)
```

### Step 2: Add Verification Button to Profile Screen
```dart
// In profile_screen.dart
ElevatedButton.icon(
  onPressed: () => context.push('/verification'),
  icon: Icon(Icons.verified_user),
  label: Text('Get Verified'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryRose,
  ),
)
```

---

## How to Access Admin Panel

### Step 1: Set Admin Flag in Firestore
1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to `users` collection
4. Find your user document
5. Add field: `isAdmin` (type: boolean, value: true)

### Step 2: Add Admin Button to Profile Screen
```dart
// In profile_screen.dart, only show if user is admin
FutureBuilder<bool>(
  future: _adminService.isAdmin(),
  builder: (context, snapshot) {
    if (snapshot.data != true) return SizedBox.shrink();

    return ListTile(
      leading: Icon(Icons.admin_panel_settings),
      title: Text('Admin Dashboard'),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () => context.push('/admin'),
    );
  },
)
```

---

## Testing Checklist

### Voice Messages:
```dart
// Test cases:
1. Grant microphone permission
2. Record 5-second message
3. Cancel recording mid-way
4. Record full 60-second message
5. Play voice message
6. Pause during playback
7. Play multiple messages sequentially
```

### Scam Detection:
```dart
// Test cases:
1. Send message with "bitcoin investment" (should warn)
2. Send message with "send money urgent" (should block)
3. Create profile with no bio and single photo (should flag)
4. Send 3 scam messages (should auto-block user)
5. Check admin panel for scam logs
```

### Verification:
```dart
// Test cases:
1. Take selfie with eyes closed (should reject)
2. Take selfie with head tilted (should reject)
3. Take selfie with multiple people (should reject)
4. Take valid selfie (should accept)
5. Admin approves verification
6. Badge appears on profile
```

---

## Common Issues & Solutions

### Issue: Voice recording not working
**Solution**: Check microphone permissions in AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### Issue: Scam detection too sensitive
**Solution**: Adjust score thresholds in scam_detection_service.dart:
```dart
return {
  'isScam': suspicionScore > 50, // Increase from 30
  'shouldWarn': suspicionScore > 30 && suspicionScore <= 50,
};
```

### Issue: ML Kit face detection slow
**Solution**: Use faster mode in verification_service.dart:
```dart
final faceDetector = FaceDetector(
  options: FaceDetectorOptions(
    performanceMode: FaceDetectorMode.fast, // Changed from accurate
  ),
);
```

### Issue: Admin panel not accessible
**Solution**: Verify isAdmin field is set correctly:
```dart
// In Firestore Console, users/[userId]
{
  "isAdmin": true  // Must be boolean, not string
}
```

---

## Performance Optimization Tips

### 1. Voice Messages:
- Limit message duration to 60 seconds (already implemented)
- Use AAC compression (already implemented)
- Clean up old voice message files periodically

### 2. Scam Detection:
- Cache scam keyword list in memory
- Use Firestore indexes for efficient queries
- Batch process scam logs for admin view

### 3. Verification:
- Compress images before upload
- Use Firebase Storage CDN for fast delivery
- Cache verification status locally

### 4. Admin Panel:
- Implement pagination for large user lists
- Use Firestore count aggregations
- Cache analytics data for 5 minutes

---

## Next Steps

1. **Test all features** using the testing checklist
2. **Deploy Firestore rules** for security
3. **Create admin account** for testing
4. **Build and test APK** on physical device
5. **Monitor Firebase usage** and costs
6. **Gather user feedback** on new features
7. **Iterate and improve** based on feedback

---

*Last updated: November 16, 2025*
