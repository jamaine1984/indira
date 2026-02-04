import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/location_service.dart';

class MatchingAlgorithmService {
  static final MatchingAlgorithmService _instance = MatchingAlgorithmService._internal();
  factory MatchingAlgorithmService() => _instance;
  MatchingAlgorithmService._internal();

  final LocationService _locationService = LocationService();

  /// Calculate compatibility score between two users (0-100)
  double calculateCompatibilityScore({
    required Map<String, dynamic> currentUser,
    required Map<String, dynamic> potentialMatch,
  }) {
    double totalScore = 0.0;
    int factors = 0;

    // 1. Shared interests (30 points max)
    final myInterests = Set<String>.from(currentUser['interests'] ?? []);
    final theirInterests = Set<String>.from(potentialMatch['interests'] ?? []);
    if (myInterests.isNotEmpty && theirInterests.isNotEmpty) {
      final commonInterests = myInterests.intersection(theirInterests);
      final interestScore = (commonInterests.length / myInterests.length) * 30;
      totalScore += interestScore;
      factors++;
    }

    // 2. Distance proximity (25 points max)
    try {
      final myLocation = currentUser['location'] is GeoPoint ? currentUser['location'] as GeoPoint : null;
      final theirLocation = potentialMatch['location'] is GeoPoint ? potentialMatch['location'] as GeoPoint : null;
      if (myLocation != null && theirLocation != null) {
        final distance = _locationService.calculateDistance(myLocation, theirLocation);
        double distanceScore = 0;
        if (distance < 5) {
          distanceScore = 25; // Very close
        } else if (distance < 25) {
          distanceScore = 20; // Close
        } else if (distance < 50) {
          distanceScore = 15; // Moderate
        } else if (distance < 100) {
          distanceScore = 10; // Far
        } else {
          distanceScore = 5; // Very far
        }
        totalScore += distanceScore;
        factors++;
      }
    } catch (e) {
      // Skip distance scoring if location data is invalid
      logger.warning('Warning: Could not calculate distance score: $e');
    }

    // 3. Age compatibility (15 points max)
    final myAge = currentUser['age'] as int?;
    final theirAge = potentialMatch['age'] as int?;
    if (myAge != null && theirAge != null) {
      final ageDifference = (myAge - theirAge).abs();
      double ageScore = 0;
      if (ageDifference <= 2) {
        ageScore = 15;
      } else if (ageDifference <= 5) {
        ageScore = 12;
      } else if (ageDifference <= 10) {
        ageScore = 8;
      } else {
        ageScore = 4;
      }
      totalScore += ageScore;
      factors++;
    }

    // 4. Activity level (15 points max)
    final theirLastSeen = potentialMatch['lastSeen'] as Timestamp?;
    if (theirLastSeen != null) {
      final hoursSinceLastSeen = DateTime.now()
          .difference(theirLastSeen.toDate())
          .inHours;
      double activityScore = 0;
      if (hoursSinceLastSeen < 1) {
        activityScore = 15; // Very active
      } else if (hoursSinceLastSeen < 24) {
        activityScore = 12; // Active today
      } else if (hoursSinceLastSeen < 72) {
        activityScore = 8; // Active this week
      } else {
        activityScore = 4; // Not very active
      }
      totalScore += activityScore;
      factors++;
    }

    // 5. Cultural & Religious Compatibility (25 points max) - CRITICAL for Indian dating
    final myCultural = currentUser['culturalPreferences'] as Map<String, dynamic>?;
    final theirCultural = potentialMatch['culturalPreferences'] as Map<String, dynamic>?;

    if (myCultural != null && theirCultural != null) {
      double culturalScore = 0;

      // Religion match (10 points) - Very important in India
      if (myCultural['religion'] == theirCultural['religion'] &&
          myCultural['religion'] != null) {
        culturalScore += 10;

        // Additional points for similar religious practice level (2 points)
        if (myCultural['religiousPractice'] == theirCultural['religiousPractice']) {
          culturalScore += 2;
        }
      }

      // Diet compatibility (8 points) - Critical for daily life
      final myDiet = myCultural['dietType'];
      final theirDiet = theirCultural['dietType'];
      if (myDiet == theirDiet && myDiet != null) {
        culturalScore += 8;
      } else if (myDiet == 'Vegetarian' && theirDiet == 'Eggetarian') {
        culturalScore += 4; // Partial compatibility
      } else if ((myDiet == 'Vegetarian' || myDiet == 'Vegan' || myDiet == 'Jain') &&
                 (theirDiet == 'Non-Vegetarian')) {
        culturalScore -= 5; // Major incompatibility
      }

      // Language match (5 points)
      if (myCultural['motherTongue'] == theirCultural['motherTongue'] &&
          myCultural['motherTongue'] != null) {
        culturalScore += 5;
      }

      // Marriage timeline compatibility (5 points)
      final myTimeline = myCultural['marriageTimeline'];
      final theirTimeline = theirCultural['marriageTimeline'];
      if (myTimeline == theirTimeline && myTimeline != null) {
        culturalScore += 5;
      }

      // Family values match (3 points)
      if (myCultural['familyValues'] == theirCultural['familyValues']) {
        culturalScore += 3;
      }

      // Manglik compatibility (Important for many) - penalty for mismatch
      final myManglik = myCultural['manglik'] as bool?;
      final theirManglik = theirCultural['manglik'] as bool?;
      if (myManglik != null && theirManglik != null) {
        if (myManglik == theirManglik) {
          culturalScore += 2; // Bonus for match
        } else {
          culturalScore -= 8; // Significant penalty for mismatch
        }
      }

      totalScore += culturalScore.clamp(0, 25);
      factors++;
    }

    // 6. Professional & Education Match (10 points max)
    if (myCultural != null && theirCultural != null) {
      double professionalScore = 0;

      // Education level compatibility (5 points)
      final myEdu = myCultural['educationLevel'];
      final theirEdu = theirCultural['educationLevel'];
      if (myEdu == theirEdu && myEdu != null) {
        professionalScore += 5;
      } else if (myEdu != null && theirEdu != null) {
        // Partial score for similar education levels
        final eduLevels = ['High School', 'Diploma', "Bachelor's", "Master's", 'Doctorate'];
        final myIndex = eduLevels.indexOf(myEdu);
        final theirIndex = eduLevels.indexOf(theirEdu);
        if (myIndex >= 0 && theirIndex >= 0) {
          final diff = (myIndex - theirIndex).abs();
          if (diff == 1) professionalScore += 3;
          else if (diff == 2) professionalScore += 1;
        }
      }

      // Professional field match (5 points)
      if (myCultural['profession'] == theirCultural['profession']) {
        professionalScore += 5;
      } else if (myCultural['educationField'] == theirCultural['educationField']) {
        professionalScore += 3; // Similar field
      }

      totalScore += professionalScore;
      factors++;
    }

    // 7. Location & NRI Status (10 points max)
    if (myCultural != null && theirCultural != null) {
      double locationScore = 0;

      // Same state (5 points)
      if (myCultural['state'] == theirCultural['state'] && myCultural['state'] != null) {
        locationScore += 5;
      }

      // NRI compatibility (5 points)
      final myNRI = myCultural['isNRI'] as bool? ?? false;
      final theirNRI = theirCultural['isNRI'] as bool? ?? false;
      if (myNRI == theirNRI) {
        locationScore += 5;
      }

      totalScore += locationScore;
      factors++;
    }

    // 8. Profile completeness (10 points max)
    final hasPhotos = (potentialMatch['photos'] as List?)?.isNotEmpty ?? false;
    final hasBio = (potentialMatch['bio'] as String?)?.isNotEmpty ?? false;
    final hasInterests = (potentialMatch['interests'] as List?)?.isNotEmpty ?? false;
    final hasCultural = potentialMatch['culturalPreferences'] != null;
    int completenessScore = 0;
    if (hasPhotos) completenessScore += 3;
    if (hasBio) completenessScore += 2;
    if (hasInterests) completenessScore += 2;
    if (hasCultural) completenessScore += 3; // Cultural info is important
    totalScore += completenessScore;
    factors++;

    // 9. Boost multiplier (bonus points)
    final isBoosted = potentialMatch['isBoosted'] ?? false;
    final boostEndTime = potentialMatch['boostEndTime'] as Timestamp?;
    if (isBoosted &&
        boostEndTime != null &&
        DateTime.now().isBefore(boostEndTime.toDate())) {
      totalScore *= 1.3; // 30% boost to visibility
    }

    // 10. Verification bonus (5 points max)
    final isVerified = potentialMatch['isVerified'] ?? false;
    if (isVerified) {
      totalScore += 5;
      factors++;
    }

    // Normalize score to 0-100 range
    return totalScore.clamp(0, 100);
  }

