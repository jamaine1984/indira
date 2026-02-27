import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';
import 'package:indira_love/features/safety/services/safety_checkin_service.dart';

class SafetyCheckinScreen extends StatefulWidget {
  const SafetyCheckinScreen({super.key});

  @override
  State<SafetyCheckinScreen> createState() => _SafetyCheckinScreenState();
}

class _SafetyCheckinScreenState extends State<SafetyCheckinScreen> {
  final _service = SafetyCheckinService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  int _durationMinutes = 60;
  bool _creating = false;
  Map<String, dynamic>? _activeCheckin;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveCheckin();
  }

  Future<void> _loadActiveCheckin() async {
    final checkin = await _service.getActiveCheckin();
    if (!mounted) return;
    if (checkin != null) {
      final expectedEnd = (checkin['expectedEndTime'] as dynamic)?.toDate();
      if (expectedEnd != null) {
        final remaining = expectedEnd.difference(DateTime.now()).inSeconds;
        setState(() {
          _activeCheckin = checkin;
          _remainingSeconds = remaining > 0 ? remaining : 0;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          t.cancel();
        }
      });
    });
  }

  Future<void> _createCheckin() async {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _locationController.text.isEmpty) {
      AppSnackBar.info(context, l10n.fillAllFields);
      return;
    }
    setState(() => _creating = true);
    try {
      await _service.createCheckin(
        trustedContactName: _nameController.text.trim(),
        trustedContactPhone: _phoneController.text.trim(),
        dateLocation: _locationController.text.trim(),
        durationMinutes: _durationMinutes,
      );
      await _loadActiveCheckin();
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '${AppLocalizations.of(context).error}: $e');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeCheckin != null) {
      return _buildActiveCheckinView();
    }
    return _buildCreateView();
  }

  Widget _buildCreateView() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Text(
                      l10n.safetyCheckin,
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay', fontSize: 24,
                        fontWeight: FontWeight.bold, color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    l10n.safetyDescription,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),
                _buildField(l10n.trustedContactName, _nameController, Icons.person),
                _buildField(l10n.theirPhoneNumber, _phoneController, Icons.phone, keyboard: TextInputType.phone),
                _buildField(l10n.dateLocation, _locationController, Icons.location_on),
                const SizedBox(height: 16),
                Text(l10n.duration, style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [30, 60, 90, 120, 180].map((m) {
                    final selected = _durationMinutes == m;
                    return ChoiceChip(
                      label: Text('${m >= 60 ? '${m ~/ 60}h' : '${m}m'}${m > 60 && m % 60 > 0 ? ' ${m % 60}m' : ''}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _durationMinutes = m),
                      selectedColor: AppTheme.secondaryPlum,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _creating ? null : _createCheckin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.secondaryPlum,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _creating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.startCheckin, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCheckinView() {
    final l10n = AppLocalizations.of(context);
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    final expired = _remainingSeconds <= 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    expired ? Icons.warning : Icons.shield,
                    size: 80,
                    color: expired ? Colors.red : Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    expired ? l10n.timesUp : l10n.checkinActive,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay', fontSize: 28,
                      fontWeight: FontWeight.bold, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    expired
                        ? 'Your trusted contact will be alerted.'
                        : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} remaining',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeCheckin?['dateLocation'] ?? '',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _service.markSafe(_activeCheckin!['id']);
                        if (!mounted) return;
                        setState(() { _activeCheckin = null; _timer?.cancel(); });
                        AppSnackBar.success(context, l10n.markedSafe);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: Text(l10n.imSafe, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _service.triggerSOS(_activeCheckin!['id']);
                        if (!mounted) return;
                        AppSnackBar.error(context, l10n.sosAlertSent);
                      },
                      icon: const Icon(Icons.sos),
                      label: Text(l10n.sosAlert, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(l10n.back, style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
