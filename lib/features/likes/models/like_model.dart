import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String id;
  final String likerId; // User who sent the like
  final String likedUserId; // User who received the like
  final DateTime timestamp;
  final bool isRevealed; // For blur feature - has user watched ads to reveal?
  final bool isMutualMatch; // Is this a match?

  LikeModel({
    required this.id,
    required this.likerId,
    required this.likedUserId,
    required this.timestamp,
    this.isRevealed = false,
    this.isMutualMatch = false,
  });

  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LikeModel(
      id: doc.id,
      likerId: data['likerId'] ?? '',
      likedUserId: data['likedUserId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRevealed: data['isRevealed'] ?? false,
      isMutualMatch: data['isMutualMatch'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'likerId': likerId,
      'likedUserId': likedUserId,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRevealed': isRevealed,
      'isMutualMatch': isMutualMatch,
    };
  }
}
