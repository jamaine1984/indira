import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
    Locale('ta'),
    Locale('ur'),
    Locale('te'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('gu'),
    Locale('pa'),
    Locale('or'),
    Locale('ne'),
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'bn': 'বাংলা (Bengali)',
    'ta': 'தமிழ் (Tamil)',
    'ur': 'اردو (Urdu)',
    'te': 'తెలుగు (Telugu)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
    'mr': 'मराठी (Marathi)',
    'gu': 'ગુજરાતી (Gujarati)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'or': 'ଓଡ଼ିଆ (Odia)',
    'ne': 'नेपाली (Nepali)',
  };

  static const Map<String, String> languageNativeNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'bn': 'বাংলা',
    'ta': 'தமிழ்',
    'ur': 'اردو',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'pa': 'ਪੰਜਾਬੀ',
    'or': 'ଓଡ଼ିଆ',
    'ne': 'नेपाली',
  };

  String get languageCode => locale.languageCode;

  // Get all translations for current locale
  Map<String, String> get _translations {
    switch (locale.languageCode) {
      case 'hi':
        return _hiTranslations;
      case 'bn':
        return _bnTranslations;
      case 'ta':
        return _taTranslations;
      case 'ur':
        return _urTranslations;
      case 'te':
        return _teTranslations;
      case 'kn':
        return _knTranslations;
      case 'ml':
        return _mlTranslations;
      case 'mr':
        return _mrTranslations;
      case 'gu':
        return _guTranslations;
      case 'pa':
        return _paTranslations;
      case 'or':
        return _orTranslations;
      case 'ne':
        return _neTranslations;
      default:
        return _enTranslations;
    }
  }

  String translate(String key) => _translations[key] ?? _enTranslations[key] ?? key;

  // ============================================================
  // COMMON / GENERAL
  // ============================================================
  String get appName => translate('appName');
  String get ok => translate('ok');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get done => translate('done');
  String get next => translate('next');
  String get back => translate('back');
  String get close => translate('close');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get retry => translate('retry');
  String get yes => translate('yes');
  String get no => translate('no');
  String get submit => translate('submit');
  String get send => translate('send');
  String get share => translate('share');
  String get report => translate('report');
  String get block => translate('block');
  String get menu => translate('menu');
  String get settings => translate('settings');
  String get logout => translate('logout');

  // ============================================================
  // AUTH / LOGIN / SIGNUP
  // ============================================================
  String get welcome => translate('welcome');
  String get welcomeSubtitle => translate('welcomeSubtitle');
  String get login => translate('login');
  String get signup => translate('signup');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get forgotPassword => translate('forgotPassword');
  String get createAccount => translate('createAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get orContinueWith => translate('orContinueWith');
  String get signInWithGoogle => translate('signInWithGoogle');
  String get fullName => translate('fullName');
  String get enterEmail => translate('enterEmail');
  String get enterPassword => translate('enterPassword');

  // ============================================================
  // NAVIGATION / TABS
  // ============================================================
  String get discover => translate('discover');
  String get likes => translate('likes');
  String get messages => translate('messages');
  String get matches => translate('matches');
  String get profile => translate('profile');
  String get gifts => translate('gifts');
  String get social => translate('social');
  String get entertainment => translate('entertainment');
  String get premium => translate('premium');
  String get activity => translate('activity');

  // ============================================================
  // DISCOVER / SWIPING
  // ============================================================
  String get discoverPeople => translate('discoverPeople');
  String get noMoreProfiles => translate('noMoreProfiles');
  String get itsAMatch => translate('itsAMatch');
  String get keepSwiping => translate('keepSwiping');
  String get sendMessage => translate('sendMessage');
  String get locationSettings => translate('locationSettings');
  String get culturalFilters => translate('culturalFilters');
  String get boostProfile => translate('boostProfile');

  // ============================================================
  // PROFILE
  // ============================================================
  String get editProfile => translate('editProfile');
  String get about => translate('about');
  String get interests => translate('interests');
  String get photos => translate('photos');
  String get verified => translate('verified');
  String get getVerified => translate('getVerified');
  String get culturalLifestyle => translate('culturalLifestyle');
  String get age => translate('age');
  String get bio => translate('bio');
  String get religion => translate('religion');
  String get motherTongue => translate('motherTongue');
  String get education => translate('education');
  String get profession => translate('profession');
  String get diet => translate('diet');
  String get familyValues => translate('familyValues');
  String get marriageTimeline => translate('marriageTimeline');
  String get community => translate('community');
  String get location => translate('location');
  String get height => translate('height');
  String get manglik => translate('manglik');

  // ============================================================
  // MESSAGING
  // ============================================================
  String get noMessagesYet => translate('noMessagesYet');
  String get sayHi => translate('sayHi');
  String get typeMessage => translate('typeMessage');
  String get suggestedIcebreakers => translate('suggestedIcebreakers');
  String get conversations => translate('conversations');
  String get noConversations => translate('noConversations');

  // ============================================================
  // MATCHES
  // ============================================================
  String get yourMatches => translate('yourMatches');
  String get noMatches => translate('noMatches');
  String get recentMatches => translate('recentMatches');
  String get allMatches => translate('allMatches');
  String get unmatch => translate('unmatch');
  String get unmatchConfirm => translate('unmatchConfirm');

  // ============================================================
  // LIKES
  // ============================================================
  String get peopleWhoLikedYou => translate('peopleWhoLikedYou');
  String get superlikes => translate('superlikes');
  String get noLikesYet => translate('noLikesYet');
  String get sentLikes => translate('sentLikes');

  // ============================================================
  // VIDEO CALLING
  // ============================================================
  String get videoCall => translate('videoCall');
  String get audioCall => translate('audioCall');
  String get incomingCall => translate('incomingCall');
  String get calling => translate('calling');
  String get answer => translate('answer');
  String get reject => translate('reject');
  String get callEnded => translate('callEnded');
  String get endCall => translate('endCall');

  // ============================================================
  // SAFETY
  // ============================================================
  String get safetyCheckin => translate('safetyCheckin');
  String get safetyDescription => translate('safetyDescription');
  String get trustedContactName => translate('trustedContactName');
  String get theirPhoneNumber => translate('theirPhoneNumber');
  String get dateLocation => translate('dateLocation');
  String get duration => translate('duration');
  String get startCheckin => translate('startCheckin');
  String get imSafe => translate('imSafe');
  String get sosAlert => translate('sosAlert');
  String get checkinActive => translate('checkinActive');
  String get timesUp => translate('timesUp');
  String get markedSafe => translate('markedSafe');
  String get sosAlertSent => translate('sosAlertSent');

  // ============================================================
  // KUNDLI / ASTROLOGY
  // ============================================================
  String get kundliMatch => translate('kundliMatch');
  String get kundliDescription => translate('kundliDescription');
  String get yourNakshatra => translate('yourNakshatra');
  String get partnerNakshatra => translate('partnerNakshatra');
  String get yourRashi => translate('yourRashi');
  String get partnerRashi => translate('partnerRashi');
  String get calculateCompatibility => translate('calculateCompatibility');
  String get excellentMatch => translate('excellentMatch');
  String get goodMatch => translate('goodMatch');
  String get averageMatch => translate('averageMatch');
  String get belowAverage => translate('belowAverage');
  String get compatibility => translate('compatibility');

  // ============================================================
  // FESTIVALS
  // ============================================================
  String get festivalEvents => translate('festivalEvents');
  String get happeningNow => translate('happeningNow');
  String get upcomingFestivals => translate('upcomingFestivals');
  String get pastEvents => translate('pastEvents');
  String get interested => translate('interested');
  String get youreGoing => translate('youreGoing');
  String get activities => translate('activities');

  // ============================================================
  // ENTERTAINMENT / GAMES
  // ============================================================
  String get games => translate('games');
  String get loveLanguageQuiz => translate('loveLanguageQuiz');
  String get triviaGame => translate('triviaGame');
  String get thisOrThat => translate('thisOrThat');
  String get wouldYouRather => translate('wouldYouRather');
  String get compatibilityGame => translate('compatibilityGame');
  String get playAgain => translate('playAgain');
  String get score => translate('score');
  String get highScore => translate('highScore');
  String get yourResult => translate('yourResult');
  String get takeLoveLanguageQuiz => translate('takeLoveLanguageQuiz');

  // ============================================================
  // ENDORSEMENTS
  // ============================================================
  String get communityReviews => translate('communityReviews');
  String get endorse => translate('endorse');
  String get endorseThisPerson => translate('endorseThisPerson');
  String get endorsementAnonymous => translate('endorsementAnonymous');
  String get noEndorsementsYet => translate('noEndorsementsYet');

  // ============================================================
  // FAMILY SHARING
  // ============================================================
  String get shareWithFamily => translate('shareWithFamily');

  // ============================================================
  // GIFTS
  // ============================================================
  String get giftShop => translate('giftShop');
  String get sendGift => translate('sendGift');
  String get myGifts => translate('myGifts');
  String get leaderboard => translate('leaderboard');

  // ============================================================
  // SUBSCRIPTION
  // ============================================================
  String get subscription => translate('subscription');
  String get free => translate('free');
  String get silver => translate('silver');
  String get gold => translate('gold');
  String get upgradeToPremium => translate('upgradeToPremium');
  String get currentPlan => translate('currentPlan');

  // ============================================================
  // SETTINGS / LANGUAGE
  // ============================================================
  String get language => translate('language');
  String get selectLanguage => translate('selectLanguage');
  String get languageChanged => translate('languageChanged');
  String get privacy => translate('privacy');
  String get safety => translate('safety');
  String get notifications => translate('notifications');
  String get helpSupport => translate('helpSupport');
  String get termsOfService => translate('termsOfService');
  String get privacyPolicy => translate('privacyPolicy');
  String get communityGuidelines => translate('communityGuidelines');

  // ============================================================
  // MISC
  // ============================================================
  String get fillAllFields => translate('fillAllFields');
  String get blockUser => translate('blockUser');
  String get blockUserConfirm => translate('blockUserConfirm');
  String get userBlocked => translate('userBlocked');
  String get reportUser => translate('reportUser');
  String get remaining => translate('remaining');
  String get noResults => translate('noResults');
  String get seeAll => translate('seeAll');

  // ============================================================
  // ENGLISH TRANSLATIONS (DEFAULT)
  // ============================================================
  static const Map<String, String> _enTranslations = {
    // Common
    'appName': 'Indira Love',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'done': 'Done',
    'next': 'Next',
    'back': 'Back',
    'close': 'Close',
    'search': 'Search',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'retry': 'Retry',
    'yes': 'Yes',
    'no': 'No',
    'submit': 'Submit',
    'send': 'Send',
    'share': 'Share',
    'report': 'Report',
    'block': 'Block',
    'menu': 'Menu',
    'settings': 'Settings',
    'logout': 'Logout',

    // Auth
    'welcome': 'Welcome to Indira Love',
    'welcomeSubtitle': 'Find your perfect match',
    'login': 'Login',
    'signup': 'Sign Up',
    'email': 'Email',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'forgotPassword': 'Forgot Password?',
    'createAccount': 'Create Account',
    'alreadyHaveAccount': 'Already have an account?',
    'dontHaveAccount': "Don't have an account?",
    'orContinueWith': 'Or continue with',
    'signInWithGoogle': 'Sign in with Google',
    'fullName': 'Full Name',
    'enterEmail': 'Enter your email',
    'enterPassword': 'Enter your password',

    // Navigation
    'discover': 'Discover',
    'likes': 'Likes',
    'messages': 'Messages',
    'matches': 'Matches',
    'profile': 'Profile',
    'gifts': 'Gifts',
    'social': 'Social',
    'entertainment': 'Entertainment',
    'premium': 'Premium',
    'activity': 'Activity',

    // Discover
    'discoverPeople': 'Discover People',
    'noMoreProfiles': 'No more profiles nearby',
    'itsAMatch': "It's a Match!",
    'keepSwiping': 'Keep Swiping',
    'sendMessage': 'Send Message',
    'locationSettings': 'Location Settings',
    'culturalFilters': 'Cultural Filters',
    'boostProfile': 'Boost Profile',

    // Profile
    'editProfile': 'Edit Profile',
    'about': 'About',
    'interests': 'Interests',
    'photos': 'Photos',
    'verified': 'Verified',
    'getVerified': 'Get Verified',
    'culturalLifestyle': 'Cultural & Lifestyle',
    'age': 'Age',
    'bio': 'Bio',
    'religion': 'Religion',
    'motherTongue': 'Mother Tongue',
    'education': 'Education',
    'profession': 'Profession',
    'diet': 'Diet',
    'familyValues': 'Family Values',
    'marriageTimeline': 'Marriage Timeline',
    'community': 'Community',
    'location': 'Location',
    'height': 'Height',
    'manglik': 'Manglik',

    // Messaging
    'noMessagesYet': 'No messages yet',
    'sayHi': 'Say hi!',
    'typeMessage': 'Type a message...',
    'suggestedIcebreakers': 'Suggested Icebreakers',
    'conversations': 'Conversations',
    'noConversations': 'No conversations yet',

    // Matches
    'yourMatches': 'Your Matches',
    'noMatches': 'No matches yet',
    'recentMatches': 'Recent Matches',
    'allMatches': 'All Matches',
    'unmatch': 'Unmatch',
    'unmatchConfirm': 'Are you sure you want to unmatch?',

    // Likes
    'peopleWhoLikedYou': 'People Who Liked You',
    'superlikes': 'Super Likes',
    'noLikesYet': 'No likes yet',
    'sentLikes': 'Sent Likes',

    // Video Calling
    'videoCall': 'Video Call',
    'audioCall': 'Audio Call',
    'incomingCall': 'Incoming Call',
    'calling': 'Calling...',
    'answer': 'Answer',
    'reject': 'Reject',
    'callEnded': 'Call Ended',
    'endCall': 'End Call',

    // Safety
    'safetyCheckin': 'Safety Check-In',
    'safetyDescription': "Going on a date? Set a safety timer. If you don't check in by the end, your trusted contact will be alerted.",
    'trustedContactName': 'Trusted Contact Name',
    'theirPhoneNumber': 'Their Phone Number',
    'dateLocation': 'Date Location',
    'duration': 'Duration',
    'startCheckin': 'Start Check-In',
    'imSafe': "I'm Safe",
    'sosAlert': 'SOS Alert',
    'checkinActive': 'Check-In Active',
    'timesUp': "Time's Up!",
    'markedSafe': 'Marked safe! Stay safe out there.',
    'sosAlertSent': 'SOS Alert sent to your trusted contact!',

    // Kundli
    'kundliMatch': 'Kundli Match',
    'kundliDescription': 'Gun Milan (Ashtakoota) - The traditional 36-point Vedic compatibility system used in Hindu matchmaking.',
    'yourNakshatra': 'Your Nakshatra',
    'partnerNakshatra': "Partner's Nakshatra",
    'yourRashi': 'Your Rashi (optional)',
    'partnerRashi': "Partner's Rashi (optional)",
    'calculateCompatibility': 'Calculate Compatibility',
    'excellentMatch': 'Excellent Match',
    'goodMatch': 'Good Match',
    'averageMatch': 'Average Match',
    'belowAverage': 'Below Average',
    'compatibility': 'Compatibility',

    // Festivals
    'festivalEvents': 'Festival Events',
    'happeningNow': 'HAPPENING NOW',
    'upcomingFestivals': 'Upcoming Festivals',
    'pastEvents': 'Past Events',
    'interested': "I'm Interested",
    'youreGoing': "You're Going!",
    'activities': 'Activities',

    // Entertainment
    'games': 'Games',
    'loveLanguageQuiz': 'Love Language Quiz',
    'triviaGame': 'Bollywood & Cricket Trivia',
    'thisOrThat': 'This or That',
    'wouldYouRather': 'Would You Rather',
    'compatibilityGame': 'Compatibility Game',
    'playAgain': 'Play Again',
    'score': 'Score',
    'highScore': 'High Score',
    'yourResult': 'Your Result',
    'takeLoveLanguageQuiz': 'Take Love Language Quiz',

    // Endorsements
    'communityReviews': 'Community Reviews',
    'endorse': 'Endorse',
    'endorseThisPerson': 'Endorse This Person',
    'endorsementAnonymous': 'Your endorsement is anonymous and helps build trust.',
    'noEndorsementsYet': 'No endorsements yet. Be the first to vouch for this person!',

    // Family
    'shareWithFamily': 'Share with Family',

    // Gifts
    'giftShop': 'Gift Shop',
    'sendGift': 'Send Gift',
    'myGifts': 'My Gifts',
    'leaderboard': 'Leaderboard',

    // Subscription
    'subscription': 'Subscription',
    'free': 'Free',
    'silver': 'Silver',
    'gold': 'Gold',
    'upgradeToPremium': 'Upgrade to Premium',
    'currentPlan': 'Current Plan',

    // Settings
    'language': 'Language',
    'selectLanguage': 'Select Language',
    'languageChanged': 'Language changed successfully!',
    'privacy': 'Privacy',
    'safety': 'Safety',
    'notifications': 'Notifications',
    'helpSupport': 'Help & Support',
    'termsOfService': 'Terms of Service',
    'privacyPolicy': 'Privacy Policy',
    'communityGuidelines': 'Community Guidelines',

    // Misc
    'fillAllFields': 'Please fill all fields',
    'blockUser': 'Block User',
    'blockUserConfirm': 'Are you sure you want to block this user? You will not see each other anymore.',
    'userBlocked': 'has been blocked',
    'reportUser': 'Report User',
    'remaining': 'remaining',
    'noResults': 'No results found',
    'seeAll': 'See All',
  };

  // ============================================================
  // HINDI TRANSLATIONS (हिन्दी)
  // ============================================================
  static const Map<String, String> _hiTranslations = {
    // Common
    'appName': 'इंदिरा लव',
    'ok': 'ठीक',
    'cancel': 'रद्द करें',
    'save': 'सहेजें',
    'delete': 'हटाएं',
    'edit': 'संपादित करें',
    'done': 'हो गया',
    'next': 'अगला',
    'back': 'वापस',
    'close': 'बंद करें',
    'search': 'खोजें',
    'loading': 'लोड हो रहा है...',
    'error': 'त्रुटि',
    'success': 'सफल',
    'retry': 'पुनः प्रयास करें',
    'yes': 'हाँ',
    'no': 'नहीं',
    'submit': 'जमा करें',
    'send': 'भेजें',
    'share': 'साझा करें',
    'report': 'रिपोर्ट करें',
    'block': 'ब्लॉक करें',
    'menu': 'मेन्यू',
    'settings': 'सेटिंग्स',
    'logout': 'लॉग आउट',

    // Auth
    'welcome': 'इंदिरा लव में आपका स्वागत है',
    'welcomeSubtitle': 'अपना परफेक्ट मैच खोजें',
    'login': 'लॉग इन',
    'signup': 'साइन अप',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'confirmPassword': 'पासवर्ड की पुष्टि करें',
    'forgotPassword': 'पासवर्ड भूल गए?',
    'createAccount': 'खाता बनाएं',
    'alreadyHaveAccount': 'पहले से खाता है?',
    'dontHaveAccount': 'खाता नहीं है?',
    'orContinueWith': 'या इससे जारी रखें',
    'signInWithGoogle': 'Google से साइन इन करें',
    'fullName': 'पूरा नाम',
    'enterEmail': 'अपना ईमेल दर्ज करें',
    'enterPassword': 'अपना पासवर्ड दर्ज करें',

    // Navigation
    'discover': 'खोजें',
    'likes': 'पसंद',
    'messages': 'संदेश',
    'matches': 'मैच',
    'profile': 'प्रोफ़ाइल',
    'gifts': 'उपहार',
    'social': 'सामाजिक',
    'entertainment': 'मनोरंजन',
    'premium': 'प्रीमियम',
    'activity': 'गतिविधि',

    // Discover
    'discoverPeople': 'लोगों को खोजें',
    'noMoreProfiles': 'आसपास और प्रोफ़ाइल नहीं हैं',
    'itsAMatch': 'यह एक मैच है!',
    'keepSwiping': 'स्वाइप करते रहें',
    'sendMessage': 'संदेश भेजें',
    'locationSettings': 'लोकेशन सेटिंग्स',
    'culturalFilters': 'सांस्कृतिक फ़िल्टर',
    'boostProfile': 'प्रोफ़ाइल बूस्ट करें',

    // Profile
    'editProfile': 'प्रोफ़ाइल संपादित करें',
    'about': 'परिचय',
    'interests': 'रुचियाँ',
    'photos': 'फ़ोटो',
    'verified': 'सत्यापित',
    'getVerified': 'सत्यापित हों',
    'culturalLifestyle': 'सांस्कृतिक और जीवनशैली',
    'age': 'उम्र',
    'bio': 'बायो',
    'religion': 'धर्म',
    'motherTongue': 'मातृभाषा',
    'education': 'शिक्षा',
    'profession': 'पेशा',
    'diet': 'आहार',
    'familyValues': 'पारिवारिक मूल्य',
    'marriageTimeline': 'शादी की समयसीमा',
    'community': 'समुदाय',
    'location': 'स्थान',
    'height': 'ऊँचाई',
    'manglik': 'मांगलिक',

    // Messaging
    'noMessagesYet': 'अभी तक कोई संदेश नहीं',
    'sayHi': 'नमस्ते कहें!',
    'typeMessage': 'संदेश लिखें...',
    'suggestedIcebreakers': 'सुझाए गए आइसब्रेकर',
    'conversations': 'बातचीत',
    'noConversations': 'अभी तक कोई बातचीत नहीं',

    // Matches
    'yourMatches': 'आपके मैच',
    'noMatches': 'अभी तक कोई मैच नहीं',
    'recentMatches': 'हाल के मैच',
    'allMatches': 'सभी मैच',
    'unmatch': 'अनमैच',
    'unmatchConfirm': 'क्या आप वाकई अनमैच करना चाहते हैं?',

    // Likes
    'peopleWhoLikedYou': 'जिन्होंने आपको पसंद किया',
    'superlikes': 'सुपर लाइक',
    'noLikesYet': 'अभी तक कोई लाइक नहीं',
    'sentLikes': 'भेजे गए लाइक',

    // Video Calling
    'videoCall': 'वीडियो कॉल',
    'audioCall': 'ऑडियो कॉल',
    'incomingCall': 'आने वाली कॉल',
    'calling': 'कॉल हो रही है...',
    'answer': 'उत्तर दें',
    'reject': 'अस्वीकार करें',
    'callEnded': 'कॉल समाप्त',
    'endCall': 'कॉल समाप्त करें',

    // Safety
    'safetyCheckin': 'सुरक्षा चेक-इन',
    'safetyDescription': 'डेट पर जा रहे हैं? सुरक्षा टाइमर सेट करें। अगर आप समय पर चेक-इन नहीं करते, तो आपके विश्वसनीय संपर्क को सूचित किया जाएगा।',
    'trustedContactName': 'विश्वसनीय संपर्क का नाम',
    'theirPhoneNumber': 'उनका फ़ोन नंबर',
    'dateLocation': 'डेट का स्थान',
    'duration': 'अवधि',
    'startCheckin': 'चेक-इन शुरू करें',
    'imSafe': 'मैं सुरक्षित हूँ',
    'sosAlert': 'SOS अलर्ट',
    'checkinActive': 'चेक-इन सक्रिय',
    'timesUp': 'समय पूरा!',
    'markedSafe': 'सुरक्षित चिह्नित! सुरक्षित रहें।',
    'sosAlertSent': 'आपके विश्वसनीय संपर्क को SOS अलर्ट भेजा गया!',

    // Kundli
    'kundliMatch': 'कुंडली मिलान',
    'kundliDescription': 'गुण मिलान (अष्टकूट) - हिंदू विवाह में उपयोग होने वाली पारंपरिक 36 अंकों की वैदिक संगतता प्रणाली।',
    'yourNakshatra': 'आपका नक्षत्र',
    'partnerNakshatra': 'साथी का नक्षत्र',
    'yourRashi': 'आपकी राशि (वैकल्पिक)',
    'partnerRashi': 'साथी की राशि (वैकल्पिक)',
    'calculateCompatibility': 'संगतता की गणना करें',
    'excellentMatch': 'उत्कृष्ट मैच',
    'goodMatch': 'अच्छा मैच',
    'averageMatch': 'औसत मैच',
    'belowAverage': 'औसत से कम',
    'compatibility': 'संगतता',

    // Festivals
    'festivalEvents': 'त्योहार कार्यक्रम',
    'happeningNow': 'अभी हो रहा है',
    'upcomingFestivals': 'आगामी त्योहार',
    'pastEvents': 'पिछले कार्यक्रम',
    'interested': 'मुझे रुचि है',
    'youreGoing': 'आप जा रहे हैं!',
    'activities': 'गतिविधियाँ',

    // Entertainment
    'games': 'खेल',
    'loveLanguageQuiz': 'लव लैंग्वेज क्विज़',
    'triviaGame': 'बॉलीवुड और क्रिकेट ट्रिविया',
    'thisOrThat': 'यह या वह',
    'wouldYouRather': 'आप क्या करेंगे',
    'compatibilityGame': 'संगतता खेल',
    'playAgain': 'फिर से खेलें',
    'score': 'स्कोर',
    'highScore': 'उच्चतम स्कोर',
    'yourResult': 'आपका परिणाम',
    'takeLoveLanguageQuiz': 'लव लैंग्वेज क्विज़ लें',

    // Endorsements
    'communityReviews': 'सामुदायिक समीक्षा',
    'endorse': 'समर्थन करें',
    'endorseThisPerson': 'इस व्यक्ति का समर्थन करें',
    'endorsementAnonymous': 'आपका समर्थन गुमनाम है और विश्वास बनाने में मदद करता है।',
    'noEndorsementsYet': 'अभी तक कोई समर्थन नहीं। पहले बनें!',

    // Family
    'shareWithFamily': 'परिवार के साथ साझा करें',

    // Gifts
    'giftShop': 'गिफ्ट शॉप',
    'sendGift': 'उपहार भेजें',
    'myGifts': 'मेरे उपहार',
    'leaderboard': 'लीडरबोर्ड',

    // Subscription
    'subscription': 'सदस्यता',
    'free': 'मुफ्त',
    'silver': 'सिल्वर',
    'gold': 'गोल्ड',
    'upgradeToPremium': 'प्रीमियम में अपग्रेड करें',
    'currentPlan': 'वर्तमान प्लान',

    // Settings
    'language': 'भाषा',
    'selectLanguage': 'भाषा चुनें',
    'languageChanged': 'भाषा सफलतापूर्वक बदल दी गई!',
    'privacy': 'गोपनीयता',
    'safety': 'सुरक्षा',
    'notifications': 'सूचनाएं',
    'helpSupport': 'सहायता और समर्थन',
    'termsOfService': 'सेवा की शर्तें',
    'privacyPolicy': 'गोपनीयता नीति',
    'communityGuidelines': 'सामुदायिक दिशानिर्देश',

    // Misc
    'fillAllFields': 'कृपया सभी फ़ील्ड भरें',
    'blockUser': 'उपयोगकर्ता को ब्लॉक करें',
    'blockUserConfirm': 'क्या आप वाकई इस उपयोगकर्ता को ब्लॉक करना चाहते हैं?',
    'userBlocked': 'को ब्लॉक कर दिया गया है',
    'reportUser': 'उपयोगकर्ता की रिपोर्ट करें',
    'remaining': 'शेष',
    'noResults': 'कोई परिणाम नहीं मिला',
    'seeAll': 'सभी देखें',
  };

  // ============================================================
  // BENGALI TRANSLATIONS (বাংলা)
  // ============================================================
  static const Map<String, String> _bnTranslations = {
    // Common
    'appName': 'ইন্দিরা লাভ',
    'ok': 'ঠিক আছে',
    'cancel': 'বাতিল',
    'save': 'সংরক্ষণ করুন',
    'delete': 'মুছুন',
    'edit': 'সম্পাদনা',
    'done': 'হয়ে গেছে',
    'next': 'পরবর্তী',
    'back': 'পেছনে',
    'close': 'বন্ধ করুন',
    'search': 'অনুসন্ধান',
    'loading': 'লোড হচ্ছে...',
    'error': 'ত্রুটি',
    'success': 'সফল',
    'retry': 'আবার চেষ্টা করুন',
    'yes': 'হ্যাঁ',
    'no': 'না',
    'submit': 'জমা দিন',
    'send': 'পাঠান',
    'share': 'শেয়ার করুন',
    'report': 'রিপোর্ট',
    'block': 'ব্লক',
    'menu': 'মেনু',
    'settings': 'সেটিংস',
    'logout': 'লগ আউট',

    // Auth
    'welcome': 'ইন্দিরা লাভে স্বাগতম',
    'welcomeSubtitle': 'আপনার নিখুঁত সঙ্গী খুঁজুন',
    'login': 'লগ ইন',
    'signup': 'সাইন আপ',
    'email': 'ইমেল',
    'password': 'পাসওয়ার্ড',
    'confirmPassword': 'পাসওয়ার্ড নিশ্চিত করুন',
    'forgotPassword': 'পাসওয়ার্ড ভুলে গেছেন?',
    'createAccount': 'অ্যাকাউন্ট তৈরি করুন',
    'alreadyHaveAccount': 'ইতিমধ্যে অ্যাকাউন্ট আছে?',
    'dontHaveAccount': 'অ্যাকাউন্ট নেই?',
    'orContinueWith': 'অথবা এর সাথে চালিয়ে যান',
    'signInWithGoogle': 'Google দিয়ে সাইন ইন',
    'fullName': 'পুরো নাম',
    'enterEmail': 'আপনার ইমেল দিন',
    'enterPassword': 'আপনার পাসওয়ার্ড দিন',

    // Navigation
    'discover': 'আবিষ্কার',
    'likes': 'পছন্দ',
    'messages': 'বার্তা',
    'matches': 'ম্যাচ',
    'profile': 'প্রোফাইল',
    'gifts': 'উপহার',
    'social': 'সামাজিক',
    'entertainment': 'বিনোদন',
    'premium': 'প্রিমিয়াম',
    'activity': 'কার্যকলাপ',

    // Discover
    'discoverPeople': 'মানুষ আবিষ্কার করুন',
    'noMoreProfiles': 'আশেপাশে আর প্রোফাইল নেই',
    'itsAMatch': 'এটি একটি ম্যাচ!',
    'keepSwiping': 'সোয়াইপ করতে থাকুন',
    'sendMessage': 'বার্তা পাঠান',
    'locationSettings': 'লোকেশন সেটিংস',
    'culturalFilters': 'সাংস্কৃতিক ফিল্টার',
    'boostProfile': 'প্রোফাইল বুস্ট করুন',

    // Profile
    'editProfile': 'প্রোফাইল সম্পাদনা',
    'about': 'সম্পর্কে',
    'interests': 'আগ্রহ',
    'photos': 'ছবি',
    'verified': 'যাচাইকৃত',
    'getVerified': 'যাচাই করুন',
    'culturalLifestyle': 'সংস্কৃতি ও জীবনধারা',
    'age': 'বয়স',
    'bio': 'বায়ো',
    'religion': 'ধর্ম',
    'motherTongue': 'মাতৃভাষা',
    'education': 'শিক্ষা',
    'profession': 'পেশা',
    'diet': 'খাদ্যাভ্যাস',
    'familyValues': 'পারিবারিক মূল্যবোধ',
    'marriageTimeline': 'বিয়ের সময়সীমা',
    'community': 'সম্প্রদায়',
    'location': 'অবস্থান',
    'height': 'উচ্চতা',
    'manglik': 'মাঙ্গলিক',

    // Messaging
    'noMessagesYet': 'এখনো কোনো বার্তা নেই',
    'sayHi': 'হ্যালো বলুন!',
    'typeMessage': 'বার্তা লিখুন...',
    'suggestedIcebreakers': 'প্রস্তাবিত আইসব্রেকার',
    'conversations': 'কথোপকথন',
    'noConversations': 'এখনো কোনো কথোপকথন নেই',

    // Matches
    'yourMatches': 'আপনার ম্যাচ',
    'noMatches': 'এখনো কোনো ম্যাচ নেই',
    'recentMatches': 'সাম্প্রতিক ম্যাচ',
    'allMatches': 'সব ম্যাচ',
    'unmatch': 'আনম্যাচ',
    'unmatchConfirm': 'আপনি কি নিশ্চিত আনম্যাচ করতে চান?',

    // Likes
    'peopleWhoLikedYou': 'যারা আপনাকে পছন্দ করেছে',
    'superlikes': 'সুপার লাইক',
    'noLikesYet': 'এখনো কোনো লাইক নেই',
    'sentLikes': 'পাঠানো লাইক',

    // Video Calling
    'videoCall': 'ভিডিও কল',
    'audioCall': 'অডিও কল',
    'incomingCall': 'ইনকামিং কল',
    'calling': 'কল হচ্ছে...',
    'answer': 'উত্তর দিন',
    'reject': 'প্রত্যাখ্যান',
    'callEnded': 'কল শেষ',
    'endCall': 'কল শেষ করুন',

    // Safety
    'safetyCheckin': 'নিরাপত্তা চেক-ইন',
    'safetyDescription': 'ডেটে যাচ্ছেন? নিরাপত্তা টাইমার সেট করুন। সময়মতো চেক-ইন না করলে আপনার বিশ্বস্ত ব্যক্তিকে জানানো হবে।',
    'trustedContactName': 'বিশ্বস্ত ব্যক্তির নাম',
    'theirPhoneNumber': 'তাদের ফোন নম্বর',
    'dateLocation': 'ডেটের স্থান',
    'duration': 'সময়কাল',
    'startCheckin': 'চেক-ইন শুরু করুন',
    'imSafe': 'আমি নিরাপদ',
    'sosAlert': 'SOS সতর্কতা',
    'checkinActive': 'চেক-ইন সক্রিয়',
    'timesUp': 'সময় শেষ!',
    'markedSafe': 'নিরাপদ চিহ্নিত! নিরাপদ থাকুন।',
    'sosAlertSent': 'আপনার বিশ্বস্ত ব্যক্তিকে SOS সতর্কতা পাঠানো হয়েছে!',

    // Kundli
    'kundliMatch': 'কুণ্ডলী মিলান',
    'kundliDescription': 'গুণ মিলান (অষ্টকূট) - হিন্দু বিবাহে ব্যবহৃত ঐতিহ্যবাহী ৩৬ পয়েন্ট বৈদিক সামঞ্জস্য পদ্ধতি।',
    'yourNakshatra': 'আপনার নক্ষত্র',
    'partnerNakshatra': 'সঙ্গীর নক্ষত্র',
    'yourRashi': 'আপনার রাশি (ঐচ্ছিক)',
    'partnerRashi': 'সঙ্গীর রাশি (ঐচ্ছিক)',
    'calculateCompatibility': 'সামঞ্জস্য গণনা করুন',
    'excellentMatch': 'চমৎকার ম্যাচ',
    'goodMatch': 'ভালো ম্যাচ',
    'averageMatch': 'গড় ম্যাচ',
    'belowAverage': 'গড়ের নিচে',
    'compatibility': 'সামঞ্জস্য',

    // Festivals
    'festivalEvents': 'উৎসব অনুষ্ঠান',
    'happeningNow': 'এখন হচ্ছে',
    'upcomingFestivals': 'আসন্ন উৎসব',
    'pastEvents': 'অতীত অনুষ্ঠান',
    'interested': 'আমি আগ্রহী',
    'youreGoing': 'আপনি যাচ্ছেন!',
    'activities': 'কার্যক্রম',

    // Entertainment
    'games': 'খেলা',
    'loveLanguageQuiz': 'লাভ ল্যাঙ্গুয়েজ কুইজ',
    'triviaGame': 'বলিউড ও ক্রিকেট ট্রিভিয়া',
    'thisOrThat': 'এটা না ওটা',
    'wouldYouRather': 'আপনি কী করবেন',
    'compatibilityGame': 'সামঞ্জস্য খেলা',
    'playAgain': 'আবার খেলুন',
    'score': 'স্কোর',
    'highScore': 'সর্বোচ্চ স্কোর',
    'yourResult': 'আপনার ফলাফল',
    'takeLoveLanguageQuiz': 'লাভ ল্যাঙ্গুয়েজ কুইজ নিন',

    // Endorsements
    'communityReviews': 'সম্প্রদায়ের মতামত',
    'endorse': 'সমর্থন করুন',
    'endorseThisPerson': 'এই ব্যক্তিকে সমর্থন করুন',
    'endorsementAnonymous': 'আপনার সমর্থন বেনামী এবং বিশ্বাস তৈরিতে সাহায্য করে।',
    'noEndorsementsYet': 'এখনো কোনো সমর্থন নেই। প্রথম হন!',

    // Family
    'shareWithFamily': 'পরিবারের সাথে শেয়ার করুন',

    // Gifts
    'giftShop': 'গিফট শপ',
    'sendGift': 'উপহার পাঠান',
    'myGifts': 'আমার উপহার',
    'leaderboard': 'লিডারবোর্ড',

    // Subscription
    'subscription': 'সাবস্ক্রিপশন',
    'free': 'বিনামূল্যে',
    'silver': 'সিলভার',
    'gold': 'গোল্ড',
    'upgradeToPremium': 'প্রিমিয়ামে আপগ্রেড করুন',
    'currentPlan': 'বর্তমান প্ল্যান',

    // Settings
    'language': 'ভাষা',
    'selectLanguage': 'ভাষা নির্বাচন করুন',
    'languageChanged': 'ভাষা সফলভাবে পরিবর্তিত হয়েছে!',
    'privacy': 'গোপনীয়তা',
    'safety': 'নিরাপত্তা',
    'notifications': 'বিজ্ঞপ্তি',
    'helpSupport': 'সাহায্য ও সহায়তা',
    'termsOfService': 'সেবার শর্তাবলী',
    'privacyPolicy': 'গোপনীয়তা নীতি',
    'communityGuidelines': 'সম্প্রদায়ের নির্দেশিকা',

    // Misc
    'fillAllFields': 'অনুগ্রহ করে সব ফিল্ড পূরণ করুন',
    'blockUser': 'ব্যবহারকারী ব্লক করুন',
    'blockUserConfirm': 'আপনি কি নিশ্চিত এই ব্যবহারকারীকে ব্লক করতে চান?',
    'userBlocked': 'ব্লক করা হয়েছে',
    'reportUser': 'ব্যবহারকারী রিপোর্ট করুন',
    'remaining': 'বাকি',
    'noResults': 'কোনো ফলাফল পাওয়া যায়নি',
    'seeAll': 'সব দেখুন',
  };

  // ============================================================
  // TAMIL TRANSLATIONS (தமிழ்)
  // ============================================================
  static const Map<String, String> _taTranslations = {
    // Common
    'appName': 'இந்திரா லவ்',
    'ok': 'சரி',
    'cancel': 'ரத்து',
    'save': 'சேமி',
    'delete': 'நீக்கு',
    'edit': 'திருத்து',
    'done': 'முடிந்தது',
    'next': 'அடுத்து',
    'back': 'பின்',
    'close': 'மூடு',
    'search': 'தேடு',
    'loading': 'ஏற்றுகிறது...',
    'error': 'பிழை',
    'success': 'வெற்றி',
    'retry': 'மீண்டும் முயற்சி',
    'yes': 'ஆம்',
    'no': 'இல்லை',
    'submit': 'சமர்ப்பி',
    'send': 'அனுப்பு',
    'share': 'பகிர்',
    'report': 'புகார்',
    'block': 'தடு',
    'menu': 'மெனு',
    'settings': 'அமைப்புகள்',
    'logout': 'வெளியேறு',

    // Auth
    'welcome': 'இந்திரா லவ்-க்கு வரவேற்கிறோம்',
    'welcomeSubtitle': 'உங்கள் சரியான துணையைக் கண்டறியுங்கள்',
    'login': 'உள்நுழை',
    'signup': 'பதிவு செய்',
    'email': 'மின்னஞ்சல்',
    'password': 'கடவுச்சொல்',
    'confirmPassword': 'கடவுச்சொல்லை உறுதிப்படுத்து',
    'forgotPassword': 'கடவுச்சொல் மறந்துவிட்டதா?',
    'createAccount': 'கணக்கை உருவாக்கு',
    'alreadyHaveAccount': 'ஏற்கனவே கணக்கு உள்ளதா?',
    'dontHaveAccount': 'கணக்கு இல்லையா?',
    'orContinueWith': 'அல்லது இதன் மூலம் தொடரவும்',
    'signInWithGoogle': 'Google மூலம் உள்நுழைக',
    'fullName': 'முழு பெயர்',
    'enterEmail': 'மின்னஞ்சலை உள்ளிடவும்',
    'enterPassword': 'கடவுச்சொல்லை உள்ளிடவும்',

    // Navigation
    'discover': 'கண்டறி',
    'likes': 'விருப்பங்கள்',
    'messages': 'செய்திகள்',
    'matches': 'பொருத்தங்கள்',
    'profile': 'சுயவிவரம்',
    'gifts': 'பரிசுகள்',
    'social': 'சமூகம்',
    'entertainment': 'பொழுதுபோக்கு',
    'premium': 'பிரீமியம்',
    'activity': 'செயல்பாடு',

    // Discover
    'discoverPeople': 'மக்களைக் கண்டறியுங்கள்',
    'noMoreProfiles': 'அருகில் மேலும் சுயவிவரங்கள் இல்லை',
    'itsAMatch': 'இது ஒரு பொருத்தம்!',
    'keepSwiping': 'ஸ்வைப் செய்யுங்கள்',
    'sendMessage': 'செய்தி அனுப்பு',
    'locationSettings': 'இருப்பிட அமைப்புகள்',
    'culturalFilters': 'கலாச்சார வடிகட்டிகள்',
    'boostProfile': 'சுயவிவரத்தை ஊக்குவி',

    // Profile
    'editProfile': 'சுயவிவரத்தைத் திருத்து',
    'about': 'பற்றி',
    'interests': 'ஆர்வங்கள்',
    'photos': 'புகைப்படங்கள்',
    'verified': 'சரிபார்க்கப்பட்டது',
    'getVerified': 'சரிபார்க்கவும்',
    'culturalLifestyle': 'கலாச்சாரம் & வாழ்க்கை முறை',
    'age': 'வயது',
    'bio': 'சுய அறிமுகம்',
    'religion': 'மதம்',
    'motherTongue': 'தாய்மொழி',
    'education': 'கல்வி',
    'profession': 'தொழில்',
    'diet': 'உணவு',
    'familyValues': 'குடும்ப மதிப்புகள்',
    'marriageTimeline': 'திருமண காலக்கெடு',
    'community': 'சமூகம்',
    'location': 'இடம்',
    'height': 'உயரம்',
    'manglik': 'மங்கலிக்',

    // Messaging
    'noMessagesYet': 'இன்னும் செய்திகள் இல்லை',
    'sayHi': 'வணக்கம் சொல்லுங்கள்!',
    'typeMessage': 'செய்தியை தட்டச்சு செய்யுங்கள்...',
    'suggestedIcebreakers': 'பரிந்துரைக்கப்பட்ட ஐஸ்பிரேக்கர்கள்',
    'conversations': 'உரையாடல்கள்',
    'noConversations': 'இன்னும் உரையாடல்கள் இல்லை',

    // Matches
    'yourMatches': 'உங்கள் பொருத்தங்கள்',
    'noMatches': 'இன்னும் பொருத்தங்கள் இல்லை',
    'recentMatches': 'சமீபத்திய பொருத்தங்கள்',
    'allMatches': 'அனைத்து பொருத்தங்கள்',
    'unmatch': 'பொருத்தத்தை நீக்கு',
    'unmatchConfirm': 'நிச்சயமாக பொருத்தத்தை நீக்க விரும்புகிறீர்களா?',

    // Likes
    'peopleWhoLikedYou': 'உங்களை விரும்பியவர்கள்',
    'superlikes': 'சூப்பர் லைக்',
    'noLikesYet': 'இன்னும் லைக் இல்லை',
    'sentLikes': 'அனுப்பிய லைக்கள்',

    // Video Calling
    'videoCall': 'வீடியோ அழைப்பு',
    'audioCall': 'ஆடியோ அழைப்பு',
    'incomingCall': 'வரும் அழைப்பு',
    'calling': 'அழைக்கிறது...',
    'answer': 'பதிலளி',
    'reject': 'நிராகரி',
    'callEnded': 'அழைப்பு முடிந்தது',
    'endCall': 'அழைப்பை முடி',

    // Safety
    'safetyCheckin': 'பாதுகாப்பு செக்-இன்',
    'safetyDescription': 'டேட்டிற்கு செல்கிறீர்களா? பாதுகாப்பு டைமர் அமைக்கவும். செக்-இன் செய்யாவிட்டால் உங்கள் நம்பிக்கையான தொடர்பாளருக்கு தெரிவிக்கப்படும்.',
    'trustedContactName': 'நம்பிக்கையான தொடர்பாளர் பெயர்',
    'theirPhoneNumber': 'அவர்களின் தொலைபேசி எண்',
    'dateLocation': 'டேட் இடம்',
    'duration': 'காலம்',
    'startCheckin': 'செக்-இன் தொடங்கு',
    'imSafe': 'நான் பாதுகாப்பாக இருக்கிறேன்',
    'sosAlert': 'SOS எச்சரிக்கை',
    'checkinActive': 'செக்-இன் செயலில்',
    'timesUp': 'நேரம் முடிந்தது!',
    'markedSafe': 'பாதுகாப்பானது என குறிக்கப்பட்டது! பாதுகாப்பாக இருங்கள்.',
    'sosAlertSent': 'உங்கள் நம்பிக்கையான தொடர்பாளருக்கு SOS எச்சரிக்கை அனுப்பப்பட்டது!',

    // Kundli
    'kundliMatch': 'குண்டலி பொருத்தம்',
    'kundliDescription': 'குண மிலான் (அஷ்டகூட) - இந்து திருமணத்தில் பயன்படுத்தப்படும் பாரம்பரிய 36 புள்ளி வேத பொருத்த முறை.',
    'yourNakshatra': 'உங்கள் நட்சத்திரம்',
    'partnerNakshatra': 'துணையின் நட்சத்திரம்',
    'yourRashi': 'உங்கள் ராசி (விரும்பினால்)',
    'partnerRashi': 'துணையின் ராசி (விரும்பினால்)',
    'calculateCompatibility': 'பொருத்தத்தைக் கணக்கிடு',
    'excellentMatch': 'சிறந்த பொருத்தம்',
    'goodMatch': 'நல்ல பொருத்தம்',
    'averageMatch': 'சராசரி பொருத்தம்',
    'belowAverage': 'சராசரிக்கு கீழ்',
    'compatibility': 'பொருத்தம்',

    // Festivals
    'festivalEvents': 'திருவிழா நிகழ்வுகள்',
    'happeningNow': 'இப்போது நடக்கிறது',
    'upcomingFestivals': 'வரவிருக்கும் திருவிழாக்கள்',
    'pastEvents': 'கடந்த நிகழ்வுகள்',
    'interested': 'ஆர்வமாக உள்ளேன்',
    'youreGoing': 'நீங்கள் செல்கிறீர்கள்!',
    'activities': 'செயல்பாடுகள்',

    // Entertainment
    'games': 'விளையாட்டுகள்',
    'loveLanguageQuiz': 'காதல் மொழி வினாடி வினா',
    'triviaGame': 'பாலிவுட் & கிரிக்கெட் வினாடி வினா',
    'thisOrThat': 'இது அல்லது அது',
    'wouldYouRather': 'நீங்கள் என்ன செய்வீர்கள்',
    'compatibilityGame': 'பொருத்த விளையாட்டு',
    'playAgain': 'மீண்டும் விளையாடு',
    'score': 'மதிப்பெண்',
    'highScore': 'அதிக மதிப்பெண்',
    'yourResult': 'உங்கள் முடிவு',
    'takeLoveLanguageQuiz': 'காதல் மொழி வினாடி வினா எடுங்கள்',

    // Endorsements
    'communityReviews': 'சமூக மதிப்பாய்வுகள்',
    'endorse': 'ஆதரவு',
    'endorseThisPerson': 'இந்த நபரை ஆதரிக்கவும்',
    'endorsementAnonymous': 'உங்கள் ஆதரவு அநாமதேயமானது மற்றும் நம்பிக்கையை உருவாக்க உதவுகிறது.',
    'noEndorsementsYet': 'இன்னும் ஆதரவு இல்லை. முதல் நபராக இருங்கள்!',

    // Family
    'shareWithFamily': 'குடும்பத்துடன் பகிர்',

    // Gifts
    'giftShop': 'பரிசு கடை',
    'sendGift': 'பரிசு அனுப்பு',
    'myGifts': 'என் பரிசுகள்',
    'leaderboard': 'தரவரிசை',

    // Subscription
    'subscription': 'சந்தா',
    'free': 'இலவசம்',
    'silver': 'சில்வர்',
    'gold': 'கோல்ட்',
    'upgradeToPremium': 'பிரீமியத்திற்கு மேம்படுத்து',
    'currentPlan': 'தற்போதைய திட்டம்',

    // Settings
    'language': 'மொழி',
    'selectLanguage': 'மொழி தேர்வு செய்யவும்',
    'languageChanged': 'மொழி வெற்றிகரமாக மாற்றப்பட்டது!',
    'privacy': 'தனியுரிமை',
    'safety': 'பாதுகாப்பு',
    'notifications': 'அறிவிப்புகள்',
    'helpSupport': 'உதவி & ஆதரவு',
    'termsOfService': 'சேவை விதிமுறைகள்',
    'privacyPolicy': 'தனியுரிமைக் கொள்கை',
    'communityGuidelines': 'சமூக வழிகாட்டுதல்கள்',

    // Misc
    'fillAllFields': 'அனைத்து புலங்களையும் நிரப்பவும்',
    'blockUser': 'பயனரைத் தடு',
    'blockUserConfirm': 'இந்த பயனரைத் தடுக்க விரும்புகிறீர்களா?',
    'userBlocked': 'தடுக்கப்பட்டது',
    'reportUser': 'பயனரைப் புகாரளி',
    'remaining': 'மீதம்',
    'noResults': 'முடிவுகள் இல்லை',
    'seeAll': 'அனைத்தும் பார்',
  };

  // ============================================================
  // URDU TRANSLATIONS (اردو)
  // ============================================================
  static const Map<String, String> _urTranslations = {
    // Common
    'appName': 'اندرا لو',
    'ok': 'ٹھیک ہے',
    'cancel': 'منسوخ',
    'save': 'محفوظ کریں',
    'delete': 'حذف کریں',
    'edit': 'ترمیم',
    'done': 'ہو گیا',
    'next': 'اگلا',
    'back': 'واپس',
    'close': 'بند کریں',
    'search': 'تلاش',
    'loading': 'لوڈ ہو رہا ہے...',
    'error': 'خرابی',
    'success': 'کامیاب',
    'retry': 'دوبارہ کوشش کریں',
    'yes': 'ہاں',
    'no': 'نہیں',
    'submit': 'جمع کریں',
    'send': 'بھیجیں',
    'share': 'شیئر کریں',
    'report': 'رپورٹ',
    'block': 'بلاک',
    'menu': 'مینو',
    'settings': 'ترتیبات',
    'logout': 'لاگ آؤٹ',

    // Auth
    'welcome': 'اندرا لو میں خوش آمدید',
    'welcomeSubtitle': 'اپنا بہترین ساتھی تلاش کریں',
    'login': 'لاگ ان',
    'signup': 'سائن اپ',
    'email': 'ای میل',
    'password': 'پاسورڈ',
    'confirmPassword': 'پاسورڈ کی تصدیق کریں',
    'forgotPassword': 'پاسورڈ بھول گئے؟',
    'createAccount': 'اکاؤنٹ بنائیں',
    'alreadyHaveAccount': 'پہلے سے اکاؤنٹ ہے؟',
    'dontHaveAccount': 'اکاؤنٹ نہیں ہے؟',
    'orContinueWith': 'یا اس کے ساتھ جاری رکھیں',
    'signInWithGoogle': 'Google سے سائن ان کریں',
    'fullName': 'پورا نام',
    'enterEmail': 'اپنا ای میل درج کریں',
    'enterPassword': 'اپنا پاسورڈ درج کریں',

    // Navigation
    'discover': 'دریافت',
    'likes': 'پسند',
    'messages': 'پیغامات',
    'matches': 'میچز',
    'profile': 'پروفائل',
    'gifts': 'تحائف',
    'social': 'سوشل',
    'entertainment': 'تفریح',
    'premium': 'پریمیم',
    'activity': 'سرگرمی',

    // Discover
    'discoverPeople': 'لوگوں کو دریافت کریں',
    'noMoreProfiles': 'قریب میں مزید پروفائلز نہیں',
    'itsAMatch': 'یہ ایک میچ ہے!',
    'keepSwiping': 'سوائپ کرتے رہیں',
    'sendMessage': 'پیغام بھیجیں',
    'locationSettings': 'مقام کی ترتیبات',
    'culturalFilters': 'ثقافتی فلٹرز',
    'boostProfile': 'پروفائل بوسٹ کریں',

    // Profile
    'editProfile': 'پروفائل میں ترمیم',
    'about': 'تعارف',
    'interests': 'دلچسپیاں',
    'photos': 'تصاویر',
    'verified': 'تصدیق شدہ',
    'getVerified': 'تصدیق کروائیں',
    'culturalLifestyle': 'ثقافت اور طرز زندگی',
    'age': 'عمر',
    'bio': 'تعارف',
    'religion': 'مذہب',
    'motherTongue': 'مادری زبان',
    'education': 'تعلیم',
    'profession': 'پیشہ',
    'diet': 'خوراک',
    'familyValues': 'خاندانی اقدار',
    'marriageTimeline': 'شادی کا وقت',
    'community': 'برادری',
    'location': 'مقام',
    'height': 'قد',
    'manglik': 'منگلک',

    // Messaging
    'noMessagesYet': 'ابھی تک کوئی پیغام نہیں',
    'sayHi': 'ہیلو کہیں!',
    'typeMessage': 'پیغام لکھیں...',
    'suggestedIcebreakers': 'تجویز کردہ آئس بریکرز',
    'conversations': 'بات چیت',
    'noConversations': 'ابھی تک کوئی بات چیت نہیں',

    // Matches
    'yourMatches': 'آپ کے میچز',
    'noMatches': 'ابھی تک کوئی میچ نہیں',
    'recentMatches': 'حالیہ میچز',
    'allMatches': 'تمام میچز',
    'unmatch': 'ان میچ',
    'unmatchConfirm': 'کیا آپ واقعی ان میچ کرنا چاہتے ہیں؟',

    // Likes
    'peopleWhoLikedYou': 'جنہوں نے آپ کو پسند کیا',
    'superlikes': 'سپر لائک',
    'noLikesYet': 'ابھی تک کوئی لائک نہیں',
    'sentLikes': 'بھیجے گئے لائکس',

    // Video Calling
    'videoCall': 'ویڈیو کال',
    'audioCall': 'آڈیو کال',
    'incomingCall': 'آنے والی کال',
    'calling': 'کال ہو رہی ہے...',
    'answer': 'جواب دیں',
    'reject': 'رد کریں',
    'callEnded': 'کال ختم ہو گئی',
    'endCall': 'کال ختم کریں',

    // Safety
    'safetyCheckin': 'حفاظتی چیک ان',
    'safetyDescription': 'ڈیٹ پر جا رہے ہیں؟ حفاظتی ٹائمر سیٹ کریں۔ اگر آپ وقت پر چیک ان نہیں کرتے تو آپ کے قابل اعتماد رابطے کو مطلع کیا جائے گا۔',
    'trustedContactName': 'قابل اعتماد رابطے کا نام',
    'theirPhoneNumber': 'ان کا فون نمبر',
    'dateLocation': 'ڈیٹ کا مقام',
    'duration': 'مدت',
    'startCheckin': 'چیک ان شروع کریں',
    'imSafe': 'میں محفوظ ہوں',
    'sosAlert': 'SOS الرٹ',
    'checkinActive': 'چیک ان فعال',
    'timesUp': 'وقت ختم!',
    'markedSafe': 'محفوظ نشان زد! محفوظ رہیں۔',
    'sosAlertSent': 'آپ کے قابل اعتماد رابطے کو SOS الرٹ بھیجا گیا!',

    // Kundli
    'kundliMatch': 'کنڈلی میچ',
    'kundliDescription': 'گن ملان (اشٹکوٹ) - ہندو شادی میں استعمال ہونے والا روایتی 36 پوائنٹ ویدک مطابقت کا نظام۔',
    'yourNakshatra': 'آپ کا نکشتر',
    'partnerNakshatra': 'ساتھی کا نکشتر',
    'yourRashi': 'آپ کی راشی (اختیاری)',
    'partnerRashi': 'ساتھی کی راشی (اختیاری)',
    'calculateCompatibility': 'مطابقت کا حساب لگائیں',
    'excellentMatch': 'بہترین میچ',
    'goodMatch': 'اچھا میچ',
    'averageMatch': 'اوسط میچ',
    'belowAverage': 'اوسط سے کم',
    'compatibility': 'مطابقت',

    // Festivals
    'festivalEvents': 'تہوار کے پروگرام',
    'happeningNow': 'ابھی ہو رہا ہے',
    'upcomingFestivals': 'آنے والے تہوار',
    'pastEvents': 'گزشتہ پروگرام',
    'interested': 'مجھے دلچسپی ہے',
    'youreGoing': 'آپ جا رہے ہیں!',
    'activities': 'سرگرمیاں',

    // Entertainment
    'games': 'کھیل',
    'loveLanguageQuiz': 'محبت کی زبان کوئز',
    'triviaGame': 'بالی ووڈ اور کرکٹ ٹریویا',
    'thisOrThat': 'یہ یا وہ',
    'wouldYouRather': 'آپ کیا کریں گے',
    'compatibilityGame': 'مطابقت کا کھیل',
    'playAgain': 'دوبارہ کھیلیں',
    'score': 'اسکور',
    'highScore': 'اعلی اسکور',
    'yourResult': 'آپ کا نتیجہ',
    'takeLoveLanguageQuiz': 'محبت کی زبان کوئز لیں',

    // Endorsements
    'communityReviews': 'کمیونٹی جائزے',
    'endorse': 'تائید',
    'endorseThisPerson': 'اس شخص کی تائید کریں',
    'endorsementAnonymous': 'آپ کی تائید گمنام ہے اور اعتماد بنانے میں مدد کرتی ہے۔',
    'noEndorsementsYet': 'ابھی تک کوئی تائید نہیں۔ پہلے بنیں!',

    // Family
    'shareWithFamily': 'خاندان کے ساتھ شیئر کریں',

    // Gifts
    'giftShop': 'تحفے کی دکان',
    'sendGift': 'تحفہ بھیجیں',
    'myGifts': 'میرے تحائف',
    'leaderboard': 'لیڈر بورڈ',

    // Subscription
    'subscription': 'سبسکرپشن',
    'free': 'مفت',
    'silver': 'سلور',
    'gold': 'گولڈ',
    'upgradeToPremium': 'پریمیم میں اپ گریڈ کریں',
    'currentPlan': 'موجودہ پلان',

    // Settings
    'language': 'زبان',
    'selectLanguage': 'زبان منتخب کریں',
    'languageChanged': 'زبان کامیابی سے تبدیل ہو گئی!',
    'privacy': 'رازداری',
    'safety': 'حفاظت',
    'notifications': 'اطلاعات',
    'helpSupport': 'مدد اور سپورٹ',
    'termsOfService': 'سروس کی شرائط',
    'privacyPolicy': 'رازداری کی پالیسی',
    'communityGuidelines': 'کمیونٹی گائیڈ لائنز',

    // Misc
    'fillAllFields': 'براہ کرم تمام فیلڈز بھریں',
    'blockUser': 'صارف کو بلاک کریں',
    'blockUserConfirm': 'کیا آپ واقعی اس صارف کو بلاک کرنا چاہتے ہیں؟',
    'userBlocked': 'بلاک کر دیا گیا ہے',
    'reportUser': 'صارف کی رپورٹ کریں',
    'remaining': 'باقی',
    'noResults': 'کوئی نتیجہ نہیں ملا',
    'seeAll': 'سب دیکھیں',
  };

  // ============================================================
  // TELUGU TRANSLATIONS (తెలుగు)
  // ============================================================
  static const Map<String, String> _teTranslations = {
    // Common
    'appName': 'ఇందిరా లవ్',
    'ok': 'సరే',
    'cancel': 'రద్దు',
    'save': 'సేవ్',
    'delete': 'తొలగించు',
    'edit': 'సవరించు',
    'done': 'పూర్తి',
    'next': 'తదుపరి',
    'back': 'వెనుకకు',
    'close': 'మూసివేయి',
    'search': 'వెతుకు',
    'loading': 'లోడ్ అవుతోంది...',
    'error': 'లోపం',
    'success': 'విజయం',
    'retry': 'మళ్ళీ ప్రయత్నించు',
    'yes': 'అవును',
    'no': 'కాదు',
    'submit': 'సమర్పించు',
    'send': 'పంపు',
    'share': 'షేర్ చేయి',
    'report': 'రిపోర్ట్',
    'block': 'బ్లాక్',
    'menu': 'మెనూ',
    'settings': 'సెట్టింగ్స్',
    'logout': 'లాగ్ అవుట్',

    // Auth
    'welcome': 'ఇందిరా లవ్‌కు స్వాగతం',
    'welcomeSubtitle': 'మీ సరైన జోడీని కనుగొనండి',
    'login': 'లాగిన్',
    'signup': 'సైన్ అప్',
    'email': 'ఇమెయిల్',
    'password': 'పాస్‌వర్డ్',
    'confirmPassword': 'పాస్‌వర్డ్ నిర్ధారించండి',
    'forgotPassword': 'పాస్‌వర్డ్ మర్చిపోయారా?',
    'createAccount': 'ఖాతా సృష్టించండి',
    'alreadyHaveAccount': 'ఇప్పటికే ఖాతా ఉందా?',
    'dontHaveAccount': 'ఖాతా లేదా?',
    'orContinueWith': 'లేదా దీనితో కొనసాగించండి',
    'signInWithGoogle': 'Google తో సైన్ ఇన్ చేయండి',
    'fullName': 'పూర్తి పేరు',
    'enterEmail': 'మీ ఇమెయిల్ నమోదు చేయండి',
    'enterPassword': 'మీ పాస్‌వర్డ్ నమోదు చేయండి',

    // Navigation
    'discover': 'కనుగొను',
    'likes': 'లైక్‌లు',
    'messages': 'సందేశాలు',
    'matches': 'మ్యాచ్‌లు',
    'profile': 'ప్రొఫైల్',
    'gifts': 'బహుమతులు',
    'social': 'సామాజికం',
    'entertainment': 'వినోదం',
    'premium': 'ప్రీమియం',
    'activity': 'కార్యకలాపం',

    // Discover
    'discoverPeople': 'వ్యక్తులను కనుగొనండి',
    'noMoreProfiles': 'సమీపంలో ఇక ప్రొఫైల్‌లు లేవు',
    'itsAMatch': 'ఇది మ్యాచ్!',
    'keepSwiping': 'స్వైప్ చేస్తూ ఉండండి',
    'sendMessage': 'సందేశం పంపండి',
    'locationSettings': 'లొకేషన్ సెట్టింగ్స్',
    'culturalFilters': 'సాంస్కృతిక ఫిల్టర్లు',
    'boostProfile': 'ప్రొఫైల్ బూస్ట్ చేయండి',

    // Profile
    'editProfile': 'ప్రొఫైల్ సవరించండి',
    'about': 'గురించి',
    'interests': 'ఆసక్తులు',
    'photos': 'ఫోటోలు',
    'verified': 'ధృవీకరించబడింది',
    'getVerified': 'ధృవీకరణ పొందండి',
    'culturalLifestyle': 'సాంస్కృతిక & జీవనశైలి',
    'age': 'వయస్సు',
    'bio': 'బయో',
    'religion': 'మతం',
    'motherTongue': 'మాతృభాష',
    'education': 'విద్య',
    'profession': 'వృత్తి',
    'diet': 'ఆహారం',
    'familyValues': 'కుటుంబ విలువలు',
    'marriageTimeline': 'వివాహ సమయ పట్టిక',
    'community': 'సమాజం',
    'location': 'ప్రాంతం',
    'height': 'ఎత్తు',
    'manglik': 'మాంగ్లిక్',

    // Messaging
    'noMessagesYet': 'ఇంకా సందేశాలు లేవు',
    'sayHi': 'హాయ్ చెప్పండి!',
    'typeMessage': 'సందేశం టైప్ చేయండి...',
    'suggestedIcebreakers': 'సూచించిన ఐస్‌బ్రేకర్లు',
    'conversations': 'సంభాషణలు',
    'noConversations': 'ఇంకా సంభాషణలు లేవు',

    // Matches
    'yourMatches': 'మీ మ్యాచ్‌లు',
    'noMatches': 'ఇంకా మ్యాచ్‌లు లేవు',
    'recentMatches': 'ఇటీవలి మ్యాచ్‌లు',
    'allMatches': 'అన్ని మ్యాచ్‌లు',
    'unmatch': 'అన్‌మ్యాచ్',
    'unmatchConfirm': 'మీరు ఖచ్చితంగా అన్‌మ్యాచ్ చేయాలనుకుంటున్నారా?',

    // Likes
    'peopleWhoLikedYou': 'మిమ్మల్ని లైక్ చేసిన వ్యక్తులు',
    'superlikes': 'సూపర్ లైక్‌లు',
    'noLikesYet': 'ఇంకా లైక్‌లు లేవు',
    'sentLikes': 'పంపిన లైక్‌లు',

    // Video Calling
    'videoCall': 'వీడియో కాల్',
    'audioCall': 'ఆడియో కాల్',
    'incomingCall': 'ఇన్‌కమింగ్ కాల్',
    'calling': 'కాల్ చేస్తోంది...',
    'answer': 'సమాధానం',
    'reject': 'తిరస్కరించు',
    'callEnded': 'కాల్ ముగిసింది',
    'endCall': 'కాల్ ముగించు',

    // Safety
    'safetyCheckin': 'సేఫ్టీ చెక్-ఇన్',
    'safetyDescription': 'డేట్‌కు వెళ్తున్నారా? సేఫ్టీ టైమర్ సెట్ చేయండి. మీరు సమయానికి చెక్ ఇన్ చేయకపోతే, మీ విశ్వసనీయ వ్యక్తికి అలర్ట్ పంపబడుతుంది.',
    'trustedContactName': 'విశ్వసనీయ వ్యక్తి పేరు',
    'theirPhoneNumber': 'వారి ఫోన్ నంబర్',
    'dateLocation': 'డేట్ ప్రాంతం',
    'duration': 'వ్యవధి',
    'startCheckin': 'చెక్-ఇన్ ప్రారంభించు',
    'imSafe': 'నేను సురక్షితంగా ఉన్నాను',
    'sosAlert': 'SOS అలర్ట్',
    'checkinActive': 'చెక్-ఇన్ యాక్టివ్',
    'timesUp': 'సమయం అయిపోయింది!',
    'markedSafe': 'సురక్షితంగా గుర్తించబడింది! జాగ్రత్తగా ఉండండి.',
    'sosAlertSent': 'మీ విశ్వసనీయ వ్యక్తికి SOS అలర్ట్ పంపబడింది!',

    // Kundli
    'kundliMatch': 'కుండలి మ్యాచ్',
    'kundliDescription': 'గుణ మిలన్ (అష్టకూట) - హిందూ వివాహ సంప్రదాయంలో ఉపయోగించే 36-పాయింట్ల వేద అనుకూలత వ్యవస్థ.',
    'yourNakshatra': 'మీ నక్షత్రం',
    'partnerNakshatra': 'భాగస్వామి నక్షత్రం',
    'yourRashi': 'మీ రాశి (ఐచ్ఛికం)',
    'partnerRashi': 'భాగస్వామి రాశి (ఐచ్ఛికం)',
    'calculateCompatibility': 'అనుకూలత లెక్కించండి',
    'excellentMatch': 'అద్భుతమైన మ్యాచ్',
    'goodMatch': 'మంచి మ్యాచ్',
    'averageMatch': 'సగటు మ్యాచ్',
    'belowAverage': 'సగటు కంటే తక్కువ',
    'compatibility': 'అనుకూలత',

    // Festivals
    'festivalEvents': 'పండుగ కార్యక్రమాలు',
    'happeningNow': 'ఇప్పుడు జరుగుతోంది',
    'upcomingFestivals': 'రాబోయే పండుగలు',
    'pastEvents': 'గత కార్యక్రమాలు',
    'interested': 'నాకు ఆసక్తి ఉంది',
    'youreGoing': 'మీరు వెళ్తున్నారు!',
    'activities': 'కార్యకలాపాలు',

    // Entertainment
    'games': 'గేమ్‌లు',
    'loveLanguageQuiz': 'ప్రేమ భాష క్విజ్',
    'triviaGame': 'బాలీవుడ్ & క్రికెట్ ట్రివియా',
    'thisOrThat': 'ఇది లేదా అది',
    'wouldYouRather': 'మీరు ఏది ఎంచుకుంటారు',
    'compatibilityGame': 'అనుకూలత గేమ్',
    'playAgain': 'మళ్ళీ ఆడండి',
    'score': 'స్కోర్',
    'highScore': 'హై స్కోర్',
    'yourResult': 'మీ ఫలితం',
    'takeLoveLanguageQuiz': 'ప్రేమ భాష క్విజ్ తీసుకోండి',

    // Endorsements
    'communityReviews': 'సమాజ సమీక్షలు',
    'endorse': 'ఎండార్స్ చేయండి',
    'endorseThisPerson': 'ఈ వ్యక్తిని ఎండార్స్ చేయండి',
    'endorsementAnonymous': 'మీ ఎండార్స్‌మెంట్ అజ్ఞాతం మరియు విశ్వాసాన్ని పెంచుతుంది.',
    'noEndorsementsYet': 'ఇంకా ఎండార్స్‌మెంట్లు లేవు. ఈ వ్యక్తి కోసం మొదటిగా హామీ ఇవ్వండి!',

    // Family
    'shareWithFamily': 'కుటుంబంతో షేర్ చేయండి',

    // Gifts
    'giftShop': 'గిఫ్ట్ షాప్',
    'sendGift': 'బహుమతి పంపండి',
    'myGifts': 'నా బహుమతులు',
    'leaderboard': 'లీడర్‌బోర్డ్',

    // Subscription
    'subscription': 'సబ్‌స్క్రిప్షన్',
    'free': 'ఉచితం',
    'silver': 'సిల్వర్',
    'gold': 'గోల్డ్',
    'upgradeToPremium': 'ప్రీమియంకు అప్‌గ్రేడ్ చేయండి',
    'currentPlan': 'ప్రస్తుత ప్లాన్',

    // Settings
    'language': 'భాష',
    'selectLanguage': 'భాషను ఎంచుకోండి',
    'languageChanged': 'భాష విజయవంతంగా మార్చబడింది!',
    'privacy': 'గోప్యత',
    'safety': 'భద్రత',
    'notifications': 'నోటిఫికేషన్లు',
    'helpSupport': 'సహాయం & మద్దతు',
    'termsOfService': 'సేవా నిబంధనలు',
    'privacyPolicy': 'గోప్యతా విధానం',
    'communityGuidelines': 'సమాజ మార్గదర్శకాలు',

    // Misc
    'fillAllFields': 'దయచేసి అన్ని ఫీల్డ్‌లు నింపండి',
    'blockUser': 'వినియోగదారుని బ్లాక్ చేయండి',
    'blockUserConfirm': 'మీరు ఖచ్చితంగా ఈ వినియోగదారుని బ్లాక్ చేయాలనుకుంటున్నారా? మీరు ఒకరినొకరు చూడలేరు.',
    'userBlocked': 'బ్లాక్ చేయబడింది',
    'reportUser': 'వినియోగదారుని రిపోర్ట్ చేయండి',
    'remaining': 'మిగిలి ఉంది',
    'noResults': 'ఫలితాలు కనుగొనబడలేదు',
    'seeAll': 'అన్నీ చూడండి',
  };

  // ============================================================
  // KANNADA TRANSLATIONS (ಕನ್ನಡ)
  // ============================================================
  static const Map<String, String> _knTranslations = {
    // Common
    'appName': 'ಇಂದಿರಾ ಲವ್',
    'ok': 'ಸರಿ',
    'cancel': 'ರದ್ದುಮಾಡು',
    'save': 'ಉಳಿಸು',
    'delete': 'ಅಳಿಸು',
    'edit': 'ತಿದ್ದು',
    'done': 'ಮುಗಿಯಿತು',
    'next': 'ಮುಂದೆ',
    'back': 'ಹಿಂದೆ',
    'close': 'ಮುಚ್ಚು',
    'search': 'ಹುಡುಕು',
    'loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
    'error': 'ದೋಷ',
    'success': 'ಯಶಸ್ಸು',
    'retry': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸು',
    'yes': 'ಹೌದು',
    'no': 'ಇಲ್ಲ',
    'submit': 'ಸಲ್ಲಿಸು',
    'send': 'ಕಳುಹಿಸು',
    'share': 'ಹಂಚು',
    'report': 'ವರದಿ',
    'block': 'ಬ್ಲಾಕ್',
    'menu': 'ಮೆನು',
    'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    'logout': 'ಲಾಗ್ ಔಟ್',

    // Auth
    'welcome': 'ಇಂದಿರಾ ಲವ್‌ಗೆ ಸ್ವಾಗತ',
    'welcomeSubtitle': 'ನಿಮ್ಮ ಸರಿಯಾದ ಜೋಡಿಯನ್ನು ಹುಡುಕಿ',
    'login': 'ಲಾಗಿನ್',
    'signup': 'ಸೈನ್ ಅಪ್',
    'email': 'ಇಮೇಲ್',
    'password': 'ಪಾಸ್‌ವರ್ಡ್',
    'confirmPassword': 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
    'forgotPassword': 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿದ್ದೀರಾ?',
    'createAccount': 'ಖಾತೆ ರಚಿಸಿ',
    'alreadyHaveAccount': 'ಈಗಾಗಲೇ ಖಾತೆ ಇದೆಯೇ?',
    'dontHaveAccount': 'ಖಾತೆ ಇಲ್ಲವೇ?',
    'orContinueWith': 'ಅಥವಾ ಇದರೊಂದಿಗೆ ಮುಂದುವರಿಸಿ',
    'signInWithGoogle': 'Google ಮೂಲಕ ಸೈನ್ ಇನ್ ಮಾಡಿ',
    'fullName': 'ಪೂರ್ಣ ಹೆಸರು',
    'enterEmail': 'ನಿಮ್ಮ ಇಮೇಲ್ ನಮೂದಿಸಿ',
    'enterPassword': 'ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ',

    // Navigation
    'discover': 'ಅನ್ವೇಷಿಸು',
    'likes': 'ಲೈಕ್‌ಗಳು',
    'messages': 'ಸಂದೇಶಗಳು',
    'matches': 'ಮ್ಯಾಚ್‌ಗಳು',
    'profile': 'ಪ್ರೊಫೈಲ್',
    'gifts': 'ಉಡುಗೊರೆಗಳು',
    'social': 'ಸಾಮಾಜಿಕ',
    'entertainment': 'ಮನರಂಜನೆ',
    'premium': 'ಪ್ರೀಮಿಯಂ',
    'activity': 'ಚಟುವಟಿಕೆ',

    // Discover
    'discoverPeople': 'ಜನರನ್ನು ಅನ್ವೇಷಿಸಿ',
    'noMoreProfiles': 'ಹತ್ತಿರದಲ್ಲಿ ಇನ್ನು ಪ್ರೊಫೈಲ್‌ಗಳಿಲ್ಲ',
    'itsAMatch': 'ಇದು ಮ್ಯಾಚ್!',
    'keepSwiping': 'ಸ್ವೈಪ್ ಮಾಡುತ್ತಿರಿ',
    'sendMessage': 'ಸಂದೇಶ ಕಳುಹಿಸಿ',
    'locationSettings': 'ಸ್ಥಳ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    'culturalFilters': 'ಸಾಂಸ್ಕೃತಿಕ ಫಿಲ್ಟರ್‌ಗಳು',
    'boostProfile': 'ಪ್ರೊಫೈಲ್ ಬೂಸ್ಟ್ ಮಾಡಿ',

    // Profile
    'editProfile': 'ಪ್ರೊಫೈಲ್ ತಿದ್ದಿ',
    'about': 'ಕುರಿತು',
    'interests': 'ಆಸಕ್ತಿಗಳು',
    'photos': 'ಫೋಟೋಗಳು',
    'verified': 'ಪರಿಶೀಲಿಸಲಾಗಿದೆ',
    'getVerified': 'ಪರಿಶೀಲನೆ ಪಡೆಯಿರಿ',
    'culturalLifestyle': 'ಸಾಂಸ್ಕೃತಿಕ & ಜೀವನಶೈಲಿ',
    'age': 'ವಯಸ್ಸು',
    'bio': 'ಬಯೋ',
    'religion': 'ಧರ್ಮ',
    'motherTongue': 'ಮಾತೃಭಾಷೆ',
    'education': 'ಶಿಕ್ಷಣ',
    'profession': 'ವೃತ್ತಿ',
    'diet': 'ಆಹಾರ',
    'familyValues': 'ಕುಟುಂಬ ಮೌಲ್ಯಗಳು',
    'marriageTimeline': 'ವಿವಾಹ ಸಮಯರೇಖೆ',
    'community': 'ಸಮುದಾಯ',
    'location': 'ಸ್ಥಳ',
    'height': 'ಎತ್ತರ',
    'manglik': 'ಮಾಂಗಲಿಕ',

    // Messaging
    'noMessagesYet': 'ಇನ್ನೂ ಸಂದೇಶಗಳಿಲ್ಲ',
    'sayHi': 'ಹಾಯ್ ಹೇಳಿ!',
    'typeMessage': 'ಸಂದೇಶ ಟೈಪ್ ಮಾಡಿ...',
    'suggestedIcebreakers': 'ಸೂಚಿಸಿದ ಐಸ್‌ಬ್ರೇಕರ್‌ಗಳು',
    'conversations': 'ಸಂಭಾಷಣೆಗಳು',
    'noConversations': 'ಇನ್ನೂ ಸಂಭಾಷಣೆಗಳಿಲ್ಲ',

    // Matches
    'yourMatches': 'ನಿಮ್ಮ ಮ್ಯಾಚ್‌ಗಳು',
    'noMatches': 'ಇನ್ನೂ ಮ್ಯಾಚ್‌ಗಳಿಲ್ಲ',
    'recentMatches': 'ಇತ್ತೀಚಿನ ಮ್ಯಾಚ್‌ಗಳು',
    'allMatches': 'ಎಲ್ಲಾ ಮ್ಯಾಚ್‌ಗಳು',
    'unmatch': 'ಅನ್‌ಮ್ಯಾಚ್',
    'unmatchConfirm': 'ನೀವು ಖಚಿತವಾಗಿ ಅನ್‌ಮ್ಯಾಚ್ ಮಾಡಲು ಬಯಸುತ್ತೀರಾ?',

    // Likes
    'peopleWhoLikedYou': 'ನಿಮ್ಮನ್ನು ಲೈಕ್ ಮಾಡಿದವರು',
    'superlikes': 'ಸೂಪರ್ ಲೈಕ್‌ಗಳು',
    'noLikesYet': 'ಇನ್ನೂ ಲೈಕ್‌ಗಳಿಲ್ಲ',
    'sentLikes': 'ಕಳುಹಿಸಿದ ಲೈಕ್‌ಗಳು',

    // Video Calling
    'videoCall': 'ವೀಡಿಯೊ ಕರೆ',
    'audioCall': 'ಆಡಿಯೊ ಕರೆ',
    'incomingCall': 'ಒಳಬರುವ ಕರೆ',
    'calling': 'ಕರೆ ಮಾಡುತ್ತಿದೆ...',
    'answer': 'ಉತ್ತರಿಸು',
    'reject': 'ತಿರಸ್ಕರಿಸು',
    'callEnded': 'ಕರೆ ಮುಗಿಯಿತು',
    'endCall': 'ಕರೆ ಮುಗಿಸು',

    // Safety
    'safetyCheckin': 'ಸೇಫ್ಟಿ ಚೆಕ್-ಇನ್',
    'safetyDescription': 'ಡೇಟ್‌ಗೆ ಹೋಗುತ್ತಿದ್ದೀರಾ? ಸೇಫ್ಟಿ ಟೈಮರ್ ಸೆಟ್ ಮಾಡಿ. ನೀವು ಸಮಯಕ್ಕೆ ಚೆಕ್ ಇನ್ ಮಾಡದಿದ್ದರೆ, ನಿಮ್ಮ ನಂಬಿಕಸ್ಥ ವ್ಯಕ್ತಿಗೆ ಅಲರ್ಟ್ ಕಳುಹಿಸಲಾಗುತ್ತದೆ.',
    'trustedContactName': 'ನಂಬಿಕಸ್ಥ ವ್ಯಕ್ತಿಯ ಹೆಸರು',
    'theirPhoneNumber': 'ಅವರ ಫೋನ್ ನಂಬರ್',
    'dateLocation': 'ಡೇಟ್ ಸ್ಥಳ',
    'duration': 'ಅವಧಿ',
    'startCheckin': 'ಚೆಕ್-ಇನ್ ಪ್ರಾರಂಭಿಸು',
    'imSafe': 'ನಾನು ಸುರಕ್ಷಿತ',
    'sosAlert': 'SOS ಅಲರ್ಟ್',
    'checkinActive': 'ಚೆಕ್-ಇನ್ ಸಕ್ರಿಯ',
    'timesUp': 'ಸಮಯ ಮುಗಿಯಿತು!',
    'markedSafe': 'ಸುರಕ್ಷಿತ ಎಂದು ಗುರುತಿಸಲಾಗಿದೆ! ಜಾಗರೂಕರಾಗಿರಿ.',
    'sosAlertSent': 'ನಿಮ್ಮ ನಂಬಿಕಸ್ಥ ವ್ಯಕ್ತಿಗೆ SOS ಅಲರ್ಟ್ ಕಳುಹಿಸಲಾಗಿದೆ!',

    // Kundli
    'kundliMatch': 'ಕುಂಡಲಿ ಮ್ಯಾಚ್',
    'kundliDescription': 'ಗುಣ ಮಿಲನ (ಅಷ್ಟಕೂಟ) - ಹಿಂದೂ ವಿವಾಹ ಸಂಪ್ರದಾಯದಲ್ಲಿ ಬಳಸುವ 36-ಅಂಕಗಳ ವೈದಿಕ ಹೊಂದಾಣಿಕೆ ವ್ಯವಸ್ಥೆ.',
    'yourNakshatra': 'ನಿಮ್ಮ ನಕ್ಷತ್ರ',
    'partnerNakshatra': 'ಸಂಗಾತಿಯ ನಕ್ಷತ್ರ',
    'yourRashi': 'ನಿಮ್ಮ ರಾಶಿ (ಐಚ್ಛಿಕ)',
    'partnerRashi': 'ಸಂಗಾತಿಯ ರಾಶಿ (ಐಚ್ಛಿಕ)',
    'calculateCompatibility': 'ಹೊಂದಾಣಿಕೆ ಲೆಕ್ಕ ಹಾಕಿ',
    'excellentMatch': 'ಅತ್ಯುತ್ತಮ ಮ್ಯಾಚ್',
    'goodMatch': 'ಒಳ್ಳೆಯ ಮ್ಯಾಚ್',
    'averageMatch': 'ಸರಾಸರಿ ಮ್ಯಾಚ್',
    'belowAverage': 'ಸರಾಸರಿಗಿಂತ ಕಡಿಮೆ',
    'compatibility': 'ಹೊಂದಾಣಿಕೆ',

    // Festivals
    'festivalEvents': 'ಹಬ್ಬ ಕಾರ್ಯಕ್ರಮಗಳು',
    'happeningNow': 'ಈಗ ನಡೆಯುತ್ತಿದೆ',
    'upcomingFestivals': 'ಮುಂಬರುವ ಹಬ್ಬಗಳು',
    'pastEvents': 'ಹಿಂದಿನ ಕಾರ್ಯಕ್ರಮಗಳು',
    'interested': 'ನನಗೆ ಆಸಕ್ತಿ ಇದೆ',
    'youreGoing': 'ನೀವು ಹೋಗುತ್ತಿದ್ದೀರಿ!',
    'activities': 'ಚಟುವಟಿಕೆಗಳು',

    // Entertainment
    'games': 'ಆಟಗಳು',
    'loveLanguageQuiz': 'ಪ್ರೀತಿ ಭಾಷೆ ಕ್ವಿಜ್',
    'triviaGame': 'ಬಾಲಿವುಡ್ & ಕ್ರಿಕೆಟ್ ಟ್ರಿವಿಯಾ',
    'thisOrThat': 'ಇದು ಅಥವಾ ಅದು',
    'wouldYouRather': 'ನೀವು ಯಾವುದನ್ನು ಆಯ್ಕೆ ಮಾಡುತ್ತೀರಿ',
    'compatibilityGame': 'ಹೊಂದಾಣಿಕೆ ಆಟ',
    'playAgain': 'ಮತ್ತೆ ಆಡಿ',
    'score': 'ಸ್ಕೋರ್',
    'highScore': 'ಹೈ ಸ್ಕೋರ್',
    'yourResult': 'ನಿಮ್ಮ ಫಲಿತಾಂಶ',
    'takeLoveLanguageQuiz': 'ಪ್ರೀತಿ ಭಾಷೆ ಕ್ವಿಜ್ ತೆಗೆದುಕೊಳ್ಳಿ',

    // Endorsements
    'communityReviews': 'ಸಮುದಾಯ ವಿಮರ್ಶೆಗಳು',
    'endorse': 'ಎಂಡಾರ್ಸ್ ಮಾಡಿ',
    'endorseThisPerson': 'ಈ ವ್ಯಕ್ತಿಯನ್ನು ಎಂಡಾರ್ಸ್ ಮಾಡಿ',
    'endorsementAnonymous': 'ನಿಮ್ಮ ಎಂಡಾರ್ಸ್‌ಮೆಂಟ್ ಅನಾಮಧೇಯ ಮತ್ತು ನಂಬಿಕೆ ಬೆಳೆಸಲು ಸಹಾಯ ಮಾಡುತ್ತದೆ.',
    'noEndorsementsYet': 'ಇನ್ನೂ ಎಂಡಾರ್ಸ್‌ಮೆಂಟ್‌ಗಳಿಲ್ಲ. ಈ ವ್ಯಕ್ತಿಗೆ ಮೊದಲು ಹೊಣೆಗಾರರಾಗಿರಿ!',

    // Family
    'shareWithFamily': 'ಕುಟುಂಬದೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಿ',

    // Gifts
    'giftShop': 'ಗಿಫ್ಟ್ ಶಾಪ್',
    'sendGift': 'ಉಡುಗೊರೆ ಕಳುಹಿಸಿ',
    'myGifts': 'ನನ್ನ ಉಡುಗೊರೆಗಳು',
    'leaderboard': 'ಲೀಡರ್‌ಬೋರ್ಡ್',

    // Subscription
    'subscription': 'ಸಬ್‌ಸ್ಕ್ರಿಪ್ಷನ್',
    'free': 'ಉಚಿತ',
    'silver': 'ಸಿಲ್ವರ್',
    'gold': 'ಗೋಲ್ಡ್',
    'upgradeToPremium': 'ಪ್ರೀಮಿಯಂಗೆ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ',
    'currentPlan': 'ಪ್ರಸ್ತುತ ಪ್ಲಾನ್',

    // Settings
    'language': 'ಭಾಷೆ',
    'selectLanguage': 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
    'languageChanged': 'ಭಾಷೆ ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ!',
    'privacy': 'ಗೌಪ್ಯತೆ',
    'safety': 'ಸುರಕ್ಷತೆ',
    'notifications': 'ಅಧಿಸೂಚನೆಗಳು',
    'helpSupport': 'ಸಹಾಯ & ಬೆಂಬಲ',
    'termsOfService': 'ಸೇವಾ ನಿಯಮಗಳು',
    'privacyPolicy': 'ಗೌಪ್ಯತಾ ನೀತಿ',
    'communityGuidelines': 'ಸಮುದಾಯ ಮಾರ್ಗಸೂಚಿಗಳು',

    // Misc
    'fillAllFields': 'ದಯವಿಟ್ಟು ಎಲ್ಲಾ ಕ್ಷೇತ್ರಗಳನ್ನು ಭರ್ತಿ ಮಾಡಿ',
    'blockUser': 'ಬಳಕೆದಾರರನ್ನು ಬ್ಲಾಕ್ ಮಾಡಿ',
    'blockUserConfirm': 'ನೀವು ಖಚಿತವಾಗಿ ಈ ಬಳಕೆದಾರರನ್ನು ಬ್ಲಾಕ್ ಮಾಡಲು ಬಯಸುತ್ತೀರಾ? ನೀವು ಪರಸ್ಪರ ನೋಡಲು ಸಾಧ್ಯವಿಲ್ಲ.',
    'userBlocked': 'ಬ್ಲಾಕ್ ಮಾಡಲಾಗಿದೆ',
    'reportUser': 'ಬಳಕೆದಾರರನ್ನು ವರದಿ ಮಾಡಿ',
    'remaining': 'ಉಳಿದಿದೆ',
    'noResults': 'ಫಲಿತಾಂಶಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
    'seeAll': 'ಎಲ್ಲಾ ನೋಡಿ',
  };

  // ============================================================
  // MALAYALAM TRANSLATIONS (മലയാളം)
  // ============================================================
  static const Map<String, String> _mlTranslations = {
    // Common
    'appName': 'ഇന്ദിരാ ലവ്',
    'ok': 'ശരി',
    'cancel': 'റദ്ദാക്കുക',
    'save': 'സേവ് ചെയ്യുക',
    'delete': 'ഇല്ലാതാക്കുക',
    'edit': 'തിരുത്തുക',
    'done': 'പൂര്‍ത്തിയായി',
    'next': 'അടുത്തത്',
    'back': 'പിന്നിലേക്ക്',
    'close': 'അടയ്ക്കുക',
    'search': 'തിരയുക',
    'loading': 'ലോഡ് ചെയ്യുന്നു...',
    'error': 'പിശക്',
    'success': 'വിജയം',
    'retry': 'വീണ്ടും ശ്രമിക്കുക',
    'yes': 'അതെ',
    'no': 'ഇല്ല',
    'submit': 'സമര്‍പ്പിക്കുക',
    'send': 'അയയ്ക്കുക',
    'share': 'പങ്കിടുക',
    'report': 'റിപ്പോര്‍ട്ട്',
    'block': 'ബ്ലോക്ക്',
    'menu': 'മെനു',
    'settings': 'ക്രമീകരണങ്ങള്‍',
    'logout': 'ലോഗ് ഔട്ട്',

    // Auth
    'welcome': 'ഇന്ദിരാ ലവിലേക്ക് സ്വാഗതം',
    'welcomeSubtitle': 'നിങ്ങളുടെ അനുയോജ്യ ജോഡിയെ കണ്ടെത്തുക',
    'login': 'ലോഗിന്‍',
    'signup': 'സൈന്‍ അപ്പ്',
    'email': 'ഇമെയില്‍',
    'password': 'പാസ്‌വേഡ്',
    'confirmPassword': 'പാസ്‌വേഡ് സ്ഥിരീകരിക്കുക',
    'forgotPassword': 'പാസ്‌വേഡ് മറന്നോ?',
    'createAccount': 'അക്കൗണ്ട് സൃഷ്ടിക്കുക',
    'alreadyHaveAccount': 'ഇതിനകം ഒരു അക്കൗണ്ട് ഉണ്ടോ?',
    'dontHaveAccount': 'അക്കൗണ്ട് ഇല്ലേ?',
    'orContinueWith': 'അല്ലെങ്കില്‍ ഇതുപയോഗിച്ച് തുടരുക',
    'signInWithGoogle': 'Google ഉപയോഗിച്ച് സൈന്‍ ഇന്‍ ചെയ്യുക',
    'fullName': 'പൂര്‍ണ്ണ നാമം',
    'enterEmail': 'നിങ്ങളുടെ ഇമെയില്‍ നല്‍കുക',
    'enterPassword': 'നിങ്ങളുടെ പാസ്‌വേഡ് നല്‍കുക',

    // Navigation
    'discover': 'കണ്ടെത്തുക',
    'likes': 'ലൈക്കുകള്‍',
    'messages': 'സന്ദേശങ്ങള്‍',
    'matches': 'മാച്ചുകള്‍',
    'profile': 'പ്രൊഫൈല്‍',
    'gifts': 'സമ്മാനങ്ങള്‍',
    'social': 'സാമൂഹികം',
    'entertainment': 'വിനോദം',
    'premium': 'പ്രീമിയം',
    'activity': 'പ്രവര്‍ത്തനം',

    // Discover
    'discoverPeople': 'ആളുകളെ കണ്ടെത്തുക',
    'noMoreProfiles': 'സമീപത്ത് കൂടുതല്‍ പ്രൊഫൈലുകള്‍ ഇല്ല',
    'itsAMatch': 'ഇത് ഒരു മാച്ച്!',
    'keepSwiping': 'സ്വൈപ്പ് ചെയ്തുകൊണ്ടിരിക്കുക',
    'sendMessage': 'സന്ദേശം അയയ്ക്കുക',
    'locationSettings': 'ലൊക്കേഷന്‍ ക്രമീകരണങ്ങള്‍',
    'culturalFilters': 'സാംസ്‌കാരിക ഫില്‍ട്ടറുകള്‍',
    'boostProfile': 'പ്രൊഫൈല്‍ ബൂസ്റ്റ് ചെയ്യുക',

    // Profile
    'editProfile': 'പ്രൊഫൈല്‍ തിരുത്തുക',
    'about': 'കുറിച്ച്',
    'interests': 'താല്‍പ്പര്യങ്ങള്‍',
    'photos': 'ഫോട്ടോകള്‍',
    'verified': 'സ്ഥിരീകരിച്ചു',
    'getVerified': 'സ്ഥിരീകരണം നേടുക',
    'culturalLifestyle': 'സാംസ്‌കാരിക & ജീവിതശൈലി',
    'age': 'പ്രായം',
    'bio': 'ബയോ',
    'religion': 'മതം',
    'motherTongue': 'മാതൃഭാഷ',
    'education': 'വിദ്യാഭ്യാസം',
    'profession': 'തൊഴില്‍',
    'diet': 'ഭക്ഷണക്രമം',
    'familyValues': 'കുടുംബ മൂല്യങ്ങള്‍',
    'marriageTimeline': 'വിവാഹ സമയക്രമം',
    'community': 'സമൂഹം',
    'location': 'ലൊക്കേഷന്‍',
    'height': 'ഉയരം',
    'manglik': 'മാംഗ്ലിക്',

    // Messaging
    'noMessagesYet': 'ഇതുവരെ സന്ദേശങ്ങളില്ല',
    'sayHi': 'ഹായ് പറയൂ!',
    'typeMessage': 'ഒരു സന്ദേശം ടൈപ്പ് ചെയ്യുക...',
    'suggestedIcebreakers': 'നിര്‍ദ്ദേശിച്ച ഐസ്‌ബ്രേക്കറുകള്‍',
    'conversations': 'സംഭാഷണങ്ങള്‍',
    'noConversations': 'ഇതുവരെ സംഭാഷണങ്ങളില്ല',

    // Matches
    'yourMatches': 'നിങ്ങളുടെ മാച്ചുകള്‍',
    'noMatches': 'ഇതുവരെ മാച്ചുകളില്ല',
    'recentMatches': 'സമീപകാല മാച്ചുകള്‍',
    'allMatches': 'എല്ലാ മാച്ചുകളും',
    'unmatch': 'അണ്‍മാച്ച്',
    'unmatchConfirm': 'നിങ്ങള്‍ക്ക് ഉറപ്പാണോ അണ്‍മാച്ച് ചെയ്യാന്‍?',

    // Likes
    'peopleWhoLikedYou': 'നിങ്ങളെ ലൈക്ക് ചെയ്തവര്‍',
    'superlikes': 'സൂപ്പര്‍ ലൈക്കുകള്‍',
    'noLikesYet': 'ഇതുവരെ ലൈക്കുകളില്ല',
    'sentLikes': 'അയച്ച ലൈക്കുകള്‍',

    // Video Calling
    'videoCall': 'വീഡിയോ കോള്‍',
    'audioCall': 'ഓഡിയോ കോള്‍',
    'incomingCall': 'ഇന്‍കമിംഗ് കോള്‍',
    'calling': 'വിളിക്കുന്നു...',
    'answer': 'ഉത്തരം',
    'reject': 'നിരസിക്കുക',
    'callEnded': 'കോള്‍ അവസാനിച്ചു',
    'endCall': 'കോള്‍ അവസാനിപ്പിക്കുക',

    // Safety
    'safetyCheckin': 'സേഫ്റ്റി ചെക്ക്-ഇന്‍',
    'safetyDescription': 'ഡേറ്റിന് പോകുന്നുണ്ടോ? സേഫ്റ്റി ടൈമര്‍ സെറ്റ് ചെയ്യുക. നിങ്ങള്‍ സമയത്തിന് ചെക്ക് ഇന്‍ ചെയ്തില്ലെങ്കില്‍, നിങ്ങളുടെ വിശ്വസ്ത വ്യക്തിയെ അറിയിക്കും.',
    'trustedContactName': 'വിശ്വസ്ത വ്യക്തിയുടെ പേര്',
    'theirPhoneNumber': 'അവരുടെ ഫോണ്‍ നമ്പര്‍',
    'dateLocation': 'ഡേറ്റ് സ്ഥലം',
    'duration': 'ദൈര്‍ഘ്യം',
    'startCheckin': 'ചെക്ക്-ഇന്‍ ആരംഭിക്കുക',
    'imSafe': 'ഞാന്‍ സുരക്ഷിതമാണ്',
    'sosAlert': 'SOS അലര്‍ട്ട്',
    'checkinActive': 'ചെക്ക്-ഇന്‍ സജീവം',
    'timesUp': 'സമയം കഴിഞ്ഞു!',
    'markedSafe': 'സുരക്ഷിതമായി അടയാളപ്പെടുത്തി! സുരക്ഷിതരായിരിക്കുക.',
    'sosAlertSent': 'നിങ്ങളുടെ വിശ്വസ്ത വ്യക്തിക്ക് SOS അലര്‍ട്ട് അയച്ചു!',

    // Kundli
    'kundliMatch': 'കുണ്ഡലി മാച്ച്',
    'kundliDescription': 'ഗുണ മിലന്‍ (അഷ്ടകൂട) - ഹിന്ദു വിവാഹ സമ്പ്രദായത്തില്‍ ഉപയോഗിക്കുന്ന 36-പോയിന്‍റ് വൈദിക അനുയോജ്യതാ സംവിധാനം.',
    'yourNakshatra': 'നിങ്ങളുടെ നക്ഷത്രം',
    'partnerNakshatra': 'പങ്കാളിയുടെ നക്ഷത്രം',
    'yourRashi': 'നിങ്ങളുടെ രാശി (ഓപ്ഷണല്‍)',
    'partnerRashi': 'പങ്കാളിയുടെ രാശി (ഓപ്ഷണല്‍)',
    'calculateCompatibility': 'അനുയോജ്യത കണക്കാക്കുക',
    'excellentMatch': 'മികച്ച മാച്ച്',
    'goodMatch': 'നല്ല മാച്ച്',
    'averageMatch': 'ശരാശരി മാച്ച്',
    'belowAverage': 'ശരാശരിയില്‍ താഴെ',
    'compatibility': 'അനുയോജ്യത',

    // Festivals
    'festivalEvents': 'ഉത്സവ പരിപാടികള്‍',
    'happeningNow': 'ഇപ്പോള്‍ നടക്കുന്നു',
    'upcomingFestivals': 'വരാനിരിക്കുന്ന ഉത്സവങ്ങള്‍',
    'pastEvents': 'കഴിഞ്ഞ പരിപാടികള്‍',
    'interested': 'എനിക്ക് താല്‍പ്പര്യമുണ്ട്',
    'youreGoing': 'നിങ്ങള്‍ പോകുന്നു!',
    'activities': 'പ്രവര്‍ത്തനങ്ങള്‍',

    // Entertainment
    'games': 'ഗെയിമുകള്‍',
    'loveLanguageQuiz': 'പ്രണയ ഭാഷ ക്വിസ്',
    'triviaGame': 'ബോളിവുഡ് & ക്രിക്കറ്റ് ട്രിവിയ',
    'thisOrThat': 'ഇത് അല്ലെങ്കില്‍ അത്',
    'wouldYouRather': 'നിങ്ങള്‍ ഏത് തിരഞ്ഞെടുക്കും',
    'compatibilityGame': 'അനുയോജ്യതാ ഗെയിം',
    'playAgain': 'വീണ്ടും കളിക്കുക',
    'score': 'സ്‌കോര്‍',
    'highScore': 'ഹൈ സ്‌കോര്‍',
    'yourResult': 'നിങ്ങളുടെ ഫലം',
    'takeLoveLanguageQuiz': 'പ്രണയ ഭാഷ ക്വിസ് എടുക്കുക',

    // Endorsements
    'communityReviews': 'സമൂഹ അവലോകനങ്ങള്‍',
    'endorse': 'എന്‍ഡോഴ്‌സ് ചെയ്യുക',
    'endorseThisPerson': 'ഈ വ്യക്തിയെ എന്‍ഡോഴ്‌സ് ചെയ്യുക',
    'endorsementAnonymous': 'നിങ്ങളുടെ എന്‍ഡോഴ്‌സ്‌മെന്‍റ് അജ്ഞാതമാണ്, വിശ്വാസം വളര്‍ത്താന്‍ സഹായിക്കുന്നു.',
    'noEndorsementsYet': 'ഇതുവരെ എന്‍ഡോഴ്‌സ്‌മെന്‍റുകളില്ല. ഈ വ്യക്തിക്ക് ആദ്യം ജാമ്യം നില്‍ക്കൂ!',

    // Family
    'shareWithFamily': 'കുടുംബവുമായി പങ്കിടുക',

    // Gifts
    'giftShop': 'ഗിഫ്റ്റ് ഷോപ്പ്',
    'sendGift': 'സമ്മാനം അയയ്ക്കുക',
    'myGifts': 'എന്‍റെ സമ്മാനങ്ങള്‍',
    'leaderboard': 'ലീഡര്‍ബോര്‍ഡ്',

    // Subscription
    'subscription': 'സബ്‌സ്‌ക്രിപ്ഷന്‍',
    'free': 'സൗജന്യം',
    'silver': 'സില്‍വര്‍',
    'gold': 'ഗോള്‍ഡ്',
    'upgradeToPremium': 'പ്രീമിയത്തിലേക്ക് അപ്‌ഗ്രേഡ് ചെയ്യുക',
    'currentPlan': 'നിലവിലെ പ്ലാന്‍',

    // Settings
    'language': 'ഭാഷ',
    'selectLanguage': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
    'languageChanged': 'ഭാഷ വിജയകരമായി മാറ്റി!',
    'privacy': 'സ്വകാര്യത',
    'safety': 'സുരക്ഷ',
    'notifications': 'അറിയിപ്പുകള്‍',
    'helpSupport': 'സഹായവും പിന്തുണയും',
    'termsOfService': 'സേവന നിബന്ധനകള്‍',
    'privacyPolicy': 'സ്വകാര്യതാ നയം',
    'communityGuidelines': 'സമൂഹ മാര്‍ഗ്ഗനിര്‍ദ്ദേശങ്ങള്‍',

    // Misc
    'fillAllFields': 'ദയവായി എല്ലാ ഫീല്‍ഡുകളും പൂരിപ്പിക്കുക',
    'blockUser': 'ഉപയോക്താവിനെ ബ്ലോക്ക് ചെയ്യുക',
    'blockUserConfirm': 'ഈ ഉപയോക്താവിനെ ബ്ലോക്ക് ചെയ്യണമെന്ന് ഉറപ്പാണോ? നിങ്ങള്‍ പരസ്പരം കാണില്ല.',
    'userBlocked': 'ബ്ലോക്ക് ചെയ്തു',
    'reportUser': 'ഉപയോക്താവിനെ റിപ്പോര്‍ട്ട് ചെയ്യുക',
    'remaining': 'ശേഷിക്കുന്നു',
    'noResults': 'ഫലങ്ങളൊന്നും കണ്ടെത്തിയില്ല',
    'seeAll': 'എല്ലാം കാണുക',
  };

  // ============================================================
  // MARATHI TRANSLATIONS (मराठी)
  // ============================================================
  static const Map<String, String> _mrTranslations = {
    // Common
    'appName': 'इंदिरा लव्ह',
    'ok': 'ठीक आहे',
    'cancel': 'रद्द करा',
    'save': 'जतन करा',
    'delete': 'हटवा',
    'edit': 'संपादित करा',
    'done': 'पूर्ण',
    'next': 'पुढे',
    'back': 'मागे',
    'close': 'बंद करा',
    'search': 'शोधा',
    'loading': 'लोड होत आहे...',
    'error': 'त्रुटी',
    'success': 'यश',
    'retry': 'पुन्हा प्रयत्न करा',
    'yes': 'होय',
    'no': 'नाही',
    'submit': 'सबमिट करा',
    'send': 'पाठवा',
    'share': 'शेअर करा',
    'report': 'रिपोर्ट',
    'block': 'ब्लॉक',
    'menu': 'मेनू',
    'settings': 'सेटिंग्ज',
    'logout': 'लॉग आउट',

    // Auth
    'welcome': 'इंदिरा लव्हमध्ये स्वागत आहे',
    'welcomeSubtitle': 'तुमचा योग्य जोडीदार शोधा',
    'login': 'लॉगिन',
    'signup': 'साइन अप',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'confirmPassword': 'पासवर्ड पुष्टी करा',
    'forgotPassword': 'पासवर्ड विसरलात?',
    'createAccount': 'खाते तयार करा',
    'alreadyHaveAccount': 'आधीच खाते आहे?',
    'dontHaveAccount': 'खाते नाही?',
    'orContinueWith': 'किंवा यासह सुरू ठेवा',
    'signInWithGoogle': 'Google सह साइन इन करा',
    'fullName': 'पूर्ण नाव',
    'enterEmail': 'तुमचा ईमेल प्रविष्ट करा',
    'enterPassword': 'तुमचा पासवर्ड प्रविष्ट करा',

    // Navigation
    'discover': 'शोधा',
    'likes': 'लाईक्स',
    'messages': 'संदेश',
    'matches': 'मॅचेस',
    'profile': 'प्रोफाइल',
    'gifts': 'भेटवस्तू',
    'social': 'सामाजिक',
    'entertainment': 'मनोरंजन',
    'premium': 'प्रीमियम',
    'activity': 'कार्यकलाप',

    // Discover
    'discoverPeople': 'लोक शोधा',
    'noMoreProfiles': 'जवळपास आणखी प्रोफाइल नाहीत',
    'itsAMatch': 'हे मॅच आहे!',
    'keepSwiping': 'स्वाइप करत राहा',
    'sendMessage': 'संदेश पाठवा',
    'locationSettings': 'स्थान सेटिंग्ज',
    'culturalFilters': 'सांस्कृतिक फिल्टर्स',
    'boostProfile': 'प्रोफाइल बूस्ट करा',

    // Profile
    'editProfile': 'प्रोफाइल संपादित करा',
    'about': 'बद्दल',
    'interests': 'आवडी',
    'photos': 'फोटो',
    'verified': 'सत्यापित',
    'getVerified': 'सत्यापन मिळवा',
    'culturalLifestyle': 'सांस्कृतिक & जीवनशैली',
    'age': 'वय',
    'bio': 'बायो',
    'religion': 'धर्म',
    'motherTongue': 'मातृभाषा',
    'education': 'शिक्षण',
    'profession': 'व्यवसाय',
    'diet': 'आहार',
    'familyValues': 'कौटुंबिक मूल्ये',
    'marriageTimeline': 'विवाह वेळापत्रक',
    'community': 'समुदाय',
    'location': 'स्थान',
    'height': 'उंची',
    'manglik': 'मांगलिक',

    // Messaging
    'noMessagesYet': 'अजून संदेश नाहीत',
    'sayHi': 'हाय म्हणा!',
    'typeMessage': 'संदेश टाइप करा...',
    'suggestedIcebreakers': 'सुचवलेले आइसब्रेकर्स',
    'conversations': 'संभाषणे',
    'noConversations': 'अजून संभाषणे नाहीत',

    // Matches
    'yourMatches': 'तुमचे मॅचेस',
    'noMatches': 'अजून मॅचेस नाहीत',
    'recentMatches': 'अलीकडील मॅचेस',
    'allMatches': 'सर्व मॅचेस',
    'unmatch': 'अनमॅच',
    'unmatchConfirm': 'तुम्हाला खात्री आहे की तुम्ही अनमॅच करू इच्छिता?',

    // Likes
    'peopleWhoLikedYou': 'तुम्हाला लाईक केलेले लोक',
    'superlikes': 'सुपर लाईक्स',
    'noLikesYet': 'अजून लाईक्स नाहीत',
    'sentLikes': 'पाठवलेले लाईक्स',

    // Video Calling
    'videoCall': 'व्हिडिओ कॉल',
    'audioCall': 'ऑडिओ कॉल',
    'incomingCall': 'इनकमिंग कॉल',
    'calling': 'कॉल करत आहे...',
    'answer': 'उत्तर द्या',
    'reject': 'नाकारा',
    'callEnded': 'कॉल संपला',
    'endCall': 'कॉल समाप्त करा',

    // Safety
    'safetyCheckin': 'सेफ्टी चेक-इन',
    'safetyDescription': 'डेटवर जात आहात? सेफ्टी टायमर सेट करा. तुम्ही वेळेत चेक इन केले नाही तर तुमच्या विश्वासू व्यक्तीला अलर्ट पाठवला जाईल.',
    'trustedContactName': 'विश्वासू व्यक्तीचे नाव',
    'theirPhoneNumber': 'त्यांचा फोन नंबर',
    'dateLocation': 'डेट स्थान',
    'duration': 'कालावधी',
    'startCheckin': 'चेक-इन सुरू करा',
    'imSafe': 'मी सुरक्षित आहे',
    'sosAlert': 'SOS अलर्ट',
    'checkinActive': 'चेक-इन सक्रिय',
    'timesUp': 'वेळ संपली!',
    'markedSafe': 'सुरक्षित म्हणून चिन्हांकित! सुरक्षित राहा.',
    'sosAlertSent': 'तुमच्या विश्वासू व्यक्तीला SOS अलर्ट पाठवला!',

    // Kundli
    'kundliMatch': 'कुंडली मॅच',
    'kundliDescription': 'गुण मिलन (अष्टकूट) - हिंदू विवाह परंपरेत वापरली जाणारी ३६-गुणांची वैदिक सुसंगतता प्रणाली.',
    'yourNakshatra': 'तुमचे नक्षत्र',
    'partnerNakshatra': 'जोडीदाराचे नक्षत्र',
    'yourRashi': 'तुमची राशी (ऐच्छिक)',
    'partnerRashi': 'जोडीदाराची राशी (ऐच्छिक)',
    'calculateCompatibility': 'सुसंगतता मोजा',
    'excellentMatch': 'उत्कृष्ट मॅच',
    'goodMatch': 'चांगला मॅच',
    'averageMatch': 'सरासरी मॅच',
    'belowAverage': 'सरासरीपेक्षा कमी',
    'compatibility': 'सुसंगतता',

    // Festivals
    'festivalEvents': 'सण कार्यक्रम',
    'happeningNow': 'आता सुरू आहे',
    'upcomingFestivals': 'आगामी सण',
    'pastEvents': 'मागील कार्यक्रम',
    'interested': 'मला स्वारस्य आहे',
    'youreGoing': 'तुम्ही जात आहात!',
    'activities': 'कार्यकलाप',

    // Entertainment
    'games': 'गेम्स',
    'loveLanguageQuiz': 'प्रेम भाषा क्विझ',
    'triviaGame': 'बॉलीवूड & क्रिकेट ट्रिव्हिया',
    'thisOrThat': 'हे किंवा ते',
    'wouldYouRather': 'तुम्ही कोणते निवडाल',
    'compatibilityGame': 'सुसंगतता गेम',
    'playAgain': 'पुन्हा खेळा',
    'score': 'स्कोअर',
    'highScore': 'हाय स्कोअर',
    'yourResult': 'तुमचा निकाल',
    'takeLoveLanguageQuiz': 'प्रेम भाषा क्विझ घ्या',

    // Endorsements
    'communityReviews': 'समुदाय पुनरावलोकने',
    'endorse': 'एंडोर्स करा',
    'endorseThisPerson': 'या व्यक्तीला एंडोर्स करा',
    'endorsementAnonymous': 'तुमचे एंडोर्समेंट अनामिक आहे आणि विश्वास निर्माण करण्यात मदत करते.',
    'noEndorsementsYet': 'अजून एंडोर्समेंट नाहीत. या व्यक्तीसाठी पहिले जामीनदार व्हा!',

    // Family
    'shareWithFamily': 'कुटुंबासोबत शेअर करा',

    // Gifts
    'giftShop': 'गिफ्ट शॉप',
    'sendGift': 'भेटवस्तू पाठवा',
    'myGifts': 'माझ्या भेटवस्तू',
    'leaderboard': 'लीडरबोर्ड',

    // Subscription
    'subscription': 'सदस्यता',
    'free': 'मोफत',
    'silver': 'सिल्व्हर',
    'gold': 'गोल्ड',
    'upgradeToPremium': 'प्रीमियमवर अपग्रेड करा',
    'currentPlan': 'सध्याचा प्लॅन',

    // Settings
    'language': 'भाषा',
    'selectLanguage': 'भाषा निवडा',
    'languageChanged': 'भाषा यशस्वीरीत्या बदलली!',
    'privacy': 'गोपनीयता',
    'safety': 'सुरक्षितता',
    'notifications': 'सूचना',
    'helpSupport': 'मदत & समर्थन',
    'termsOfService': 'सेवा अटी',
    'privacyPolicy': 'गोपनीयता धोरण',
    'communityGuidelines': 'समुदाय मार्गदर्शक तत्त्वे',

    // Misc
    'fillAllFields': 'कृपया सर्व फील्ड भरा',
    'blockUser': 'वापरकर्त्याला ब्लॉक करा',
    'blockUserConfirm': 'तुम्हाला खात्री आहे की तुम्ही या वापरकर्त्याला ब्लॉक करू इच्छिता? तुम्ही एकमेकांना दिसणार नाही.',
    'userBlocked': 'ब्लॉक केले',
    'reportUser': 'वापरकर्त्याची रिपोर्ट करा',
    'remaining': 'शिल्लक',
    'noResults': 'कोणतेही निकाल सापडले नाहीत',
    'seeAll': 'सर्व पहा',
  };

  // ============================================================
  // GUJARATI TRANSLATIONS (ગુજરાતી)
  // ============================================================
  static const Map<String, String> _guTranslations = {
    // Common
    'appName': 'ઇન્દિરા લવ',
    'ok': 'બરાબર',
    'cancel': 'રદ કરો',
    'save': 'સાચવો',
    'delete': 'કાઢી નાખો',
    'edit': 'ફેરફાર કરો',
    'done': 'પૂર્ણ',
    'next': 'આગળ',
    'back': 'પાછળ',
    'close': 'બંધ કરો',
    'search': 'શોધો',
    'loading': 'લોડ થઈ રહ્યું છે...',
    'error': 'ભૂલ',
    'success': 'સફળતા',
    'retry': 'ફરી પ્રયાસ કરો',
    'yes': 'હા',
    'no': 'ના',
    'submit': 'સબમિટ કરો',
    'send': 'મોકલો',
    'share': 'શેર કરો',
    'report': 'રિપોર્ટ',
    'block': 'બ્લૉક',
    'menu': 'મેનુ',
    'settings': 'સેટિંગ્સ',
    'logout': 'લૉગ આઉટ',

    // Auth
    'welcome': 'ઇન્દિરા લવમાં સ્વાગત છે',
    'welcomeSubtitle': 'તમારો યોગ્ય સાથી શોધો',
    'login': 'લૉગિન',
    'signup': 'સાઇન અપ',
    'email': 'ઇમેઇલ',
    'password': 'પાસવર્ડ',
    'confirmPassword': 'પાસવર્ડ ખાતરી કરો',
    'forgotPassword': 'પાસવર્ડ ભૂલી ગયા?',
    'createAccount': 'ખાતું બનાવો',
    'alreadyHaveAccount': 'પહેલેથી ખાતું છે?',
    'dontHaveAccount': 'ખાતું નથી?',
    'orContinueWith': 'અથવા આનાથી ચાલુ રાખો',
    'signInWithGoogle': 'Google થી સાઇન ઇન કરો',
    'fullName': 'પૂરું નામ',
    'enterEmail': 'તમારો ઇમેઇલ દાખલ કરો',
    'enterPassword': 'તમારો પાસવર્ડ દાખલ કરો',

    // Navigation
    'discover': 'શોધો',
    'likes': 'લાઇક્સ',
    'messages': 'સંદેશાઓ',
    'matches': 'મૅચ',
    'profile': 'પ્રોફાઇલ',
    'gifts': 'ભેટ',
    'social': 'સામાજિક',
    'entertainment': 'મનોરંજન',
    'premium': 'પ્રીમિયમ',
    'activity': 'પ્રવૃત્તિ',

    // Discover
    'discoverPeople': 'લોકો શોધો',
    'noMoreProfiles': 'નજીકમાં વધુ પ્રોફાઇલ નથી',
    'itsAMatch': 'આ મૅચ છે!',
    'keepSwiping': 'સ્વાઇપ કરતા રહો',
    'sendMessage': 'સંદેશો મોકલો',
    'locationSettings': 'સ્થાન સેટિંગ્સ',
    'culturalFilters': 'સાંસ્કૃતિક ફિલ્ટર્સ',
    'boostProfile': 'પ્રોફાઇલ બૂસ્ટ કરો',

    // Profile
    'editProfile': 'પ્રોફાઇલ ફેરફાર કરો',
    'about': 'વિશે',
    'interests': 'રુચિઓ',
    'photos': 'ફોટા',
    'verified': 'ચકાસાયેલ',
    'getVerified': 'ચકાસણી મેળવો',
    'culturalLifestyle': 'સાંસ્કૃતિક & જીવનશૈલી',
    'age': 'ઉંમર',
    'bio': 'બાયો',
    'religion': 'ધર્મ',
    'motherTongue': 'માતૃભાષા',
    'education': 'શિક્ષણ',
    'profession': 'વ્યવસાય',
    'diet': 'ખોરાક',
    'familyValues': 'કૌટુંબિક મૂલ્યો',
    'marriageTimeline': 'લગ્ન સમયરેખા',
    'community': 'સમુદાય',
    'location': 'સ્થાન',
    'height': 'ઊંચાઈ',
    'manglik': 'માંગલિક',

    // Messaging
    'noMessagesYet': 'હજુ સુધી કોઈ સંદેશા નથી',
    'sayHi': 'હાય કહો!',
    'typeMessage': 'સંદેશો ટાઇપ કરો...',
    'suggestedIcebreakers': 'સૂચિત આઇસબ્રેકર્સ',
    'conversations': 'વાતચીત',
    'noConversations': 'હજુ સુધી કોઈ વાતચીત નથી',

    // Matches
    'yourMatches': 'તમારા મૅચ',
    'noMatches': 'હજુ સુધી કોઈ મૅચ નથી',
    'recentMatches': 'તાજેતરના મૅચ',
    'allMatches': 'બધા મૅચ',
    'unmatch': 'અનમૅચ',
    'unmatchConfirm': 'શું તમે ખરેખર અનમૅચ કરવા માંગો છો?',

    // Likes
    'peopleWhoLikedYou': 'તમને લાઇક કરનારા લોકો',
    'superlikes': 'સુપર લાઇક્સ',
    'noLikesYet': 'હજુ સુધી કોઈ લાઇક્સ નથી',
    'sentLikes': 'મોકલેલા લાઇક્સ',

    // Video Calling
    'videoCall': 'વીડિયો કૉલ',
    'audioCall': 'ઑડિયો કૉલ',
    'incomingCall': 'ઇનકમિંગ કૉલ',
    'calling': 'કૉલ કરી રહ્યા છે...',
    'answer': 'જવાબ આપો',
    'reject': 'નકારો',
    'callEnded': 'કૉલ સમાપ્ત',
    'endCall': 'કૉલ સમાપ્ત કરો',

    // Safety
    'safetyCheckin': 'સેફ્ટી ચેક-ઇન',
    'safetyDescription': 'ડેટ પર જઈ રહ્યા છો? સેફ્ટી ટાઇમર સેટ કરો. જો તમે સમયસર ચેક ઇન ન કરો, તો તમારા વિશ્વસનીય વ્યક્તિને ચેતવણી મોકલવામાં આવશે.',
    'trustedContactName': 'વિશ્વસનીય વ્યક્તિનું નામ',
    'theirPhoneNumber': 'તેમનો ફોન નંબર',
    'dateLocation': 'ડેટ સ્થાન',
    'duration': 'સમયગાળો',
    'startCheckin': 'ચેક-ઇન શરૂ કરો',
    'imSafe': 'હું સુરક્ષિત છું',
    'sosAlert': 'SOS ચેતવણી',
    'checkinActive': 'ચેક-ઇન સક્રિય',
    'timesUp': 'સમય પૂરો!',
    'markedSafe': 'સુરક્ષિત તરીકે ચિહ્નિત! સુરક્ષિત રહો.',
    'sosAlertSent': 'તમારા વિશ્વસનીય વ્યક્તિને SOS ચેતવણી મોકલવામાં આવી!',

    // Kundli
    'kundliMatch': 'કુંડળી મૅચ',
    'kundliDescription': 'ગુણ મિલન (અષ્ટકૂટ) - હિંદુ લગ્ન પરંપરામાં વપરાતી ૩૬-ગુણની વૈદિક સુસંગતતા પ્રણાલી.',
    'yourNakshatra': 'તમારું નક્ષત્ર',
    'partnerNakshatra': 'સાથીનું નક્ષત્ર',
    'yourRashi': 'તમારી રાશિ (વૈકલ્પિક)',
    'partnerRashi': 'સાથીની રાશિ (વૈકલ્પિક)',
    'calculateCompatibility': 'સુસંગતતા ગણો',
    'excellentMatch': 'ઉત્તમ મૅચ',
    'goodMatch': 'સારો મૅચ',
    'averageMatch': 'સરેરાશ મૅચ',
    'belowAverage': 'સરેરાશથી ઓછો',
    'compatibility': 'સુસંગતતા',

    // Festivals
    'festivalEvents': 'તહેવાર કાર્યક્રમો',
    'happeningNow': 'હમણાં ચાલુ છે',
    'upcomingFestivals': 'આવનારા તહેવારો',
    'pastEvents': 'ગત કાર્યક્રમો',
    'interested': 'મને રસ છે',
    'youreGoing': 'તમે જઈ રહ્યા છો!',
    'activities': 'પ્રવૃત્તિઓ',

    // Entertainment
    'games': 'રમતો',
    'loveLanguageQuiz': 'પ્રેમ ભાષા ક્વિઝ',
    'triviaGame': 'બૉલીવુડ & ક્રિકેટ ટ્રિવિયા',
    'thisOrThat': 'આ કે તે',
    'wouldYouRather': 'તમે શું પસંદ કરશો',
    'compatibilityGame': 'સુસંગતતા રમત',
    'playAgain': 'ફરી રમો',
    'score': 'સ્કોર',
    'highScore': 'હાઇ સ્કોર',
    'yourResult': 'તમારું પરિણામ',
    'takeLoveLanguageQuiz': 'પ્રેમ ભાષા ક્વિઝ લો',

    // Endorsements
    'communityReviews': 'સમુદાય સમીક્ષાઓ',
    'endorse': 'એન્ડોર્સ કરો',
    'endorseThisPerson': 'આ વ્યક્તિને એન્ડોર્સ કરો',
    'endorsementAnonymous': 'તમારું એન્ડોર્સમેન્ટ અનામી છે અને વિશ્વાસ વધારવામાં મદદ કરે છે.',
    'noEndorsementsYet': 'હજુ સુધી કોઈ એન્ડોર્સમેન્ટ નથી. આ વ્યક્તિ માટે પ્રથમ જામીનદાર બનો!',

    // Family
    'shareWithFamily': 'પરિવાર સાથે શેર કરો',

    // Gifts
    'giftShop': 'ગિફ્ટ શૉપ',
    'sendGift': 'ભેટ મોકલો',
    'myGifts': 'મારી ભેટ',
    'leaderboard': 'લીડરબોર્ડ',

    // Subscription
    'subscription': 'સબ્સ્ક્રિપ્શન',
    'free': 'મફત',
    'silver': 'સિલ્વર',
    'gold': 'ગોલ્ડ',
    'upgradeToPremium': 'પ્રીમિયમમાં અપગ્રેડ કરો',
    'currentPlan': 'વર્તમાન પ્લાન',

    // Settings
    'language': 'ભાષા',
    'selectLanguage': 'ભાષા પસંદ કરો',
    'languageChanged': 'ભાષા સફળતાપૂર્વક બદલાઈ!',
    'privacy': 'ગોપનીયતા',
    'safety': 'સુરક્ષા',
    'notifications': 'સૂચનાઓ',
    'helpSupport': 'મદદ & સપોર્ટ',
    'termsOfService': 'સેવાની શરતો',
    'privacyPolicy': 'ગોપનીયતા નીતિ',
    'communityGuidelines': 'સમુદાય માર્ગદર્શિકા',

    // Misc
    'fillAllFields': 'કૃપા કરીને બધા ફીલ્ડ ભરો',
    'blockUser': 'વપરાશકર્તાને બ્લૉક કરો',
    'blockUserConfirm': 'શું તમે ખરેખર આ વપરાશકર્તાને બ્લૉક કરવા માંગો છો? તમે એકબીજાને જોઈ શકશો નહીં.',
    'userBlocked': 'બ્લૉક કરવામાં આવ્યું',
    'reportUser': 'વપરાશકર્તાની રિપોર્ટ કરો',
    'remaining': 'બાકી',
    'noResults': 'કોઈ પરિણામ મળ્યા નથી',
    'seeAll': 'બધું જુઓ',
  };

  // ============================================================
  // PUNJABI TRANSLATIONS (ਪੰਜਾਬੀ)
  // ============================================================
  static const Map<String, String> _paTranslations = {
    // Common
    'appName': 'ਇੰਦਿਰਾ ਲਵ',
    'ok': 'ਠੀਕ ਹੈ',
    'cancel': 'ਰੱਦ ਕਰੋ',
    'save': 'ਸੇਵ ਕਰੋ',
    'delete': 'ਮਿਟਾਓ',
    'edit': 'ਸੋਧੋ',
    'done': 'ਹੋ ਗਿਆ',
    'next': 'ਅਗਲਾ',
    'back': 'ਪਿੱਛੇ',
    'close': 'ਬੰਦ ਕਰੋ',
    'search': 'ਲੱਭੋ',
    'loading': 'ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...',
    'error': 'ਗਲਤੀ',
    'success': 'ਸਫਲ',
    'retry': 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ',
    'yes': 'ਹਾਂ',
    'no': 'ਨਹੀਂ',
    'submit': 'ਜਮ੍ਹਾਂ ਕਰੋ',
    'send': 'ਭੇਜੋ',
    'share': 'ਸਾਂਝਾ ਕਰੋ',
    'report': 'ਰਿਪੋਰਟ ਕਰੋ',
    'block': 'ਬਲਾਕ ਕਰੋ',
    'menu': 'ਮੀਨੂ',
    'settings': 'ਸੈਟਿੰਗਾਂ',
    'logout': 'ਲੌਗ ਆਊਟ',

    // Auth
    'welcome': 'ਇੰਦਿਰਾ ਲਵ ਵਿੱਚ ਜੀ ਆਇਆਂ ਨੂੰ',
    'welcomeSubtitle': 'ਆਪਣਾ ਸਹੀ ਜੋੜਾ ਲੱਭੋ',
    'login': 'ਲੌਗ ਇਨ',
    'signup': 'ਸਾਈਨ ਅੱਪ',
    'email': 'ਈਮੇਲ',
    'password': 'ਪਾਸਵਰਡ',
    'confirmPassword': 'ਪਾਸਵਰਡ ਪੱਕਾ ਕਰੋ',
    'forgotPassword': 'ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?',
    'createAccount': 'ਖਾਤਾ ਬਣਾਓ',
    'alreadyHaveAccount': 'ਪਹਿਲਾਂ ਤੋਂ ਖਾਤਾ ਹੈ?',
    'dontHaveAccount': 'ਖਾਤਾ ਨਹੀਂ ਹੈ?',
    'orContinueWith': 'ਜਾਂ ਇਸ ਨਾਲ ਜਾਰੀ ਰੱਖੋ',
    'signInWithGoogle': 'Google ਨਾਲ ਸਾਈਨ ਇਨ ਕਰੋ',
    'fullName': 'ਪੂਰਾ ਨਾਮ',
    'enterEmail': 'ਆਪਣੀ ਈਮੇਲ ਦਾਖਲ ਕਰੋ',
    'enterPassword': 'ਆਪਣਾ ਪਾਸਵਰਡ ਦਾਖਲ ਕਰੋ',

    // Navigation
    'discover': 'ਖੋਜੋ',
    'likes': 'ਪਸੰਦਾਂ',
    'messages': 'ਸੁਨੇਹੇ',
    'matches': 'ਮੈਚ',
    'profile': 'ਪ੍ਰੋਫਾਈਲ',
    'gifts': 'ਤੋਹਫ਼ੇ',
    'social': 'ਸਮਾਜਿਕ',
    'entertainment': 'ਮਨੋਰੰਜਨ',
    'premium': 'ਪ੍ਰੀਮੀਅਮ',
    'activity': 'ਗਤੀਵਿਧੀ',

    // Discover
    'discoverPeople': 'ਲੋਕ ਲੱਭੋ',
    'noMoreProfiles': 'ਨੇੜੇ ਹੋਰ ਪ੍ਰੋਫਾਈਲ ਨਹੀਂ ਹਨ',
    'itsAMatch': 'ਇਹ ਇੱਕ ਮੈਚ ਹੈ!',
    'keepSwiping': 'ਸਵਾਈਪ ਕਰਦੇ ਰਹੋ',
    'sendMessage': 'ਸੁਨੇਹਾ ਭੇਜੋ',
    'locationSettings': 'ਟਿਕਾਣਾ ਸੈਟਿੰਗਾਂ',
    'culturalFilters': 'ਸੱਭਿਆਚਾਰਕ ਫਿਲਟਰ',
    'boostProfile': 'ਪ੍ਰੋਫਾਈਲ ਬੂਸਟ ਕਰੋ',

    // Profile
    'editProfile': 'ਪ੍ਰੋਫਾਈਲ ਸੋਧੋ',
    'about': 'ਬਾਰੇ',
    'interests': 'ਦਿਲਚਸਪੀਆਂ',
    'photos': 'ਫੋਟੋਆਂ',
    'verified': 'ਤਸਦੀਕਸ਼ੁਦਾ',
    'getVerified': 'ਤਸਦੀਕ ਕਰਵਾਓ',
    'culturalLifestyle': 'ਸੱਭਿਆਚਾਰਕ ਅਤੇ ਜੀਵਨਸ਼ੈਲੀ',
    'age': 'ਉਮਰ',
    'bio': 'ਬਾਇਓ',
    'religion': 'ਧਰਮ',
    'motherTongue': 'ਮਾਂ ਬੋਲੀ',
    'education': 'ਸਿੱਖਿਆ',
    'profession': 'ਪੇਸ਼ਾ',
    'diet': 'ਖੁਰਾਕ',
    'familyValues': 'ਪਰਿਵਾਰਕ ਕਦਰਾਂ-ਕੀਮਤਾਂ',
    'marriageTimeline': 'ਵਿਆਹ ਦੀ ਸਮਾਂ-ਰੇਖਾ',
    'community': 'ਭਾਈਚਾਰਾ',
    'location': 'ਟਿਕਾਣਾ',
    'height': 'ਕੱਦ',
    'manglik': 'ਮੰਗਲਿਕ',

    // Messaging
    'noMessagesYet': 'ਅਜੇ ਕੋਈ ਸੁਨੇਹੇ ਨਹੀਂ',
    'sayHi': 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ ਕਹੋ!',
    'typeMessage': 'ਸੁਨੇਹਾ ਟਾਈਪ ਕਰੋ...',
    'suggestedIcebreakers': 'ਸੁਝਾਏ ਗਏ ਆਈਸਬ੍ਰੇਕਰ',
    'conversations': 'ਗੱਲਬਾਤ',
    'noConversations': 'ਅਜੇ ਕੋਈ ਗੱਲਬਾਤ ਨਹੀਂ',

    // Matches
    'yourMatches': 'ਤੁਹਾਡੇ ਮੈਚ',
    'noMatches': 'ਅਜੇ ਕੋਈ ਮੈਚ ਨਹੀਂ',
    'recentMatches': 'ਹਾਲ ਦੇ ਮੈਚ',
    'allMatches': 'ਸਾਰੇ ਮੈਚ',
    'unmatch': 'ਅਨਮੈਚ',
    'unmatchConfirm': 'ਕੀ ਤੁਸੀਂ ਸੱਚਮੁੱਚ ਅਨਮੈਚ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?',

    // Likes
    'peopleWhoLikedYou': 'ਜਿਨ੍ਹਾਂ ਨੇ ਤੁਹਾਨੂੰ ਪਸੰਦ ਕੀਤਾ',
    'superlikes': 'ਸੁਪਰ ਲਾਈਕ',
    'noLikesYet': 'ਅਜੇ ਕੋਈ ਲਾਈਕ ਨਹੀਂ',
    'sentLikes': 'ਭੇਜੀਆਂ ਲਾਈਕਾਂ',

    // Video Calling
    'videoCall': 'ਵੀਡੀਓ ਕਾਲ',
    'audioCall': 'ਆਡੀਓ ਕਾਲ',
    'incomingCall': 'ਆਉਣ ਵਾਲੀ ਕਾਲ',
    'calling': 'ਕਾਲ ਹੋ ਰਹੀ ਹੈ...',
    'answer': 'ਜਵਾਬ ਦਿਓ',
    'reject': 'ਰੱਦ ਕਰੋ',
    'callEnded': 'ਕਾਲ ਖਤਮ ਹੋਈ',
    'endCall': 'ਕਾਲ ਖਤਮ ਕਰੋ',

    // Safety
    'safetyCheckin': 'ਸੁਰੱਖਿਆ ਚੈੱਕ-ਇਨ',
    'safetyDescription': 'ਡੇਟ ਤੇ ਜਾ ਰਹੇ ਹੋ? ਸੁਰੱਖਿਆ ਟਾਈਮਰ ਸੈੱਟ ਕਰੋ। ਜੇ ਤੁਸੀਂ ਸਮੇਂ ਤੇ ਚੈੱਕ-ਇਨ ਨਹੀਂ ਕਰਦੇ, ਤੁਹਾਡੇ ਭਰੋਸੇਮੰਦ ਵਿਅਕਤੀ ਨੂੰ ਸੂਚਿਤ ਕੀਤਾ ਜਾਵੇਗਾ।',
    'trustedContactName': 'ਭਰੋਸੇਮੰਦ ਵਿਅਕਤੀ ਦਾ ਨਾਮ',
    'theirPhoneNumber': 'ਉਨ੍ਹਾਂ ਦਾ ਫ਼ੋਨ ਨੰਬਰ',
    'dateLocation': 'ਡੇਟ ਦਾ ਟਿਕਾਣਾ',
    'duration': 'ਸਮਾਂ',
    'startCheckin': 'ਚੈੱਕ-ਇਨ ਸ਼ੁਰੂ ਕਰੋ',
    'imSafe': 'ਮੈਂ ਸੁਰੱਖਿਅਤ ਹਾਂ',
    'sosAlert': 'SOS ਅਲਰਟ',
    'checkinActive': 'ਚੈੱਕ-ਇਨ ਚਾਲੂ ਹੈ',
    'timesUp': 'ਸਮਾਂ ਖਤਮ!',
    'markedSafe': 'ਸੁਰੱਖਿਅਤ ਮਾਰਕ ਕੀਤਾ! ਸੁਰੱਖਿਅਤ ਰਹੋ।',
    'sosAlertSent': 'ਤੁਹਾਡੇ ਭਰੋਸੇਮੰਦ ਵਿਅਕਤੀ ਨੂੰ SOS ਅਲਰਟ ਭੇਜਿਆ ਗਿਆ!',

    // Kundli
    'kundliMatch': 'ਕੁੰਡਲੀ ਮੈਚ',
    'kundliDescription': 'ਗੁਣ ਮਿਲਾਨ (ਅਸ਼ਟਕੂਟ) - ਹਿੰਦੂ ਵਿਆਹ ਵਿੱਚ ਵਰਤੀ ਜਾਣ ਵਾਲੀ ਰਵਾਇਤੀ 36 ਅੰਕ ਵੈਦਿਕ ਅਨੁਕੂਲਤਾ ਪ੍ਰਣਾਲੀ।',
    'yourNakshatra': 'ਤੁਹਾਡਾ ਨਕਸ਼ਤਰ',
    'partnerNakshatra': 'ਸਾਥੀ ਦਾ ਨਕਸ਼ਤਰ',
    'yourRashi': 'ਤੁਹਾਡੀ ਰਾਸ਼ੀ (ਵਿਕਲਪਿਕ)',
    'partnerRashi': 'ਸਾਥੀ ਦੀ ਰਾਸ਼ੀ (ਵਿਕਲਪਿਕ)',
    'calculateCompatibility': 'ਅਨੁਕੂਲਤਾ ਦੀ ਗਣਨਾ ਕਰੋ',
    'excellentMatch': 'ਸ਼ਾਨਦਾਰ ਮੈਚ',
    'goodMatch': 'ਵਧੀਆ ਮੈਚ',
    'averageMatch': 'ਔਸਤ ਮੈਚ',
    'belowAverage': 'ਔਸਤ ਤੋਂ ਘੱਟ',
    'compatibility': 'ਅਨੁਕੂਲਤਾ',

    // Festivals
    'festivalEvents': 'ਤਿਉਹਾਰ ਸਮਾਗਮ',
    'happeningNow': 'ਹੁਣ ਹੋ ਰਿਹਾ ਹੈ',
    'upcomingFestivals': 'ਆਉਣ ਵਾਲੇ ਤਿਉਹਾਰ',
    'pastEvents': 'ਪਿਛਲੇ ਸਮਾਗਮ',
    'interested': 'ਮੈਨੂੰ ਦਿਲਚਸਪੀ ਹੈ',
    'youreGoing': 'ਤੁਸੀਂ ਜਾ ਰਹੇ ਹੋ!',
    'activities': 'ਗਤੀਵਿਧੀਆਂ',

    // Entertainment
    'games': 'ਖੇਡਾਂ',
    'loveLanguageQuiz': 'ਪਿਆਰ ਦੀ ਭਾਸ਼ਾ ਕੁਇਜ਼',
    'triviaGame': 'ਬਾਲੀਵੁੱਡ ਅਤੇ ਕ੍ਰਿਕਟ ਟ੍ਰਿਵੀਆ',
    'thisOrThat': 'ਇਹ ਜਾਂ ਉਹ',
    'wouldYouRather': 'ਤੁਸੀਂ ਕੀ ਕਰੋਗੇ',
    'compatibilityGame': 'ਅਨੁਕੂਲਤਾ ਖੇਡ',
    'playAgain': 'ਦੁਬਾਰਾ ਖੇਡੋ',
    'score': 'ਅੰਕ',
    'highScore': 'ਸਭ ਤੋਂ ਵੱਧ ਅੰਕ',
    'yourResult': 'ਤੁਹਾਡਾ ਨਤੀਜਾ',
    'takeLoveLanguageQuiz': 'ਪਿਆਰ ਦੀ ਭਾਸ਼ਾ ਕੁਇਜ਼ ਲਓ',

    // Endorsements
    'communityReviews': 'ਭਾਈਚਾਰਾ ਸਮੀਖਿਆਵਾਂ',
    'endorse': 'ਸਮਰਥਨ ਕਰੋ',
    'endorseThisPerson': 'ਇਸ ਵਿਅਕਤੀ ਦਾ ਸਮਰਥਨ ਕਰੋ',
    'endorsementAnonymous': 'ਤੁਹਾਡਾ ਸਮਰਥਨ ਗੁਮਨਾਮ ਹੈ ਅਤੇ ਭਰੋਸਾ ਬਣਾਉਣ ਵਿੱਚ ਮਦਦ ਕਰਦਾ ਹੈ।',
    'noEndorsementsYet': 'ਅਜੇ ਕੋਈ ਸਮਰਥਨ ਨਹੀਂ। ਪਹਿਲੇ ਬਣੋ!',

    // Family
    'shareWithFamily': 'ਪਰਿਵਾਰ ਨਾਲ ਸਾਂਝਾ ਕਰੋ',

    // Gifts
    'giftShop': 'ਤੋਹਫ਼ਿਆਂ ਦੀ ਦੁਕਾਨ',
    'sendGift': 'ਤੋਹਫ਼ਾ ਭੇਜੋ',
    'myGifts': 'ਮੇਰੇ ਤੋਹਫ਼ੇ',
    'leaderboard': 'ਲੀਡਰਬੋਰਡ',

    // Subscription
    'subscription': 'ਮੈਂਬਰਸ਼ਿਪ',
    'free': 'ਮੁਫ਼ਤ',
    'silver': 'ਸਿਲਵਰ',
    'gold': 'ਗੋਲਡ',
    'upgradeToPremium': 'ਪ੍ਰੀਮੀਅਮ ਵਿੱਚ ਅੱਪਗ੍ਰੇਡ ਕਰੋ',
    'currentPlan': 'ਮੌਜੂਦਾ ਯੋਜਨਾ',

    // Settings
    'language': 'ਭਾਸ਼ਾ',
    'selectLanguage': 'ਭਾਸ਼ਾ ਚੁਣੋ',
    'languageChanged': 'ਭਾਸ਼ਾ ਸਫਲਤਾਪੂਰਵਕ ਬਦਲ ਦਿੱਤੀ ਗਈ!',
    'privacy': 'ਗੋਪਨੀਯਤਾ',
    'safety': 'ਸੁਰੱਖਿਆ',
    'notifications': 'ਸੂਚਨਾਵਾਂ',
    'helpSupport': 'ਮਦਦ ਅਤੇ ਸਹਾਇਤਾ',
    'termsOfService': 'ਸੇਵਾ ਦੀਆਂ ਸ਼ਰਤਾਂ',
    'privacyPolicy': 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ',
    'communityGuidelines': 'ਭਾਈਚਾਰਾ ਦਿਸ਼ਾ-ਨਿਰਦੇਸ਼',

    // Misc
    'fillAllFields': 'ਕਿਰਪਾ ਕਰਕੇ ਸਾਰੇ ਖੇਤਰ ਭਰੋ',
    'blockUser': 'ਵਰਤੋਂਕਾਰ ਨੂੰ ਬਲਾਕ ਕਰੋ',
    'blockUserConfirm': 'ਕੀ ਤੁਸੀਂ ਸੱਚਮੁੱਚ ਇਸ ਵਰਤੋਂਕਾਰ ਨੂੰ ਬਲਾਕ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ? ਤੁਸੀਂ ਇੱਕ ਦੂਜੇ ਨੂੰ ਨਹੀਂ ਦੇਖ ਸਕੋਗੇ।',
    'userBlocked': 'ਬਲਾਕ ਕਰ ਦਿੱਤਾ ਗਿਆ',
    'reportUser': 'ਵਰਤੋਂਕਾਰ ਦੀ ਰਿਪੋਰਟ ਕਰੋ',
    'remaining': 'ਬਾਕੀ',
    'noResults': 'ਕੋਈ ਨਤੀਜੇ ਨਹੀਂ ਮਿਲੇ',
    'seeAll': 'ਸਭ ਦੇਖੋ',
  };

  // ============================================================
  // ODIA TRANSLATIONS (ଓଡ଼ିଆ)
  // ============================================================
  static const Map<String, String> _orTranslations = {
    // Common
    'appName': 'ଇନ୍ଦିରା ଲଭ୍',
    'ok': 'ଠିକ୍ ଅଛି',
    'cancel': 'ବାତିଲ୍ କରନ୍ତୁ',
    'save': 'ସଞ୍ଚୟ କରନ୍ତୁ',
    'delete': 'ବିଲୋପ କରନ୍ତୁ',
    'edit': 'ସମ୍ପାଦନା କରନ୍ତୁ',
    'done': 'ହୋଇଗଲା',
    'next': 'ପରବର୍ତ୍ତୀ',
    'back': 'ପଛକୁ',
    'close': 'ବନ୍ଦ କରନ୍ତୁ',
    'search': 'ଖୋଜନ୍ତୁ',
    'loading': 'ଲୋଡ୍ ହେଉଛି...',
    'error': 'ତ୍ରୁଟି',
    'success': 'ସଫଳ',
    'retry': 'ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ',
    'yes': 'ହଁ',
    'no': 'ନା',
    'submit': 'ଦାଖଲ କରନ୍ତୁ',
    'send': 'ପଠାନ୍ତୁ',
    'share': 'ଅଂଶୀଦାର କରନ୍ତୁ',
    'report': 'ରିପୋର୍ଟ କରନ୍ତୁ',
    'block': 'ବ୍ଲକ୍ କରନ୍ତୁ',
    'menu': 'ମେନୁ',
    'settings': 'ସେଟିଂସ୍',
    'logout': 'ଲଗ୍ ଆଉଟ୍',

    // Auth
    'welcome': 'ଇନ୍ଦିରା ଲଭ୍‌ରେ ସ୍ୱାଗତ',
    'welcomeSubtitle': 'ଆପଣଙ୍କ ଉପଯୁକ୍ତ ସାଥୀ ଖୋଜନ୍ତୁ',
    'login': 'ଲଗ୍ ଇନ୍',
    'signup': 'ସାଇନ୍ ଅପ୍',
    'email': 'ଇମେଲ୍',
    'password': 'ପାସୱାର୍ଡ',
    'confirmPassword': 'ପାସୱାର୍ଡ ନିଶ୍ଚିତ କରନ୍ତୁ',
    'forgotPassword': 'ପାସୱାର୍ଡ ଭୁଲି ଗଲେ?',
    'createAccount': 'ଖାତା ତିଆରି କରନ୍ତୁ',
    'alreadyHaveAccount': 'ପୂର୍ବରୁ ଖାତା ଅଛି?',
    'dontHaveAccount': 'ଖାତା ନାହିଁ?',
    'orContinueWith': 'କିମ୍ବା ଏହା ସହିତ ଜାରି ରଖନ୍ତୁ',
    'signInWithGoogle': 'Google ସହିତ ସାଇନ୍ ଇନ୍ କରନ୍ତୁ',
    'fullName': 'ପୂରା ନାମ',
    'enterEmail': 'ଆପଣଙ୍କ ଇମେଲ୍ ଦିଅନ୍ତୁ',
    'enterPassword': 'ଆପଣଙ୍କ ପାସୱାର୍ଡ ଦିଅନ୍ତୁ',

    // Navigation
    'discover': 'ଅନ୍ୱେଷଣ',
    'likes': 'ପସନ୍ଦ',
    'messages': 'ସନ୍ଦେଶ',
    'matches': 'ମ୍ୟାଚ୍',
    'profile': 'ପ୍ରୋଫାଇଲ୍',
    'gifts': 'ଉପହାର',
    'social': 'ସାମାଜିକ',
    'entertainment': 'ମନୋରଞ୍ଜନ',
    'premium': 'ପ୍ରିମିୟମ୍',
    'activity': 'କାର୍ଯ୍ୟକଳାପ',

    // Discover
    'discoverPeople': 'ଲୋକମାନଙ୍କୁ ଖୋଜନ୍ତୁ',
    'noMoreProfiles': 'ନିକଟରେ ଆଉ ପ୍ରୋଫାଇଲ୍ ନାହିଁ',
    'itsAMatch': 'ଏହା ଏକ ମ୍ୟାଚ୍!',
    'keepSwiping': 'ସ୍ୱାଇପ୍ କରୁଥାନ୍ତୁ',
    'sendMessage': 'ସନ୍ଦେଶ ପଠାନ୍ତୁ',
    'locationSettings': 'ଅବସ୍ଥାନ ସେଟିଂସ୍',
    'culturalFilters': 'ସାଂସ୍କୃତିକ ଫିଲ୍ଟର',
    'boostProfile': 'ପ୍ରୋଫାଇଲ୍ ବୁଷ୍ଟ କରନ୍ତୁ',

    // Profile
    'editProfile': 'ପ୍ରୋଫାଇଲ୍ ସମ୍ପାଦନା କରନ୍ତୁ',
    'about': 'ବିଷୟରେ',
    'interests': 'ଆଗ୍ରହ',
    'photos': 'ଫଟୋ',
    'verified': 'ଯାଞ୍ଚ ହୋଇଛି',
    'getVerified': 'ଯାଞ୍ଚ କରାନ୍ତୁ',
    'culturalLifestyle': 'ସାଂସ୍କୃତିକ ଏବଂ ଜୀବନଶୈଳୀ',
    'age': 'ବୟସ',
    'bio': 'ବାଇଓ',
    'religion': 'ଧର୍ମ',
    'motherTongue': 'ମାତୃଭାଷା',
    'education': 'ଶିକ୍ଷା',
    'profession': 'ବୃତ୍ତି',
    'diet': 'ଖାଦ୍ୟ',
    'familyValues': 'ପାରିବାରିକ ମୂଲ୍ୟବୋଧ',
    'marriageTimeline': 'ବିବାହ ସମୟସୀମା',
    'community': 'ସମୁଦାୟ',
    'location': 'ଅବସ୍ଥାନ',
    'height': 'ଉଚ୍ଚତା',
    'manglik': 'ମାଙ୍ଗଳିକ',

    // Messaging
    'noMessagesYet': 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ସନ୍ଦେଶ ନାହିଁ',
    'sayHi': 'ନମସ୍କାର କୁହନ୍ତୁ!',
    'typeMessage': 'ସନ୍ଦେଶ ଟାଇପ୍ କରନ୍ତୁ...',
    'suggestedIcebreakers': 'ପ୍ରସ୍ତାବିତ ଆଇସବ୍ରେକର',
    'conversations': 'ବାର୍ତ୍ତାଳାପ',
    'noConversations': 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ବାର୍ତ୍ତାଳାପ ନାହିଁ',

    // Matches
    'yourMatches': 'ଆପଣଙ୍କ ମ୍ୟାଚ୍',
    'noMatches': 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ମ୍ୟାଚ୍ ନାହିଁ',
    'recentMatches': 'ସାମ୍ପ୍ରତିକ ମ୍ୟାଚ୍',
    'allMatches': 'ସମସ୍ତ ମ୍ୟାଚ୍',
    'unmatch': 'ଅନମ୍ୟାଚ୍',
    'unmatchConfirm': 'ଆପଣ ନିଶ୍ଚିତ ଅନମ୍ୟାଚ୍ କରିବାକୁ ଚାହୁଁଛନ୍ତି?',

    // Likes
    'peopleWhoLikedYou': 'ଯେଉଁମାନେ ଆପଣଙ୍କୁ ପସନ୍ଦ କଲେ',
    'superlikes': 'ସୁପର ଲାଇକ୍',
    'noLikesYet': 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ଲାଇକ୍ ନାହିଁ',
    'sentLikes': 'ପଠାଯାଇଥିବା ଲାଇକ୍',

    // Video Calling
    'videoCall': 'ଭିଡିଓ କଲ୍',
    'audioCall': 'ଅଡିଓ କଲ୍',
    'incomingCall': 'ଆସୁଥିବା କଲ୍',
    'calling': 'କଲ୍ ହେଉଛି...',
    'answer': 'ଉତ୍ତର ଦିଅନ୍ତୁ',
    'reject': 'ପ୍ରତ୍ୟାଖ୍ୟାନ କରନ୍ତୁ',
    'callEnded': 'କଲ୍ ସମାପ୍ତ',
    'endCall': 'କଲ୍ ସମାପ୍ତ କରନ୍ତୁ',

    // Safety
    'safetyCheckin': 'ସୁରକ୍ଷା ଚେକ୍-ଇନ୍',
    'safetyDescription': 'ଡେଟ୍‌ରେ ଯାଉଛନ୍ତି? ସୁରକ୍ଷା ଟାଇମର ସେଟ୍ କରନ୍ତୁ। ଯଦି ଆପଣ ସମୟରେ ଚେକ୍-ଇନ୍ ନ କରନ୍ତି, ଆପଣଙ୍କ ବିଶ୍ୱସ୍ତ ବ୍ୟକ୍ତିଙ୍କୁ ସୂଚିତ କରାଯିବ।',
    'trustedContactName': 'ବିଶ୍ୱସ୍ତ ବ୍ୟକ୍ତିଙ୍କ ନାମ',
    'theirPhoneNumber': 'ସେମାନଙ୍କ ଫୋନ୍ ନମ୍ବର',
    'dateLocation': 'ଡେଟ୍ ସ୍ଥାନ',
    'duration': 'ସମୟସୀମା',
    'startCheckin': 'ଚେକ୍-ଇନ୍ ଆରମ୍ଭ କରନ୍ତୁ',
    'imSafe': 'ମୁଁ ସୁରକ୍ଷିତ',
    'sosAlert': 'SOS ସତର୍କତା',
    'checkinActive': 'ଚେକ୍-ଇନ୍ ସକ୍ରିୟ',
    'timesUp': 'ସମୟ ସରିଗଲା!',
    'markedSafe': 'ସୁରକ୍ଷିତ ଚିହ୍ନିତ! ସୁରକ୍ଷିତ ରୁହନ୍ତୁ।',
    'sosAlertSent': 'ଆପଣଙ୍କ ବିଶ୍ୱସ୍ତ ବ୍ୟକ୍ତିଙ୍କୁ SOS ସତର୍କତା ପଠାଯାଇଛି!',

    // Kundli
    'kundliMatch': 'କୁଣ୍ଡଳୀ ମ୍ୟାଚ୍',
    'kundliDescription': 'ଗୁଣ ମିଳନ (ଅଷ୍ଟକୂଟ) - ହିନ୍ଦୁ ବିବାହରେ ବ୍ୟବହୃତ ପାରମ୍ପରିକ ୩୬ ପଏଣ୍ଟ ବୈଦିକ ସୁସଙ୍ଗତତା ପ୍ରଣାଳୀ।',
    'yourNakshatra': 'ଆପଣଙ୍କ ନକ୍ଷତ୍ର',
    'partnerNakshatra': 'ସାଥୀଙ୍କ ନକ୍ଷତ୍ର',
    'yourRashi': 'ଆପଣଙ୍କ ରାଶି (ଐଚ୍ଛିକ)',
    'partnerRashi': 'ସାଥୀଙ୍କ ରାଶି (ଐଚ୍ଛିକ)',
    'calculateCompatibility': 'ସୁସଙ୍ଗତତା ଗଣନା କରନ୍ତୁ',
    'excellentMatch': 'ଉତ୍କୃଷ୍ଟ ମ୍ୟାଚ୍',
    'goodMatch': 'ଭଲ ମ୍ୟାଚ୍',
    'averageMatch': 'ହାରାହାରି ମ୍ୟାଚ୍',
    'belowAverage': 'ହାରାହାରିଠାରୁ କମ୍',
    'compatibility': 'ସୁସଙ୍ଗତତା',

    // Festivals
    'festivalEvents': 'ପର୍ବ ଅନୁଷ୍ଠାନ',
    'happeningNow': 'ବର୍ତ୍ତମାନ ଚାଲୁଛି',
    'upcomingFestivals': 'ଆସୁଥିବା ପର୍ବ',
    'pastEvents': 'ଅତୀତ ଅନୁଷ୍ଠାନ',
    'interested': 'ମୋର ଆଗ୍ରହ ଅଛି',
    'youreGoing': 'ଆପଣ ଯାଉଛନ୍ତି!',
    'activities': 'କାର୍ଯ୍ୟକଳାପ',

    // Entertainment
    'games': 'ଖେଳ',
    'loveLanguageQuiz': 'ପ୍ରେମ ଭାଷା କୁଇଜ୍',
    'triviaGame': 'ବଲିଉଡ୍ ଏବଂ କ୍ରିକେଟ୍ ଟ୍ରିଭିଆ',
    'thisOrThat': 'ଏହା କି ସେହା',
    'wouldYouRather': 'ଆପଣ କଣ କରିବେ',
    'compatibilityGame': 'ସୁସଙ୍ଗତତା ଖେଳ',
    'playAgain': 'ପୁଣି ଖେଳନ୍ତୁ',
    'score': 'ସ୍କୋର',
    'highScore': 'ସର୍ବାଧିକ ସ୍କୋର',
    'yourResult': 'ଆପଣଙ୍କ ଫଳାଫଳ',
    'takeLoveLanguageQuiz': 'ପ୍ରେମ ଭାଷା କୁଇଜ୍ ନିଅନ୍ତୁ',

    // Endorsements
    'communityReviews': 'ସମୁଦାୟ ସମୀକ୍ଷା',
    'endorse': 'ସମର୍ଥନ କରନ୍ତୁ',
    'endorseThisPerson': 'ଏହି ବ୍ୟକ୍ତିଙ୍କୁ ସମର୍ଥନ କରନ୍ତୁ',
    'endorsementAnonymous': 'ଆପଣଙ୍କ ସମର୍ଥନ ଅଜ୍ଞାତ ଏବଂ ବିଶ୍ୱାସ ଗଢ଼ିବାରେ ସାହାଯ୍ୟ କରେ।',
    'noEndorsementsYet': 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ସମର୍ଥନ ନାହିଁ। ପ୍ରଥମ ହୁଅନ୍ତୁ!',

    // Family
    'shareWithFamily': 'ପରିବାର ସହ ଅଂଶୀଦାର କରନ୍ତୁ',

    // Gifts
    'giftShop': 'ଉପହାର ଦୋକାନ',
    'sendGift': 'ଉପହାର ପଠାନ୍ତୁ',
    'myGifts': 'ମୋର ଉପହାର',
    'leaderboard': 'ଲିଡରବୋର୍ଡ',

    // Subscription
    'subscription': 'ସଦସ୍ୟତା',
    'free': 'ମାଗଣା',
    'silver': 'ସିଲଭର',
    'gold': 'ଗୋଲ୍ଡ',
    'upgradeToPremium': 'ପ୍ରିମିୟମ୍‌କୁ ଅପଗ୍ରେଡ୍ କରନ୍ତୁ',
    'currentPlan': 'ବର୍ତ୍ତମାନ ଯୋଜନା',

    // Settings
    'language': 'ଭାଷା',
    'selectLanguage': 'ଭାଷା ବାଛନ୍ତୁ',
    'languageChanged': 'ଭାଷା ସଫଳତାର ସହ ପରିବର୍ତ୍ତନ ହେଲା!',
    'privacy': 'ଗୋପନୀୟତା',
    'safety': 'ସୁରକ୍ଷା',
    'notifications': 'ସୂଚନା',
    'helpSupport': 'ସାହାଯ୍ୟ ଏବଂ ସମର୍ଥନ',
    'termsOfService': 'ସେବା ସର୍ତ୍ତ',
    'privacyPolicy': 'ଗୋପନୀୟତା ନୀତି',
    'communityGuidelines': 'ସମୁଦାୟ ମାର୍ଗଦର୍ଶିକା',

    // Misc
    'fillAllFields': 'ଦୟାକରି ସମସ୍ତ ଫିଲ୍ଡ ପୂରଣ କରନ୍ତୁ',
    'blockUser': 'ବ୍ୟବହାରକାରୀଙ୍କୁ ବ୍ଲକ୍ କରନ୍ତୁ',
    'blockUserConfirm': 'ଆପଣ ନିଶ୍ଚିତ ଏହି ବ୍ୟବହାରକାରୀଙ୍କୁ ବ୍ଲକ୍ କରିବାକୁ ଚାହୁଁଛନ୍ତି? ଆପଣମାନେ ପରସ୍ପରକୁ ଦେଖିପାରିବେ ନାହିଁ।',
    'userBlocked': 'ବ୍ଲକ୍ କରାଯାଇଛି',
    'reportUser': 'ବ୍ୟବହାରକାରୀଙ୍କୁ ରିପୋର୍ଟ କରନ୍ତୁ',
    'remaining': 'ବାକି',
    'noResults': 'କୌଣସି ଫଳାଫଳ ମିଳିଲା ନାହିଁ',
    'seeAll': 'ସବୁ ଦେଖନ୍ତୁ',
  };

  // ============================================================
  // NEPALI TRANSLATIONS (नेपाली)
  // ============================================================
  static const Map<String, String> _neTranslations = {
    // Common
    'appName': 'इन्दिरा लभ',
    'ok': 'ठीक छ',
    'cancel': 'रद्द गर्नुहोस्',
    'save': 'सुरक्षित गर्नुहोस्',
    'delete': 'मेट्नुहोस्',
    'edit': 'सम्पादन गर्नुहोस्',
    'done': 'भयो',
    'next': 'अर्को',
    'back': 'पछाडि',
    'close': 'बन्द गर्नुहोस्',
    'search': 'खोज्नुहोस्',
    'loading': 'लोड हुँदैछ...',
    'error': 'त्रुटि',
    'success': 'सफल',
    'retry': 'पुन: प्रयास गर्नुहोस्',
    'yes': 'हो',
    'no': 'होइन',
    'submit': 'पेश गर्नुहोस्',
    'send': 'पठाउनुहोस्',
    'share': 'साझा गर्नुहोस्',
    'report': 'रिपोर्ट गर्नुहोस्',
    'block': 'ब्लक गर्नुहोस्',
    'menu': 'मेनु',
    'settings': 'सेटिङ्स',
    'logout': 'लग आउट',

    // Auth
    'welcome': 'इन्दिरा लभमा स्वागत छ',
    'welcomeSubtitle': 'आफ्नो उचित जोडी खोज्नुहोस्',
    'login': 'लग इन',
    'signup': 'साइन अप',
    'email': 'इमेल',
    'password': 'पासवर्ड',
    'confirmPassword': 'पासवर्ड पुष्टि गर्नुहोस्',
    'forgotPassword': 'पासवर्ड बिर्सनुभयो?',
    'createAccount': 'खाता बनाउनुहोस्',
    'alreadyHaveAccount': 'पहिले नै खाता छ?',
    'dontHaveAccount': 'खाता छैन?',
    'orContinueWith': 'वा यससँग जारी राख्नुहोस्',
    'signInWithGoogle': 'Google सँग साइन इन गर्नुहोस्',
    'fullName': 'पूरा नाम',
    'enterEmail': 'आफ्नो इमेल राख्नुहोस्',
    'enterPassword': 'आफ्नो पासवर्ड राख्नुहोस्',

    // Navigation
    'discover': 'खोज',
    'likes': 'मनपर्ने',
    'messages': 'सन्देश',
    'matches': 'म्याच',
    'profile': 'प्रोफाइल',
    'gifts': 'उपहार',
    'social': 'सामाजिक',
    'entertainment': 'मनोरञ्जन',
    'premium': 'प्रिमियम',
    'activity': 'गतिविधि',

    // Discover
    'discoverPeople': 'मानिसहरू खोज्नुहोस्',
    'noMoreProfiles': 'नजिकमा थप प्रोफाइल छैन',
    'itsAMatch': 'यो एक म्याच हो!',
    'keepSwiping': 'स्वाइप गरिरहनुहोस्',
    'sendMessage': 'सन्देश पठाउनुहोस्',
    'locationSettings': 'स्थान सेटिङ्स',
    'culturalFilters': 'सांस्कृतिक फिल्टर',
    'boostProfile': 'प्रोफाइल बुस्ट गर्नुहोस्',

    // Profile
    'editProfile': 'प्रोफाइल सम्पादन गर्नुहोस्',
    'about': 'बारेमा',
    'interests': 'रुचिहरू',
    'photos': 'फोटोहरू',
    'verified': 'प्रमाणित',
    'getVerified': 'प्रमाणित हुनुहोस्',
    'culturalLifestyle': 'सांस्कृतिक र जीवनशैली',
    'age': 'उमेर',
    'bio': 'बायो',
    'religion': 'धर्म',
    'motherTongue': 'मातृभाषा',
    'education': 'शिक्षा',
    'profession': 'पेशा',
    'diet': 'आहार',
    'familyValues': 'पारिवारिक मूल्य',
    'marriageTimeline': 'विवाह समयरेखा',
    'community': 'समुदाय',
    'location': 'स्थान',
    'height': 'उचाइ',
    'manglik': 'मांगलिक',

    // Messaging
    'noMessagesYet': 'अहिलेसम्म कुनै सन्देश छैन',
    'sayHi': 'नमस्ते भन्नुहोस्!',
    'typeMessage': 'सन्देश टाइप गर्नुहोस्...',
    'suggestedIcebreakers': 'सुझाव गरिएका आइसब्रेकर',
    'conversations': 'कुराकानी',
    'noConversations': 'अहिलेसम्म कुनै कुराकानी छैन',

    // Matches
    'yourMatches': 'तपाईंका म्याचहरू',
    'noMatches': 'अहिलेसम्म कुनै म्याच छैन',
    'recentMatches': 'हालका म्याचहरू',
    'allMatches': 'सबै म्याचहरू',
    'unmatch': 'अनम्याच',
    'unmatchConfirm': 'के तपाईं साँच्चै अनम्याच गर्न चाहनुहुन्छ?',

    // Likes
    'peopleWhoLikedYou': 'तपाईंलाई मन पराउनेहरू',
    'superlikes': 'सुपर लाइक',
    'noLikesYet': 'अहिलेसम्म कुनै लाइक छैन',
    'sentLikes': 'पठाइएका लाइकहरू',

    // Video Calling
    'videoCall': 'भिडियो कल',
    'audioCall': 'अडियो कल',
    'incomingCall': 'आउने कल',
    'calling': 'कल हुँदैछ...',
    'answer': 'उत्तर दिनुहोस्',
    'reject': 'अस्वीकार गर्नुहोस्',
    'callEnded': 'कल समाप्त भयो',
    'endCall': 'कल समाप्त गर्नुहोस्',

    // Safety
    'safetyCheckin': 'सुरक्षा चेक-इन',
    'safetyDescription': 'डेटमा जाँदै हुनुहुन्छ? सुरक्षा टाइमर सेट गर्नुहोस्। समयमा चेक-इन नगर्नुभयो भने तपाईंको विश्वसनीय व्यक्तिलाई सूचित गरिनेछ।',
    'trustedContactName': 'विश्वसनीय व्यक्तिको नाम',
    'theirPhoneNumber': 'उनीहरूको फोन नम्बर',
    'dateLocation': 'डेटको स्थान',
    'duration': 'अवधि',
    'startCheckin': 'चेक-इन सुरु गर्नुहोस्',
    'imSafe': 'म सुरक्षित छु',
    'sosAlert': 'SOS अलर्ट',
    'checkinActive': 'चेक-इन सक्रिय छ',
    'timesUp': 'समय सकियो!',
    'markedSafe': 'सुरक्षित चिन्ह लगाइयो! सुरक्षित रहनुहोस्।',
    'sosAlertSent': 'तपाईंको विश्वसनीय व्यक्तिलाई SOS अलर्ट पठाइयो!',

    // Kundli
    'kundliMatch': 'कुण्डली म्याच',
    'kundliDescription': 'गुण मिलान (अष्टकूट) - हिन्दू विवाहमा प्रयोग हुने परम्परागत ३६ अंकको वैदिक अनुकूलता प्रणाली।',
    'yourNakshatra': 'तपाईंको नक्षत्र',
    'partnerNakshatra': 'साथीको नक्षत्र',
    'yourRashi': 'तपाईंको राशि (ऐच्छिक)',
    'partnerRashi': 'साथीको राशि (ऐच्छिक)',
    'calculateCompatibility': 'अनुकूलता गणना गर्नुहोस्',
    'excellentMatch': 'उत्कृष्ट म्याच',
    'goodMatch': 'राम्रो म्याच',
    'averageMatch': 'औसत म्याच',
    'belowAverage': 'औसतभन्दा कम',
    'compatibility': 'अनुकूलता',

    // Festivals
    'festivalEvents': 'चाडपर्व कार्यक्रम',
    'happeningNow': 'अहिले भइरहेको',
    'upcomingFestivals': 'आगामी चाडपर्व',
    'pastEvents': 'विगतका कार्यक्रम',
    'interested': 'मलाई रुचि छ',
    'youreGoing': 'तपाईं जाँदै हुनुहुन्छ!',
    'activities': 'गतिविधिहरू',

    // Entertainment
    'games': 'खेलहरू',
    'loveLanguageQuiz': 'प्रेम भाषा क्विज',
    'triviaGame': 'बलिउड र क्रिकेट ट्रिभिया',
    'thisOrThat': 'यो कि त्यो',
    'wouldYouRather': 'तपाईं के गर्नुहुन्छ',
    'compatibilityGame': 'अनुकूलता खेल',
    'playAgain': 'फेरि खेल्नुहोस्',
    'score': 'अंक',
    'highScore': 'सर्वोच्च अंक',
    'yourResult': 'तपाईंको नतिजा',
    'takeLoveLanguageQuiz': 'प्रेम भाषा क्विज लिनुहोस्',

    // Endorsements
    'communityReviews': 'समुदाय समीक्षा',
    'endorse': 'समर्थन गर्नुहोस्',
    'endorseThisPerson': 'यस व्यक्तिलाई समर्थन गर्नुहोस्',
    'endorsementAnonymous': 'तपाईंको समर्थन गोप्य छ र विश्वास बनाउन मद्दत गर्छ।',
    'noEndorsementsYet': 'अहिलेसम्म कुनै समर्थन छैन। पहिलो बन्नुहोस्!',

    // Family
    'shareWithFamily': 'परिवारसँग साझा गर्नुहोस्',

    // Gifts
    'giftShop': 'उपहार पसल',
    'sendGift': 'उपहार पठाउनुहोस्',
    'myGifts': 'मेरा उपहारहरू',
    'leaderboard': 'लिडरबोर्ड',

    // Subscription
    'subscription': 'सदस्यता',
    'free': 'निःशुल्क',
    'silver': 'सिल्भर',
    'gold': 'गोल्ड',
    'upgradeToPremium': 'प्रिमियममा अपग्रेड गर्नुहोस्',
    'currentPlan': 'हालको योजना',

    // Settings
    'language': 'भाषा',
    'selectLanguage': 'भाषा छान्नुहोस्',
    'languageChanged': 'भाषा सफलतापूर्वक परिवर्तन भयो!',
    'privacy': 'गोपनीयता',
    'safety': 'सुरक्षा',
    'notifications': 'सूचनाहरू',
    'helpSupport': 'मद्दत र सहयोग',
    'termsOfService': 'सेवा सर्तहरू',
    'privacyPolicy': 'गोपनीयता नीति',
    'communityGuidelines': 'समुदाय दिशानिर्देश',

    // Misc
    'fillAllFields': 'कृपया सबै फिल्डहरू भर्नुहोस्',
    'blockUser': 'प्रयोगकर्तालाई ब्लक गर्नुहोस्',
    'blockUserConfirm': 'के तपाईं साँच्चै यस प्रयोगकर्तालाई ब्लक गर्न चाहनुहुन्छ? तपाईंहरू एक अर्कालाई देख्न सक्नुहुने छैन।',
    'userBlocked': 'ब्लक गरियो',
    'reportUser': 'प्रयोगकर्ताको रिपोर्ट गर्नुहोस्',
    'remaining': 'बाँकी',
    'noResults': 'कुनै नतिजा फेला परेन',
    'seeAll': 'सबै हेर्नुहोस्',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'bn', 'ta', 'ur', 'te', 'kn', 'ml', 'mr', 'gu', 'pa', 'or', 'ne'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
