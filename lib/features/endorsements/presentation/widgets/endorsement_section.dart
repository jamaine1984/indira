import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/endorsements/services/endorsement_service.dart';

class EndorsementSection extends StatefulWidget {
  final String userId;

  const EndorsementSection({super.key, required this.userId});

  @override
  State<EndorsementSection> createState() => _EndorsementSectionState();
}

class _EndorsementSectionState extends State<EndorsementSection> {
  final _service = EndorsementService();
  Map<String, int> _counts = {};
  bool _loading = true;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = FirebaseAuth.instance.currentUser?.uid == widget.userId;
    _loadEndorsements();
  }

  Future<void> _loadEndorsements() async {
    final counts = await _service.getEndorsementCounts(widget.userId);
    if (mounted) {
      setState(() {
        _counts = counts;
        _loading = false;
      });
    }
  }

  void _showEndorseDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Endorse This Person',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your endorsement is anonymous and helps build trust.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...EndorsementService.categories.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _service.submitEndorsement(
                      toUserId: widget.userId,
                      categoryId: cat['id']!,
                    );
                    await _loadEndorsements();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Endorsed as ${cat['label']}!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(cat['label']!, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                      ),
                      if ((_counts[cat['id']] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${_counts[cat['id']]}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final total = _counts.values.fold<int>(0, (a, b) => a + b);
    final topEndorsements = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Community Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (total > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRose.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$total', style: const TextStyle(color: AppTheme.primaryRose, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            if (!_isOwnProfile)
              TextButton.icon(
                onPressed: _showEndorseDialog,
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                label: const Text('Endorse'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRose),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (total == 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No endorsements yet. Be the first to vouch for this person!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topEndorsements.take(6).map((entry) {
              final cat = EndorsementService.categories.firstWhere(
                (c) => c['id'] == entry.key,
                orElse: () => {'emoji': '\u{2B50}', 'label': entry.key},
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRose.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryRose.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['emoji']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(cat['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Text('${entry.value}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
