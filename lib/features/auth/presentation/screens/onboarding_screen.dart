import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/cultural_preferences.dart';
import 'package:indira_love/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';
import 'package:indira_love/features/kundli/services/kundli_service.dart';
import 'dart:io';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedCountry = '';
  String _gender = '';
  String _lookingFor = ''; // Gender preference for matching
  final List<String> _interests = [];

  // Cultural Preferences
  String? _religion;
  String? _dietType;
  String? _motherTongue = 'English';
  String? _marriageTimeline;
  String? _state = 'Delhi';

  // Vedic Astrology (Kundli) - Centerpiece Feature
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  String? _nakshatra;
  String? _rashi;
  bool _isManglik = false;
  bool _knowsVedicDetails = true;

  // Popular countries list
  final List<String> _countries = [
    'United States', 'Canada', 'United Kingdom', 'Australia', 'Germany',
    'France', 'Spain', 'Italy', 'Netherlands', 'Belgium', 'Switzerland',
    'Austria', 'Sweden', 'Norway', 'Denmark', 'Finland', 'Ireland',
    'Poland', 'Czech Republic', 'Portugal', 'Greece', 'Japan', 'South Korea',
    'Singapore', 'New Zealand', 'Brazil', 'Mexico', 'Argentina', 'Chile',
    'India', 'Philippines', 'Thailand', 'Vietnam', 'Indonesia', 'Malaysia',
    'United Arab Emirates', 'Saudi Arabia', 'Israel', 'Turkey', 'Russia',
    'Ukraine', 'Romania', 'Hungary', 'Croatia', 'South Africa', 'Nigeria',
    'Kenya', 'Egypt', 'Morocco', 'Colombia', 'Peru', 'Venezuela'
  ];

  // Image uploads
  File? _mainImage;
  final List<File> _additionalImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _availableInterests = [
    'Travel', 'Music', 'Sports', 'Art', 'Food', 'Books',
    'Movies', 'Photography', 'Cooking', 'Dancing', 'Hiking', 'Yoga',
    'Technology', 'Fashion', 'Gaming', 'Pets', 'Nature', 'Fitness',
    'Reading', 'Coffee', 'Wine', 'Adventure', 'Beach', 'Mountains'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _mainImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> _pickAdditionalImage() async {
    if (_additionalImages.length >= 6) {
      AppSnackBar.info(context, 'Maximum 6 additional images allowed');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _additionalImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error picking image: $e');
      }
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  void _nextPage() {
    if (_currentPage < 6) {
      // Validate current page
      if (_currentPage == 0 && !_validateBasicInfo()) return;
      if (_currentPage == 1 && _mainImage == null) {
        AppSnackBar.info(context, 'Please upload a main profile photo');
        return;
      }
      if (_currentPage == 2) {
        // Cultural preferences are optional, just proceed
      }
      if (_currentPage == 3) {
        // Vedic astrology - encourage but don't force
      }
      if (_currentPage == 4 && _interests.length < 3) {
        AppSnackBar.info(context, 'Please select at least 3 interests');
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  bool _validateBasicInfo() {
    if (_ageController.text.isEmpty) {
      AppSnackBar.info(context, 'Please enter your age');
      return false;
    }
    final age = int.tryParse(_ageController.text) ?? 0;
    if (age < 18 || age > 99) {
      AppSnackBar.info(context, 'Age must be between 18 and 99');
      return false;
    }
    if (_gender.isEmpty) {
      AppSnackBar.info(context, 'Please select your gender');
      return false;
    }
    if (_lookingFor.isEmpty) {
      AppSnackBar.info(context, 'Please select who you are looking for');
      return false;
    }
    if (_selectedCountry.isEmpty) {
      AppSnackBar.info(context, 'Please select your country');
      return false;
    }
    return true;
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final age = int.tryParse(_ageController.text) ?? 0;
      final user = AuthService().currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload images to Firebase Storage
      final List<String> photoUrls = [];

      // Upload main image
      if (_mainImage != null) {
        final mainFileName = '${user.uid}_main_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final mainRef = FirebaseStorage.instance.ref('user_photos/$mainFileName');
        await mainRef.putFile(_mainImage!);
        final mainUrl = await mainRef.getDownloadURL();
        photoUrls.add(mainUrl);
      }

      // Upload additional images
      for (int i = 0; i < _additionalImages.length; i++) {
        final fileName = '${user.uid}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref('user_photos/$fileName');
        await ref.putFile(_additionalImages[i]);
        final url = await ref.getDownloadURL();
        photoUrls.add(url);
      }

      await ref.read(authProvider.notifier).updateUserProfile({
        'age': age,
        'gender': _gender,
        'lookingFor': _lookingFor, // Gender preference for matching
        'location': _selectedCountry,
        'bio': _bioController.text,
        'interests': _interests,
        'photos': photoUrls,
        'profileComplete': true,
        'culturalPreferences': {
          'religion': _religion,
          'dietType': _dietType,
          'motherTongue': _motherTongue,
          'marriageTimeline': _marriageTimeline,
          'state': _state,
          'currentCity': _selectedCountry,
          'birthDate': _birthDate?.toIso8601String(),
          'birthTime': _birthTime != null ? '${_birthTime!.hour}:${_birthTime!.minute.toString().padLeft(2, '0')}' : null,
          'nakshatra': _nakshatra,
          'rashi': _rashi,
          'manglik': _isManglik,
        },
      });

      if (mounted) {
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: List.generate(
                    7,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBasicInfoPage(),
                    _buildPhotoUploadPage(),
                    _buildCulturalPreferencesPage(),
                    _buildVedicAstrologyPage(),
                    _buildInterestsPage(),
                    _buildBioPage(),
                    _buildReviewPage(),
                  ],
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _previousPage,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: Text(
                            l10n.back,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _currentPage == 6 ? l10n.done : l10n.next,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Age
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textCharcoal, fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Age',
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              labelStyle: TextStyle(color: AppTheme.secondaryPlum.withOpacity(0.8)),
              prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.secondaryPlum),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryRose, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Gender
          const Text(
            'Gender',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGenderButton('Male'),
              const SizedBox(width: 12),
              _buildGenderButton('Female'),
              const SizedBox(width: 12),
              _buildGenderButton('Other'),
            ],
          ),

          const SizedBox(height: 24),

          // Looking For (Gender Preference)
          const Text(
            'Looking For',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLookingForButton('Male'),
              const SizedBox(width: 12),
              _buildLookingForButton('Female'),
              const SizedBox(width: 12),
              _buildLookingForButton('Everyone'),
            ],
          ),

          const SizedBox(height: 24),

          // Location - Country Dropdown
          const Text(
            'Country',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCountry.isEmpty ? null : _selectedCountry,
            isExpanded: true,
            style: const TextStyle(color: AppTheme.textCharcoal, fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              prefixIcon: const Icon(Icons.location_on, color: AppTheme.secondaryPlum),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryRose, width: 2),
              ),
            ),
            hint: Text(
              'Select your country',
              style: TextStyle(color: AppTheme.textCharcoal.withOpacity(0.5)),
            ),
            items: _countries.map((country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(country),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = _gender == gender;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _gender = gender),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isSelected ? Colors.white : Colors.white70,
            width: isSelected ? 3 : 2,
          ),
          backgroundColor: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          gender,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLookingForButton(String preference) {
    final isSelected = _lookingFor == preference;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _lookingFor = preference),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isSelected ? Colors.white : Colors.white70,
            width: isSelected ? 3 : 2,
          ),
          backgroundColor: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          preference,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Your Photos',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload 1 main photo and up to 6 additional photos',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Main Photo
          const Text(
            'Main Profile Photo *',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickMainImage,
            child: Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
                image: _mainImage != null
                    ? DecorationImage(
                        image: FileImage(_mainImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _mainImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 64, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to upload main photo',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 32),

          // Additional Photos
          const Text(
            'Additional Photos (up to 6)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 7, // 6 slots + 1 add button
            itemBuilder: (context, index) {
              if (index < _additionalImages.length) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_additionalImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeAdditionalImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              } else if (index == _additionalImages.length && _additionalImages.length < 6) {
                return GestureDetector(
                  onTap: _pickAdditionalImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2, style: BorderStyle.solid),
                    ),
                    child: Icon(Icons.add, size: 40, color: Colors.white.withOpacity(0.7)),
                  ),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cultural & Lifestyle',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us find your perfect match',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Religion
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonFormField<String>(
              value: _religion,
              decoration: const InputDecoration(
                labelText: 'Religion',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: CulturalOptions.religions.map((religion) {
                return DropdownMenuItem(
                  value: religion,
                  child: Text(religion),
                );
              }).toList(),
              onChanged: (value) => setState(() => _religion = value),
            ),
          ),
          const SizedBox(height: 16),

          // Diet
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonFormField<String>(
              value: _dietType,
              decoration: const InputDecoration(
                labelText: 'Diet Preference',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: CulturalOptions.dietTypes.map((diet) {
                return DropdownMenuItem(
                  value: diet,
                  child: Text(diet),
                );
              }).toList(),
              onChanged: (value) => setState(() => _dietType = value),
            ),
          ),
          const SizedBox(height: 16),

          // Mother Tongue
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonFormField<String>(
              value: _motherTongue,
              decoration: const InputDecoration(
                labelText: 'Mother Tongue',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: CulturalOptions.motherTongues.take(10).map((language) {
                return DropdownMenuItem(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (value) => setState(() => _motherTongue = value),
            ),
          ),
          const SizedBox(height: 16),

          // Marriage Timeline
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonFormField<String>(
              value: _marriageTimeline,
              decoration: const InputDecoration(
                labelText: 'When to Get Married?',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: CulturalOptions.marriageTimelines.map((timeline) {
                return DropdownMenuItem(
                  value: timeline,
                  child: Text(timeline),
                );
              }).toList(),
              onChanged: (value) => setState(() => _marriageTimeline = value),
            ),
          ),
          const SizedBox(height: 16),

          // State
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonFormField<String>(
              value: _state,
              decoration: const InputDecoration(
                labelText: 'State/Location',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: CulturalOptions.indianStates.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) => setState(() => _state = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVedicAstrologyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Om symbol
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('🕉️', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vedic Kundli Profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Find your cosmic match with Gun Milan',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Unique feature callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withOpacity(0.2),
                  const Color(0xFFFF8E53).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF8E53).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Indira uses the ancient 36-point Gun Milan system to find your most compatible matches based on Vedic astrology.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Toggle: Do you know your Vedic details?
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'I know my Nakshatra & Rashi',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _knowsVedicDetails,
                  onChanged: (val) => setState(() => _knowsVedicDetails = val),
                  activeColor: const Color(0xFFFF6B35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Birth Date
          const Text(
            'Date of Birth',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthDate ?? DateTime(1995, 1, 1),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFFF6B35),
                        surface: Color(0xFF2D1B4E),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _birthDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 12),
                  Text(
                    _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Select your birth date',
                    style: TextStyle(
                      color: _birthDate != null ? AppTheme.textCharcoal : AppTheme.textCharcoal.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Birth Time
          const Text(
            'Time of Birth (for accurate Kundli)',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _birthTime ?? const TimeOfDay(hour: 6, minute: 0),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFFF6B35),
                        surface: Color(0xFF2D1B4E),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _birthTime = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 12),
                  Text(
                    _birthTime != null
                        ? _birthTime!.format(context)
                        : 'Select your birth time',
                    style: TextStyle(
                      color: _birthTime != null ? AppTheme.textCharcoal : AppTheme.textCharcoal.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_knowsVedicDetails) ...[
            // Nakshatra Dropdown
            const Text(
              'Nakshatra (Birth Star) ☾',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _nakshatra,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.auto_awesome, color: Color(0xFFFF6B35)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                hint: Text(
                  'Select your Nakshatra',
                  style: TextStyle(color: AppTheme.textCharcoal.withOpacity(0.5)),
                ),
                items: CulturalOptions.nakshatras.map((n) {
                  return DropdownMenuItem(value: n, child: Text(n));
                }).toList(),
                onChanged: (value) => setState(() => _nakshatra = value),
              ),
            ),
            const SizedBox(height: 16),

            // Rashi Dropdown
            const Text(
              'Rashi (Moon Sign) ♈',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _rashi,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.auto_awesome, color: Color(0xFFFF6B35)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                hint: Text(
                  'Select your Rashi',
                  style: TextStyle(color: AppTheme.textCharcoal.withOpacity(0.5)),
                ),
                items: CulturalOptions.zodiacSigns.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r));
                }).toList(),
                onChanged: (value) => setState(() => _rashi = value),
              ),
            ),
            const SizedBox(height: 16),

            // Manglik Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.brightness_5, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Are you Manglik?',
                      style: TextStyle(
                        color: AppTheme.textCharcoal,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isManglik,
                    onChanged: (val) => setState(() => _isManglik = val),
                    activeColor: const Color(0xFFFF6B35),
                  ),
                ],
              ),
            ),
          ],

          if (!_knowsVedicDetails) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'No worries! Enter your birth date and time above, and you can update your Nakshatra and Rashi later from your profile settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 8 Factors preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gun Milan: 8 Factors of Compatibility',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildFactorChip('Varna', '1pt'),
                    _buildFactorChip('Vashya', '2pt'),
                    _buildFactorChip('Tara', '3pt'),
                    _buildFactorChip('Yoni', '4pt'),
                    _buildFactorChip('Graha Maitri', '5pt'),
                    _buildFactorChip('Gana', '6pt'),
                    _buildFactorChip('Bhakut', '7pt'),
                    _buildFactorChip('Nadi', '8pt'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: 36 points — 18+ is a good match!',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorChip(String name, String points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.3),
            const Color(0xFFFF8E53).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF8E53).withOpacity(0.4)),
      ),
      child: Text(
        '$name ($points)',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInterestsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your interests?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select 3-5 interests (${_interests.length} selected)',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableInterests.map((interest) {
              final isSelected = _interests.contains(interest);
              return FilterChip(
                label: Text(
                  interest,
                  style: TextStyle(
                    // Make unselected text much darker for visibility
                    color: isSelected ? AppTheme.secondaryPlum : const Color(0xFF2D2D2D),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.9),
                checkmarkColor: AppTheme.secondaryPlum,
                side: BorderSide(color: isSelected ? AppTheme.primaryRose : Colors.white70, width: isSelected ? 2 : 1),
                onSelected: (selected) {
                  setState(() {
                    if (selected && _interests.length < 5) {
                      _interests.add(interest);
                    } else if (!selected) {
                      _interests.remove(interest);
                    } else if (_interests.length >= 5) {
                      AppSnackBar.info(context, 'Maximum 5 interests allowed');
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBioPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write your bio',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tell potential matches about yourself',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _bioController,
            maxLines: 8,
            maxLength: 500,
            style: const TextStyle(color: AppTheme.textCharcoal, fontWeight: FontWeight.w500, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Tell us about yourself, your hobbies, what you\'re looking for...',
              hintStyle: TextStyle(color: AppTheme.textCharcoal.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryRose, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Profile',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewItem('Age', _ageController.text),
                _buildReviewItem('Gender', _gender),
                _buildReviewItem('Looking For', _lookingFor),
                _buildReviewItem('Country', _selectedCountry),
                if (_nakshatra != null) _buildReviewItem('Nakshatra', _nakshatra!),
                if (_rashi != null) _buildReviewItem('Rashi', _rashi!),
                if (_birthDate != null) _buildReviewItem('Birth Date', '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
                _buildReviewItem('Manglik', _isManglik ? 'Yes' : 'No'),
                _buildReviewItem('Interests', _interests.join(', ')),
                _buildReviewItem('Bio', _bioController.text),
                _buildReviewItem('Photos', '${_mainImage != null ? 1 : 0} main + ${_additionalImages.length} additional'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can edit your profile anytime from the menu',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'Not set' : value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
