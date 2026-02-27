import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';
import 'package:indira_love/features/kundli/services/kundli_service.dart';

class KundliScreen extends StatefulWidget {
  final String? otherUserId;

  const KundliScreen({super.key, this.otherUserId});

  @override
  State<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends State<KundliScreen> {
  final _service = KundliService();
  String? _myNakshatra;
  String? _myRashi;
  bool? _myManglik;
  String? _theirNakshatra;
  String? _theirRashi;
  bool? _theirManglik;
  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadMyData();
  }

  Future<void> _loadMyData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = await _service.getUserAstroData(uid);
    if (data != null && mounted) {
      setState(() {
        _myNakshatra = data['nakshatra'];
        _myRashi = data['rashi'];
        _myManglik = data['manglik'];
      });
    }

    // If comparing with another user, load their data too
    if (widget.otherUserId != null) {
      final otherData = await _service.getUserAstroData(widget.otherUserId!);
      if (otherData != null && mounted) {
        setState(() {
          _theirNakshatra = otherData['nakshatra'];
          _theirRashi = otherData['rashi'];
          _theirManglik = otherData['manglik'];
        });
        // Auto-calculate if both have data
        if (_myNakshatra != null && _theirNakshatra != null) {
          _calculate();
        }
      }
    }

    if (mounted) setState(() => _loadingProfile = false);
  }

  void _calculate() {
    if (_myNakshatra == null || _theirNakshatra == null) {
      AppSnackBar.info(context, AppLocalizations.of(context).fillAllFields);
      return;
    }

    setState(() => _loading = true);
    final result = _service.calculateCompatibility(
      nakshatra1: _myNakshatra!,
      nakshatra2: _theirNakshatra!,
      rashi1: _myRashi,
      rashi2: _theirRashi,
      manglik1: _myManglik,
      manglik2: _theirManglik,
    );
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: _loadingProfile
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          ),
                          Expanded(
                            child: Text(
                              l10n.kundliMatch,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Text('\u{2728}', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.kundliDescription,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter', height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Your Nakshatra
                      Text(l10n.yourNakshatra, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _myNakshatra,
                        items: KundliService.nakshatras,
                        hint: 'Select your nakshatra',
                        onChanged: (v) => setState(() => _myNakshatra = v),
                      ),
                      const SizedBox(height: 16),

                      // Your Rashi (optional)
                      Text('${l10n.yourRashi} (optional)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _myRashi,
                        items: KundliService.rashis,
                        hint: 'Auto-calculated from nakshatra',
                        onChanged: (v) => setState(() => _myRashi = v),
                      ),
                      const SizedBox(height: 16),

                      // Their Nakshatra
                      Text(l10n.partnerNakshatra, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _theirNakshatra,
                        items: KundliService.nakshatras,
                        hint: "Select partner's nakshatra",
                        onChanged: (v) => setState(() => _theirNakshatra = v),
                      ),
                      const SizedBox(height: 16),

                      // Their Rashi (optional)
                      Text('${l10n.partnerRashi} (optional)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _theirRashi,
                        items: KundliService.rashis,
                        hint: 'Auto-calculated from nakshatra',
                        onChanged: (v) => setState(() => _theirRashi = v),
                      ),
                      const SizedBox(height: 24),

                      // Manglik checkboxes
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              value: _myManglik ?? false,
                              onChanged: (v) => setState(() => _myManglik = v),
                              title: Text('I am ${l10n.manglik}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                              activeColor: AppTheme.accentGold,
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              value: _theirManglik ?? false,
                              onChanged: (v) => setState(() => _theirManglik = v),
                              title: Text('Partner ${l10n.manglik}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                              activeColor: AppTheme.accentGold,
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Calculate Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _calculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGold,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(l10n.calculateCompatibility, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                        ),
                      ),

                      // Results
                      if (_result != null) ...[
                        const SizedBox(height: 32),
                        _buildResultsCard(),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          isExpanded: true,
          dropdownColor: AppTheme.secondaryPlum,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final total = (_result!['totalScore'] as num).toDouble();
    final percentage = _result!['percentage'] as int;
    final verdict = _result!['verdict'] as String;
    final details = _result!['details'] as Map<String, dynamic>;
    final manglikNote = _result!['manglikNote'] as String;

    Color verdictColor;
    String verdictEmoji;
    if (percentage >= 75) {
      verdictColor = Colors.green;
      verdictEmoji = '\u{1F49A}';
    } else if (percentage >= 50) {
      verdictColor = Colors.blue;
      verdictEmoji = '\u{1F499}';
    } else if (percentage >= 33) {
      verdictColor = Colors.orange;
      verdictEmoji = '\u{1F9E1}';
    } else {
      verdictColor = Colors.red;
      verdictEmoji = '\u{2764}\u{FE0F}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: verdictColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          // Score Circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [verdictColor, verdictColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${total.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const Text('/36', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('$verdictEmoji $verdict', style: TextStyle(color: verdictColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay')),
          Text('$percentage% ${AppLocalizations.of(context).compatibility}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          if (manglikNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(manglikNote, style: const TextStyle(color: Colors.amber, fontSize: 13, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),

          // Detailed breakdown
          ...details.entries.map((entry) {
            final detail = entry.value as Map<String, dynamic>;
            final score = (detail['score'] as num).toDouble();
            final max = (detail['max'] as num).toDouble();
            final desc = detail['desc'] as String;
            final pct = max > 0 ? score / max : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('${score.toStringAsFixed(1)}/${max.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(pct > 0.6 ? Colors.green : (pct > 0.3 ? Colors.orange : Colors.red)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
