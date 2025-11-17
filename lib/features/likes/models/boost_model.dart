import 'package:cloud_firestore/cloud_firestore.dart';

class BoostModel {
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes; // 30, 60, or 120
  final int adsWatched; // How many ads were watched for this boost
  final bool isActive;

  BoostModel({
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.adsWatched,
    required this.isActive,
  });

  factory BoostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoostModel(
      userId: data['userId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 30,
      adsWatched: data['adsWatched'] ?? 0,
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'adsWatched': adsWatched,
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endTime);

  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return endTime.difference(DateTime.now());
  }
}
