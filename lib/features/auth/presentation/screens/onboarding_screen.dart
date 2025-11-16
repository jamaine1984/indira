import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:indira_love/core/services/auth_service.dart';
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
  final _locationController = TextEditingController();
  String _gender = '';
  final List<String> _interests = [];

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
    _locationController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickAdditionalImage() async {
    if (_additionalImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 additional images allowed')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  void _nextPage() {
    if (_currentPage < 4) {
      // Validate current page
      if (_currentPage == 0 && !_validateBasicInfo()) return;
      if (_currentPage == 1 && _mainImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a main profile photo')),
        );
        return;
      }
      if (_currentPage == 2 && _interests.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least 3 interests')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your age')),
      );
      return false;
    }
    final age = int.tryParse(_ageController.text) ?? 0;
    if (age < 18 || age > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age must be between 18 and 99')),
      );
      return false;
    }
    if (_gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return false;
    }
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your location')),
      );
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
        'location': _locationController.text,
        'bio': _bioController.text,
        'interests': _interests,
        'photos': photoUrls,
        'profileComplete': true,
      });

      if (mounted) {
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    5,
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
                          child: const Text(
                            'Back',
                            style: TextStyle(
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
                                _currentPage == 4 ? 'Complete Profile' : 'Next',
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

          // Location
          TextFormField(
            controller: _locationController,
            style: const TextStyle(color: AppTheme.textCharcoal, fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Location (City, Country)',
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              labelStyle: TextStyle(color: AppTheme.secondaryPlum.withOpacity(0.8)),
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
                    color: isSelected ? AppTheme.secondaryPlum : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                checkmarkColor: AppTheme.secondaryPlum,
                side: BorderSide(color: Colors.white, width: isSelected ? 2 : 1),
                onSelected: (selected) {
                  setState(() {
                    if (selected && _interests.length < 5) {
                      _interests.add(interest);
                    } else if (!selected) {
                      _interests.remove(interest);
                    } else if (_interests.length >= 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Maximum 5 interests allowed')),
                      );
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
                _buildReviewItem('Location', _locationController.text),
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