  /// Sort potential matches by compatibility score
  List<Map<String, dynamic>> sortByCompatibility({
    required Map<String, dynamic> currentUser,
    required List<Map<String, dynamic>> potentialMatches,
  }) {
    // Calculate scores for all matches
    final matchesWithScores = potentialMatches.map((match) {
      final score = calculateCompatibilityScore(
        currentUser: currentUser,
        potentialMatch: match,
      );
      return {
        ...match,
        'compatibilityScore': score,
      };
    }).toList();

    // Sort by score (highest first)
    matchesWithScores.sort((a, b) {
      final scoreA = a['compatibilityScore'] as double;
      final scoreB = b['compatibilityScore'] as double;
      return scoreB.compareTo(scoreA);
    });

    return matchesWithScores;
  }

  /// Filter matches based on user preferences
  List<Map<String, dynamic>> filterByPreferences({
    required Map<String, dynamic> currentUser,
    required List<Map<String, dynamic>> potentialMatches,
  }) {
    // Get user preferences
    final preferences = currentUser['preferences'] as Map<String, dynamic>? ?? {};
    final minAge = preferences['minAge'] as int? ?? 18;
    final maxAge = preferences['maxAge'] as int? ?? 99;
    final maxDistance = preferences['maxDistance'] as int? ?? 100;
    final genderPreference = preferences['genderPreference'] as String?;
    final heightPreference = preferences['heightPreference'] as Map<String, dynamic>?;
    final educationPreference = preferences['educationPreference'] as List<dynamic>?;
    final religionPreference = preferences['religionPreference'] as List<dynamic>?;

    final currentUserLocation = currentUser['location'] is GeoPoint ? currentUser['location'] as GeoPoint : null;

    return potentialMatches.where((match) {
      // Age filter
      final age = match['age'] as int? ?? 0;
      if (age < minAge || age > maxAge) return false;

      // Distance filter
      if (currentUserLocation != null) {
        try {
          final matchLocation = match['location'] is GeoPoint ? match['location'] as GeoPoint : null;
          if (matchLocation != null) {
            final distance = _locationService.calculateDistance(
              currentUserLocation,
              matchLocation,
            );
            if (distance > maxDistance) return false;
          }
        } catch (e) {
          // Skip distance filter if location data is invalid
          logger.warning('Warning: Could not filter by distance: $e');
        }
      }

      // Gender preference filter
      if (genderPreference != null && genderPreference != 'all') {
        final matchGender = match['gender'] as String?;
        if (matchGender != genderPreference) return false;
      }

      // Height filter
      if (heightPreference != null) {
        final minHeight = heightPreference['min'] as int?;
        final maxHeight = heightPreference['max'] as int?;
        final matchHeight = match['height'] as int?;
        if (matchHeight != null && minHeight != null && maxHeight != null) {
          if (matchHeight < minHeight || matchHeight > maxHeight) return false;
        }
      }

      // Education filter
      if (educationPreference != null && educationPreference.isNotEmpty) {
        final matchEducation = match['education'] as String?;
        if (matchEducation == null ||
            !educationPreference.contains(matchEducation)) {
          return false;
        }
      }

      // Religion filter
      if (religionPreference != null && religionPreference.isNotEmpty) {
        final matchReligion = match['religion'] as String?;
        if (matchReligion == null ||
            !religionPreference.contains(matchReligion)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get smart recommendations combining filters and scoring
  Future<List<Map<String, dynamic>>> getSmartRecommendations({
    required Map<String, dynamic> currentUser,
    required List<Map<String, dynamic>> allPotentialMatches,
  }) async {
    // First apply preference filters
    final filtered = filterByPreferences(
      currentUser: currentUser,
      potentialMatches: allPotentialMatches,
    );

    // Then sort by compatibility score
    final sorted = sortByCompatibility(
      currentUser: currentUser,
      potentialMatches: filtered,
    );

    return sorted;
  }

  /// Calculate distance between two users
  double? calculateDistanceBetweenUsers(
    Map<String, dynamic> user1,
    Map<String, dynamic> user2,
  ) {
    try {
      final location1 = user1['location'] is GeoPoint ? user1['location'] as GeoPoint : null;
      final location2 = user2['location'] is GeoPoint ? user2['location'] as GeoPoint : null;

      if (location1 == null || location2 == null) return null;

      return _locationService.calculateDistance(location1, location2);
    } catch (e) {
      logger.warning('Warning: Could not calculate distance between users: $e');
      return null;
    }
  }
}
