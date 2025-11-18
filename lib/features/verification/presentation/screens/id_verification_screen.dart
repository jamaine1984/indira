import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/verification/services/verification_service.dart';
import 'package:indira_love/core/services/auth_service.dart';

class IdVerificationScreen extends ConsumerStatefulWidget {
  const IdVerificationScreen({super.key});

  @override
  ConsumerState<IdVerificationScreen> createState() =>
      _IdVerificationScreenState();
}

class _IdVerificationScreenState extends ConsumerState<IdVerificationScreen> {
  final VerificationService _verificationService = VerificationService();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  File? _selfieImage;
  File? _idFrontImage;
  File? _idBackImage;
  bool _isProcessing = false;
  String? _verificationStatus;
  bool _agreedToTerms = false;

  // Verification results
  Map<String, dynamic>? _selfieVerificationResult;
  Map<String, dynamic>? _idVerificationResult;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final status = await _verificationService.getVerificationStatus(user.uid);
      if (mounted) {
        setState(() {
          _verificationStatus = status;
        });
      }
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        setState(() {
          _isProcessing = true;
        });

        final imageFile = File(photo.path);

        // Verify selfie quality using ML Kit
        final result = await _verificationService.verifySelfie(imageFile);

        setState(() {
          _isProcessing = false;
          _selfieVerificationResult = result;
        });

        if (result['isValid'] == true) {
          setState(() {
            _selfieImage = imageFile;
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Selfie verified successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            _showErrorDialog(
              'Selfie Verification Failed',
              result['error'] ?? 'Please retake your selfie following the guidelines.',
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        _showErrorDialog('Error', 'Failed to take selfie: $e');
      }
    }
  }

  Future<void> _captureIdDocument(bool isFront) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        final imageFile = File(photo.path);

        setState(() {
          if (isFront) {
            _idFrontImage = imageFile;
          } else {
            _idBackImage = imageFile;
          }
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ID ${isFront ? "front" : "back"} captured successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Failed to capture ID: $e');
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_selfieImage == null || _idFrontImage == null) {
      _showErrorDialog('Missing Information', 'Please complete all required steps.');
      return;
    }

    if (!_agreedToTerms) {
      _showErrorDialog('Terms Required', 'Please agree to the terms and conditions.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Submit all verification documents
      final success = await _verificationService.submitFullVerification(
        selfie: _selfieImage!,
        idFront: _idFrontImage!,
        idBack: _idBackImage,
        verificationType: 'enhanced_id',
      );

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(
            'Submission Failed',
            'Failed to submit verification. Please try again.',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        _showErrorDialog('Error', 'Submission error: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Verification Submitted'),
          ],
        ),
        content: const Text(
          'Your verification documents have been submitted successfully!\n\n'
          'Our team will review them within 24-48 hours. You\'ll receive a notification once the review is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Flexible(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Progress Indicator
              _buildProgressIndicator(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),

              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ID Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStepTitle(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_verificationStatus == 'approved')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? Colors.white
                        : Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIntroductionStep();
      case 1:
        return _buildSelfieStep();
      case 2:
        return _buildIdDocumentStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroductionStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.security,
                    size: 64,
                    color: AppTheme.primaryRose,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Enhanced Verification',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get the verified badge and build trust with other users. Your information is encrypted and secure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRequirementItem(Icons.face, 'A clear selfie of your face'),
                  _buildRequirementItem(Icons.badge, 'Government-issued ID (front)'),
                  _buildRequirementItem(Icons.flip, 'ID back side (optional)'),
                  _buildRequirementItem(Icons.timer, '2-3 minutes to complete'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your documents are encrypted and only used for verification',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
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
        ],
      ),
    );
  }

  Widget _buildSelfieStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.camera_front,
                    size: 48,
                    color: AppTheme.primaryRose,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Take a Selfie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We\'ll use facial recognition to match your selfie with your ID',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Selfie Guidelines
                  _buildGuidelineItem(Icons.wb_sunny, 'Good lighting'),
                  _buildGuidelineItem(Icons.face, 'Face the camera directly'),
                  _buildGuidelineItem(Icons.remove_red_eye, 'Eyes clearly visible'),
                  _buildGuidelineItem(Icons.do_not_disturb_alt, 'No sunglasses or masks'),

                  const SizedBox(height: 24),

                  // Selfie Preview or Button
                  if (_selfieImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selfieImage!,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selfieVerificationResult != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Quality: ${(_selfieVerificationResult!['quality'] * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _takeSelfie,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake Selfie'),
                    ),
                  ] else
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _takeSelfie,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_isProcessing ? 'Processing...' : 'Take Selfie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdDocumentStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.badge,
                    size: 48,
                    color: AppTheme.primaryRose,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Photograph Your ID',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Take clear photos of your government-issued ID',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Accepted IDs
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accepted Documents:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildAcceptedIdItem('Driver\'s License'),
                        _buildAcceptedIdItem('Passport'),
                        _buildAcceptedIdItem('National ID Card'),
                        _buildAcceptedIdItem('State ID'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Front of ID
                  _buildIdCaptureSection(
                    title: 'Front of ID',
                    isRequired: true,
                    image: _idFrontImage,
                    onCapture: () => _captureIdDocument(true),
                  ),

                  const SizedBox(height: 16),

                  // Back of ID
                  _buildIdCaptureSection(
                    title: 'Back of ID',
                    isRequired: false,
                    image: _idBackImage,
                    onCapture: () => _captureIdDocument(false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.fact_check,
                    size: 48,
                    color: AppTheme.primaryRose,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Review & Submit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Review Items
                  _buildReviewItem(
                    'Selfie',
                    _selfieImage != null,
                    _selfieImage,
                  ),
                  _buildReviewItem(
                    'ID Front',
                    _idFrontImage != null,
                    _idFrontImage,
                  ),
                  if (_idBackImage != null)
                    _buildReviewItem(
                      'ID Back',
                      true,
                      _idBackImage,
                    ),

                  const SizedBox(height: 24),

                  // Terms and Conditions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          title: const Text(
                            'I agree to the terms and conditions',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'I confirm that all documents are genuine and belong to me. I understand that providing false information may result in account suspension.',
                            style: TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_agreedToTerms && !_isProcessing)
                          ? _submitVerification
                          : null,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isProcessing ? 'Submitting...' : 'Submit for Verification',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canProceed = _canProceedToNextStep();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          if (_currentStep < 3)
            Expanded(
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                        setState(() {
                          _currentStep++;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryRose,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Next'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryRose, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedIdItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildIdCaptureSection({
    required String title,
    required bool isRequired,
    File? image,
    required VoidCallback onCapture,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_a_photo, color: Colors.grey),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isRequired ? 'Required' : 'Optional',
                  style: TextStyle(
                    fontSize: 12,
                    color: isRequired ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCapture,
            child: Text(image != null ? 'Retake' : 'Capture'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String title, bool isComplete, File? image) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                image,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Icon(
            isComplete ? Icons.check_circle : Icons.error_outline,
            color: isComplete ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return true; // Introduction step
      case 1:
        return _selfieImage != null;
      case 2:
        return _idFrontImage != null;
      case 3:
        return _agreedToTerms;
      default:
        return false;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Introduction';
      case 1:
        return 'Step 1 of 3: Selfie';
      case 2:
        return 'Step 2 of 3: ID Document';
      case 3:
        return 'Step 3 of 3: Review & Submit';
      default:
        return '';
    }
  }
}