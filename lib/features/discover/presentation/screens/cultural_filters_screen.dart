import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/models/cultural_preferences.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/discover/presentation/providers/discover_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CulturalFiltersScreen extends ConsumerStatefulWidget {
  const CulturalFiltersScreen({super.key});

  @override
  ConsumerState<CulturalFiltersScreen> createState() =>
      _CulturalFiltersScreenState();
}

class _CulturalFiltersScreenState extends ConsumerState<CulturalFiltersScreen> {
  // Filter preferences
  List<String> _selectedReligions = [];
  List<String> _selectedDietTypes = [];
  List<String> _selectedLanguages = [];
  List<String> _selectedEducationLevels = [];
  List<String> _selectedProfessions = [];

  String? _selectedMarriageTimeline;
  String? _selectedFamilyValues;
  String? _selectedState;

  bool _filterByManglik = false;
  bool? _manglikPreference;

  bool _filterBySmoking = false;
  String? _smokingPreference;

  bool _filterByAlcohol = false;
  String? _alcoholPreference;

  bool _showNRIOnly = false;
  bool _willingToRelocateOnly = false;

  // Age range
  RangeValues _ageRange = const RangeValues(21, 35);

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
  }

  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filtersJson = prefs.getString('cultural_filters');

    if (filtersJson != null) {
      final filters = json.decode(filtersJson);
      setState(() {
        _selectedReligions = List<String>.from(filters['religions'] ?? []);
        _selectedDietTypes = List<String>.from(filters['dietTypes'] ?? []);
        _selectedLanguages = List<String>.from(filters['languages'] ?? []);
        _selectedEducationLevels = List<String>.from(filters['educationLevels'] ?? []);
        _selectedProfessions = List<String>.from(filters['professions'] ?? []);

        _selectedMarriageTimeline = filters['marriageTimeline'];
        _selectedFamilyValues = filters['familyValues'];
        _selectedState = filters['state'];

        _filterByManglik = filters['filterByManglik'] ?? false;
        _manglikPreference = filters['manglikPreference'];

        _filterBySmoking = filters['filterBySmoking'] ?? false;
        _smokingPreference = filters['smokingPreference'];

        _filterByAlcohol = filters['filterByAlcohol'] ?? false;
        _alcoholPreference = filters['alcoholPreference'];

        _showNRIOnly = filters['showNRIOnly'] ?? false;
        _willingToRelocateOnly = filters['willingToRelocateOnly'] ?? false;

        if (filters['minAge'] != null && filters['maxAge'] != null) {
          _ageRange = RangeValues(
            filters['minAge'].toDouble(),
            filters['maxAge'].toDouble(),
          );
        }
      });
    }
  }

  Future<void> _saveAndApplyFilters() async {
    // Save filters to preferences
    final prefs = await SharedPreferences.getInstance();
    final filters = {
      'religions': _selectedReligions,
      'dietTypes': _selectedDietTypes,
      'languages': _selectedLanguages,
      'educationLevels': _selectedEducationLevels,
      'professions': _selectedProfessions,
      'marriageTimeline': _selectedMarriageTimeline,
      'familyValues': _selectedFamilyValues,
      'state': _selectedState,
      'filterByManglik': _filterByManglik,
      'manglikPreference': _manglikPreference,
      'filterBySmoking': _filterBySmoking,
      'smokingPreference': _smokingPreference,
      'filterByAlcohol': _filterByAlcohol,
      'alcoholPreference': _alcoholPreference,
      'showNRIOnly': _showNRIOnly,
      'willingToRelocateOnly': _willingToRelocateOnly,
      'minAge': _ageRange.start.toInt(),
      'maxAge': _ageRange.end.toInt(),
    };

    await prefs.setString('cultural_filters', json.encode(filters));

    // Apply filters to discover provider
    final discoverNotifier = ref.read(discoverProvider.notifier);
    await discoverNotifier.applyFilters(filters);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filters applied!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedReligions = [];
      _selectedDietTypes = [];
      _selectedLanguages = [];
      _selectedEducationLevels = [];
      _selectedProfessions = [];
      _selectedMarriageTimeline = null;
      _selectedFamilyValues = null;
      _selectedState = null;
      _filterByManglik = false;
      _manglikPreference = null;
      _filterBySmoking = false;
      _smokingPreference = null;
      _filterByAlcohol = false;
      _alcoholPreference = null;
      _showNRIOnly = false;
      _willingToRelocateOnly = false;
      _ageRange = const RangeValues(21, 35);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cultural_filters');

    final discoverNotifier = ref.read(discoverProvider.notifier);
    await discoverNotifier.clearFilters();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filters cleared!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRose,
        title: const Text(
          'Filter Matches',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'CLEAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Age Range
            _buildSectionHeader('Age Range'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_ageRange.start.toInt()} years'),
                        Text('${_ageRange.end.toInt()} years'),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 60,
                      divisions: 42,
                      activeColor: AppTheme.primaryRose,
                      labels: RangeLabels(
                        _ageRange.start.toInt().toString(),
                        _ageRange.end.toInt().toString(),
                      ),
                      onChanged: (values) {
                        setState(() => _ageRange = values);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Religion
            _buildSectionHeader('Religion'),
            _buildMultiSelectChips(
              CulturalOptions.religions,
              _selectedReligions,
              (religion) {
                setState(() {
                  if (_selectedReligions.contains(religion)) {
                    _selectedReligions.remove(religion);
                  } else {
                    _selectedReligions.add(religion);
                  }
                });
              },
            ),

            // Diet
            _buildSectionHeader('Diet'),
            _buildMultiSelectChips(
              CulturalOptions.dietTypes,
              _selectedDietTypes,
              (diet) {
                setState(() {
                  if (_selectedDietTypes.contains(diet)) {
                    _selectedDietTypes.remove(diet);
                  } else {
                    _selectedDietTypes.add(diet);
                  }
                });
              },
            ),

            // Languages
            _buildSectionHeader('Languages'),
            _buildMultiSelectChips(
              CulturalOptions.motherTongues.take(10).toList(),
              _selectedLanguages,
              (language) {
                setState(() {
                  if (_selectedLanguages.contains(language)) {
                    _selectedLanguages.remove(language);
                  } else {
                    _selectedLanguages.add(language);
                  }
                });
              },
            ),

            // Lifestyle
            _buildSectionHeader('Lifestyle'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Filter by Smoking'),
                    value: _filterBySmoking,
                    onChanged: (value) {
                      setState(() => _filterBySmoking = value);
                    },
                    activeColor: AppTheme.primaryRose,
                  ),
                  if (_filterBySmoking)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: _smokingPreference,
                        decoration: const InputDecoration(
                          labelText: 'Smoking Preference',
                        ),
                        items: CulturalOptions.smokingOptions
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _smokingPreference = value);
                        },
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Filter by Alcohol'),
                    value: _filterByAlcohol,
                    onChanged: (value) {
                      setState(() => _filterByAlcohol = value);
                    },
                    activeColor: AppTheme.primaryRose,
                  ),
                  if (_filterByAlcohol)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _alcoholPreference,
                        decoration: const InputDecoration(
                          labelText: 'Alcohol Preference',
                        ),
                        items: CulturalOptions.alcoholOptions
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _alcoholPreference = value);
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Marriage & Family
            _buildSectionHeader('Marriage & Family'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedMarriageTimeline,
                      decoration: const InputDecoration(
                        labelText: 'Marriage Timeline',
                      ),
                      items: CulturalOptions.marriageTimelines
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedMarriageTimeline = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFamilyValues,
                      decoration: const InputDecoration(
                        labelText: 'Family Values',
                      ),
                      items: CulturalOptions.familyValues
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedFamilyValues = value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Education
            _buildSectionHeader('Education'),
            _buildMultiSelectChips(
              CulturalOptions.educationLevels,
              _selectedEducationLevels,
              (education) {
                setState(() {
                  if (_selectedEducationLevels.contains(education)) {
                    _selectedEducationLevels.remove(education);
                  } else {
                    _selectedEducationLevels.add(education);
                  }
                });
              },
            ),

            // Location
            _buildSectionHeader('Location'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                      ),
                      items: CulturalOptions.indianStates
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedState = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Show NRI Only'),
                      subtitle: const Text('Non-Resident Indians'),
                      value: _showNRIOnly,
                      onChanged: (value) {
                        setState(() => _showNRIOnly = value);
                      },
                      activeColor: AppTheme.primaryRose,
                    ),
                    SwitchListTile(
                      title: const Text('Willing to Relocate'),
                      subtitle: const Text('Open to moving'),
                      value: _willingToRelocateOnly,
                      onChanged: (value) {
                        setState(() => _willingToRelocateOnly = value);
                      },
                      activeColor: AppTheme.primaryRose,
                    ),
                  ],
                ),
              ),
            ),

            // Astrology
            _buildSectionHeader('Astrology'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Filter by Manglik Status'),
                    value: _filterByManglik,
                    onChanged: (value) {
                      setState(() => _filterByManglik = value);
                    },
                    activeColor: AppTheme.primaryRose,
                  ),
                  if (_filterByManglik)
                    RadioListTile<bool?>(
                      title: const Text('Manglik Only'),
                      value: true,
                      groupValue: _manglikPreference,
                      onChanged: (value) {
                        setState(() => _manglikPreference = value);
                      },
                      activeColor: AppTheme.primaryRose,
                    ),
                  if (_filterByManglik)
                    RadioListTile<bool?>(
                      title: const Text('Non-Manglik Only'),
                      value: false,
                      groupValue: _manglikPreference,
                      onChanged: (value) {
                        setState(() => _manglikPreference = value);
                      },
                      activeColor: AppTheme.primaryRose,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Apply Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveAndApplyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textCharcoal,
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips(
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onToggle(option),
              selectedColor: AppTheme.primaryRose.withOpacity(0.3),
              checkmarkColor: AppTheme.primaryRose,
            );
          }).toList(),
        ),
      ),
    );
  }
}