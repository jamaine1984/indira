import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/models/cultural_preferences.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/logger_service.dart';

class CulturalPreferencesScreen extends ConsumerStatefulWidget {
  const CulturalPreferencesScreen({super.key});

  @override
  ConsumerState<CulturalPreferencesScreen> createState() =>
      _CulturalPreferencesScreenState();
}

class _CulturalPreferencesScreenState
    extends ConsumerState<CulturalPreferencesScreen> {
  // Basic Info
  String? _religion;
  String? _religiousPractice;
  String? _motherTongue;
  String? _community;

  // Dietary
  String? _dietType;
  String? _alcohol;
  String? _smoking;

  // Family
  String? _familyType;
  String? _familyValues;
  String? _marriageTimeline;
  String? _livingWith;

  // Education & Career
  String? _educationLevel;
  String? _educationField;
  String? _profession;
  String? _incomeRange;

  // Location
  String? _hometown;
  String? _currentCity;
  String? _state;
  bool _isNRI = false;
  bool _willingToRelocate = false;

  // Astrology
  DateTime? _birthDateTime;
  String? _zodiacSign;
  String? _nakshatra;
  bool? _manglik;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  Future<void> _loadExistingPreferences() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['culturalPreferences'] != null) {
        final prefs =
            CulturalPreferences.fromMap(doc.data()!['culturalPreferences']);

        setState(() {
          _religion = prefs.religion;
          _religiousPractice = prefs.religiousPractice;
          _motherTongue = prefs.motherTongue;
          _community = prefs.community;
          _dietType = prefs.dietType;
          _alcohol = prefs.alcohol;
          _smoking = prefs.smoking;
          _familyType = prefs.familyType;
          _familyValues = prefs.familyValues;
          _marriageTimeline = prefs.marriageTimeline;
          _livingWith = prefs.livingWith;
          _educationLevel = prefs.educationLevel;
          _educationField = prefs.educationField;
          _profession = prefs.profession;
          _incomeRange = prefs.incomeRange;
          _hometown = prefs.hometown;
          _currentCity = prefs.currentCity;
          _state = prefs.state;
          _isNRI = prefs.isNRI ?? false;
          _willingToRelocate = prefs.willingToRelocate ?? false;
          _birthDateTime = prefs.birthDateTime;
          _zodiacSign = prefs.zodiacSign;
          _nakshatra = prefs.nakshatra;
          _manglik = prefs.manglik;
        });
      }
    } catch (e) {
      logger.error('Error loading cultural preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final preferences = CulturalPreferences(
        religion: _religion,
        religiousPractice: _religiousPractice,
        motherTongue: _motherTongue,
        community: _community,
        dietType: _dietType,
        alcohol: _alcohol,
        smoking: _smoking,
        familyType: _familyType,
        familyValues: _familyValues,
        marriageTimeline: _marriageTimeline,
        livingWith: _livingWith,
        educationLevel: _educationLevel,
        educationField: _educationField,
        profession: _profession,
        incomeRange: _incomeRange,
        hometown: _hometown,
        currentCity: _currentCity,
        state: _state,
        isNRI: _isNRI,
        willingToRelocate: _willingToRelocate,
        birthDateTime: _birthDateTime,
        zodiacSign: _zodiacSign,
        nakshatra: _nakshatra,
        manglik: _manglik,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'culturalPreferences': preferences.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      logger.error('Error saving cultural preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRose,
        title: const Text(
          'Cultural & Lifestyle',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Religious & Cultural Section
                  _buildSectionHeader('Religious & Cultural', Icons.temple_hindu),
                  _buildDropdownField(
                    'Religion',
                    _religion,
                    CulturalOptions.religions,
                    (value) => setState(() => _religion = value),
                    Icons.favorite,
                  ),
                  if (_religion != null && _religion != 'No Religion')
                    _buildDropdownField(
                      'How Religious?',
                      _religiousPractice,
                      CulturalOptions.religiousPractice,
                      (value) => setState(() => _religiousPractice = value),
                      Icons.stars,
                    ),
                  _buildDropdownField(
                    'Mother Tongue',
                    _motherTongue,
                    CulturalOptions.motherTongues,
                    (value) => setState(() => _motherTongue = value),
                    Icons.language,
                  ),
                  _buildTextField(
                    'Community/Caste (Optional)',
                    _community,
                    (value) => setState(() => _community = value),
                    Icons.groups,
                  ),

                  const SizedBox(height: 24),

                  // Dietary & Lifestyle Section
                  _buildSectionHeader('Dietary & Lifestyle', Icons.restaurant),
                  _buildDropdownField(
                    'Diet',
                    _dietType,
                    CulturalOptions.dietTypes,
                    (value) => setState(() => _dietType = value),
                    Icons.restaurant_menu,
                  ),
                  _buildDropdownField(
                    'Alcohol',
                    _alcohol,
                    CulturalOptions.alcoholOptions,
                    (value) => setState(() => _alcohol = value),
                    Icons.local_bar,
                  ),
                  _buildDropdownField(
                    'Smoking',
                    _smoking,
                    CulturalOptions.smokingOptions,
                    (value) => setState(() => _smoking = value),
                    Icons.smoking_rooms,
                  ),

                  const SizedBox(height: 24),

                  // Family & Marriage Section
                  _buildSectionHeader('Family & Marriage', Icons.family_restroom),
                  _buildDropdownField(
                    'Family Type',
                    _familyType,
                    CulturalOptions.familyTypes,
                    (value) => setState(() => _familyType = value),
                    Icons.home,
                  ),
                  _buildDropdownField(
                    'Family Values',
                    _familyValues,
                    CulturalOptions.familyValues,
                    (value) => setState(() => _familyValues = value),
                    Icons.favorite_border,
                  ),
                  _buildDropdownField(
                    'When to Get Married?',
                    _marriageTimeline,
                    CulturalOptions.marriageTimelines,
                    (value) => setState(() => _marriageTimeline = value),
                    Icons.access_time,
                  ),
                  _buildDropdownField(
                    'Living With',
                    _livingWith,
                    CulturalOptions.livingWith,
                    (value) => setState(() => _livingWith = value),
                    Icons.house,
                  ),

                  const SizedBox(height: 24),

                  // Education & Career Section
                  _buildSectionHeader('Education & Career', Icons.school),
                  _buildDropdownField(
                    'Education Level',
                    _educationLevel,
                    CulturalOptions.educationLevels,
                    (value) => setState(() => _educationLevel = value),
                    Icons.school,
                  ),
                  if (_educationLevel != null)
                    _buildDropdownField(
                      'Field of Study',
                      _educationField,
                      CulturalOptions.educationFields,
                      (value) => setState(() => _educationField = value),
                      Icons.book,
                    ),
                  _buildDropdownField(
                    'Profession',
                    _profession,
                    CulturalOptions.professions,
                    (value) => setState(() => _profession = value),
                    Icons.work,
                  ),
                  _buildDropdownField(
                    'Income Range',
                    _incomeRange,
                    CulturalOptions.incomeRanges,
                    (value) => setState(() => _incomeRange = value),
                    Icons.attach_money,
                  ),

                  const SizedBox(height: 24),

                  // Location Section
                  _buildSectionHeader('Location', Icons.location_on),
                  _buildTextField(
                    'Hometown',
                    _hometown,
                    (value) => setState(() => _hometown = value),
                    Icons.home,
                  ),
                  _buildTextField(
                    'Current City',
                    _currentCity,
                    (value) => setState(() => _currentCity = value),
                    Icons.location_city,
                  ),
                  _buildDropdownField(
                    'State',
                    _state,
                    CulturalOptions.indianStates,
                    (value) => setState(() => _state = value),
                    Icons.map,
                  ),
                  SwitchListTile(
                    title: const Text('Are you an NRI?'),
                    subtitle: const Text('Non-Resident Indian'),
                    value: _isNRI,
                    onChanged: (value) => setState(() => _isNRI = value),
                    activeColor: AppTheme.primaryRose,
                  ),
                  SwitchListTile(
                    title: const Text('Willing to Relocate?'),
                    subtitle: const Text('For the right person'),
                    value: _willingToRelocate,
                    onChanged: (value) => setState(() => _willingToRelocate = value),
                    activeColor: AppTheme.primaryRose,
                  ),

                  const SizedBox(height: 24),

                  // Astrology Section
                  _buildSectionHeader('Astrology (Optional)', Icons.auto_awesome),
                  ListTile(
                    leading: const Icon(Icons.cake, color: AppTheme.primaryRose),
                    title: const Text('Birth Date & Time'),
                    subtitle: Text(
                      _birthDateTime != null
                          ? '${_birthDateTime!.day}/${_birthDateTime!.month}/${_birthDateTime!.year} ${_birthDateTime!.hour}:${_birthDateTime!.minute.toString().padLeft(2, '0')}'
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _birthDateTime ?? DateTime(1995),
                        firstDate: DateTime(1950),
                        lastDate: DateTime(2006),
                      );
                      if (date != null && mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              _birthDateTime ?? DateTime.now()),
                        );
                        if (time != null && mounted) {
                          setState(() {
                            _birthDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  _buildDropdownField(
                    'Zodiac Sign (Rashi)',
                    _zodiacSign,
                    CulturalOptions.zodiacSigns,
                    (value) => setState(() => _zodiacSign = value),
                    Icons.star,
                  ),
                  _buildDropdownField(
                    'Nakshatra',
                    _nakshatra,
                    CulturalOptions.nakshatras,
                    (value) => setState(() => _nakshatra = value),
                    Icons.star_border,
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: const Text('Manglik Status'),
                      subtitle: const Text('Important for horoscope matching'),
                      trailing: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _manglik == null
                              ? Colors.grey
                              : _manglik!
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(
                          _manglik == null
                              ? 'Not Sure'
                              : _manglik!
                                  ? 'Yes'
                                  : 'No',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => CupertinoActionSheet(
                            title: const Text('Are you Manglik?'),
                            actions: [
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  setState(() => _manglik = true);
                                  Navigator.pop(context);
                                },
                                child: const Text('Yes'),
                              ),
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  setState(() => _manglik = false);
                                  Navigator.pop(context);
                                },
                                child: const Text('No'),
                              ),
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  setState(() => _manglik = null);
                                  Navigator.pop(context);
                                },
                                child: const Text('Not Sure'),
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              isDestructiveAction: true,
                              child: const Text('Cancel'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryRose, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            icon: Icon(icon, color: AppTheme.primaryRose),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String? value,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            icon: Icon(icon, color: AppTheme.primaryRose),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}