// Cultural preferences for Indian dating app
class CulturalPreferences {
  // Religious Information
  final String? religion;
  final String? religiousPractice;
  final String? motherTongue;
  final String? community; // Optional sub-community

  // Dietary Preferences
  final String? dietType;
  final String? alcohol;
  final String? smoking;

  // Family & Values
  final String? familyType;
  final String? familyValues;
  final String? marriageTimeline;
  final String? familyInvolvement;
  final String? livingWith;

  // Astrology Basics
  final DateTime? birthDateTime;
  final String? zodiacSign; // Rashi
  final String? nakshatra;
  final bool? manglik;

  // Professional & Education
  final String? educationLevel;
  final String? educationField;
  final String? profession;
  final String? workLocation;
  final String? incomeRange; // Optional

  // Location
  final String? hometown;
  final String? currentCity;
  final String? state;
  final bool? willingToRelocate;
  final bool? isNRI; // Non-Resident Indian

  CulturalPreferences({
    this.religion,
    this.religiousPractice,
    this.motherTongue,
    this.community,
    this.dietType,
    this.alcohol,
    this.smoking,
    this.familyType,
    this.familyValues,
    this.marriageTimeline,
    this.familyInvolvement,
    this.livingWith,
    this.birthDateTime,
    this.zodiacSign,
    this.nakshatra,
    this.manglik,
    this.educationLevel,
    this.educationField,
    this.profession,
    this.workLocation,
    this.incomeRange,
    this.hometown,
    this.currentCity,
    this.state,
    this.willingToRelocate,
    this.isNRI,
  });

  Map<String, dynamic> toMap() {
    return {
      'religion': religion,
      'religiousPractice': religiousPractice,
      'motherTongue': motherTongue,
      'community': community,
      'dietType': dietType,
      'alcohol': alcohol,
      'smoking': smoking,
      'familyType': familyType,
      'familyValues': familyValues,
      'marriageTimeline': marriageTimeline,
      'familyInvolvement': familyInvolvement,
      'livingWith': livingWith,
      'birthDateTime': birthDateTime?.toIso8601String(),
      'zodiacSign': zodiacSign,
      'nakshatra': nakshatra,
      'manglik': manglik,
      'educationLevel': educationLevel,
      'educationField': educationField,
      'profession': profession,
      'workLocation': workLocation,
      'incomeRange': incomeRange,
      'hometown': hometown,
      'currentCity': currentCity,
      'state': state,
      'willingToRelocate': willingToRelocate,
      'isNRI': isNRI,
    };
  }

  factory CulturalPreferences.fromMap(Map<String, dynamic> map) {
    return CulturalPreferences(
      religion: map['religion'],
      religiousPractice: map['religiousPractice'],
      motherTongue: map['motherTongue'],
      community: map['community'],
      dietType: map['dietType'],
      alcohol: map['alcohol'],
      smoking: map['smoking'],
      familyType: map['familyType'],
      familyValues: map['familyValues'],
      marriageTimeline: map['marriageTimeline'],
      familyInvolvement: map['familyInvolvement'],
      livingWith: map['livingWith'],
      birthDateTime: map['birthDateTime'] != null
          ? DateTime.parse(map['birthDateTime'])
          : null,
      zodiacSign: map['zodiacSign'],
      nakshatra: map['nakshatra'],
      manglik: map['manglik'],
      educationLevel: map['educationLevel'],
      educationField: map['educationField'],
      profession: map['profession'],
      workLocation: map['workLocation'],
      incomeRange: map['incomeRange'],
      hometown: map['hometown'],
      currentCity: map['currentCity'],
      state: map['state'],
      willingToRelocate: map['willingToRelocate'],
      isNRI: map['isNRI'],
    );
  }
}

// Option lists for dropdowns
class CulturalOptions {
  static const List<String> religions = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Buddhist',
    'Jain',
    'Parsi',
    'Jewish',
    'Bahai',
    'No Religion',
    'Spiritual',
    'Other',
  ];

  static const List<String> religiousPractice = [
    'Very Religious',
    'Religious',
    'Moderate',
    'Liberal',
    'Not Religious',
  ];

  static const List<String> motherTongues = [
    'Hindi',
    'English',
    'Telugu',
    'Tamil',
    'Marathi',
    'Bengali',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Odia',
    'Urdu',
    'Assamese',
    'Sindhi',
    'Konkani',
    'Nepali',
    'Manipuri',
    'Kashmiri',
    'Sanskrit',
    'Other',
  ];

  static const List<String> dietTypes = [
    'Vegetarian',
    'Non-Vegetarian',
    'Eggetarian',
    'Vegan',
    'Jain',
    'Occasionally Non-Veg',
  ];

  static const List<String> alcoholOptions = [
    'Never',
    'Occasionally',
    'Socially',
    'Regular',
  ];

  static const List<String> smokingOptions = [
    'Never',
    'Occasionally',
    'Regular',
    'Trying to Quit',
  ];

  static const List<String> familyTypes = [
    'Nuclear Family',
    'Joint Family',
    'Extended Family',
    'Single Parent',
    'Living Alone',
  ];

  static const List<String> familyValues = [
    'Traditional',
    'Moderate',
    'Liberal',
    'Modern',
    'Progressive',
  ];

  static const List<String> marriageTimelines = [
    'As soon as possible',
    'Within 6 months',
    'Within 1 year',
    '1-2 years',
    '2-3 years',
    '3+ years',
    'Not sure yet',
  ];

  static const List<String> familyInvolvement = [
    'Family knows I\'m looking',
    'Will tell family soon',
    'Family is involved',
    'It\'s my decision',
    'Prefer not to say',
  ];

  static const List<String> livingWith = [
    'With Parents',
    'With Family',
    'Alone',
    'With Roommates',
    'With Relatives',
    'In Hostel/PG',
  ];

  static const List<String> educationLevels = [
    'High School',
    'Diploma',
    'Bachelor\'s',
    'Master\'s',
    'Doctorate',
    'Professional Degree',
    'Other',
  ];

  static const List<String> educationFields = [
    'Engineering',
    'Medicine',
    'Business/MBA',
    'Computer Science/IT',
    'Law',
    'Arts',
    'Science',
    'Commerce',
    'Architecture',
    'Design',
    'Teaching',
    'Civil Services',
    'Other',
  ];

  static const List<String> professions = [
    'Software Professional',
    'Doctor',
    'Engineer',
    'Business Owner',
    'Government Service',
    'Teacher/Professor',
    'Banker',
    'Consultant',
    'Lawyer',
    'Armed Forces',
    'Civil Services',
    'Artist/Creative',
    'Entrepreneur',
    'Healthcare Professional',
    'Marketing Professional',
    'Sales Professional',
    'Student',
    'Other',
  ];

  static const List<String> incomeRanges = [
    'Prefer not to say',
    'Student/Not earning',
    '₹0-3 LPA',
    '₹3-5 LPA',
    '₹5-10 LPA',
    '₹10-15 LPA',
    '₹15-20 LPA',
    '₹20-30 LPA',
    '₹30-50 LPA',
    '₹50+ LPA',
    'Settled Abroad',
  ];

  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Abroad/NRI',
  ];

  static const List<String> zodiacSigns = [
    'Aries (Mesh)',
    'Taurus (Vrishabha)',
    'Gemini (Mithun)',
    'Cancer (Kark)',
    'Leo (Simha)',
    'Virgo (Kanya)',
    'Libra (Tula)',
    'Scorpio (Vrishchik)',
    'Sagittarius (Dhanu)',
    'Capricorn (Makar)',
    'Aquarius (Kumbh)',
    'Pisces (Meen)',
  ];

  static const List<String> nakshatras = [
    'Ashwini',
    'Bharani',
    'Krittika',
    'Rohini',
    'Mrigashira',
    'Ardra',
    'Punarvasu',
    'Pushya',
    'Ashlesha',
    'Magha',
    'Purva Phalguni',
    'Uttara Phalguni',
    'Hasta',
    'Chitra',
    'Swati',
    'Vishakha',
    'Anuradha',
    'Jyeshtha',
    'Mula',
    'Purva Ashadha',
    'Uttara Ashadha',
    'Shravana',
    'Dhanishta',
    'Shatabhisha',
    'Purva Bhadrapada',
    'Uttara Bhadrapada',
    'Revati',
  ];
}