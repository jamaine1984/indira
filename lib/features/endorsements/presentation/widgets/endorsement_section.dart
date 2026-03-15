import 'dart:ui';
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

  void _showEndorseDialog() async {
    // Pre-load which categories are already endorsed by others and by current user
    final allEndorsed = await _service.getEndorsedCategoryIds(widget.userId);
    final myEndorsed = await _service.getMyEndorsedCategoryIds(widget.userId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _EndorseDialogContent(
        counts: _counts,
        allEndorsedCategoryIds: allEndorsed,
        myEndorsedCategoryIds: myEndorsed,
        onSubmit: (selectedIds) async {
          Navigator.pop(ctx);
          if (selectedIds.isEmpty) return;
          try {
            await _service.submitEndorsements(
              toUserId: widget.userId,
              categoryIds: selectedIds,
            );
            await _loadEndorsements();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectedIds.length == 1
                        ? 'Endorsement submitted!'
                        : '${selectedIds.length} endorsements submitted!',
                  ),
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

/// Separate stateful widget for the multi-select endorsement dialog
class _EndorseDialogContent extends StatefulWidget {
  final Map<String, int> counts;
  final Set<String> allEndorsedCategoryIds;
  final Set<String> myEndorsedCategoryIds;
  final void Function(List<String> selectedIds) onSubmit;

  const _EndorseDialogContent({
    required this.counts,
    required this.allEndorsedCategoryIds,
    required this.myEndorsedCategoryIds,
    required this.onSubmit,
  });

  @override
  State<_EndorseDialogContent> createState() => _EndorseDialogContentState();
}

class _EndorseDialogContentState extends State<_EndorseDialogContent> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.romanticGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Endorse This Person',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select all that apply. Your endorsement is anonymous.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: EndorsementService.categories.map((cat) {
                  final catId = cat['id']!;
                  final isEndorsedByOther =
                      widget.allEndorsedCategoryIds.contains(catId);
                  final isEndorsedByMe =
                      widget.myEndorsedCategoryIds.contains(catId);
                  final isTaken = isEndorsedByOther && !isEndorsedByMe;
                  final isSelected = _selected.contains(catId);
                  final count = widget.counts[catId] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: isTaken || isEndorsedByMe
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(catId);
                                } else {
                                  _selected.add(catId);
                                }
                              });
                            },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ImageFiltered(
                          imageFilter: isTaken
                              ? ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5)
                              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isEndorsedByMe
                                  ? Colors.green.withOpacity(0.25)
                                  : isTaken
                                      ? Colors.white.withOpacity(0.05)
                                      : isSelected
                                          ? Colors.white.withOpacity(0.3)
                                          : Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white.withOpacity(0.6),
                                      width: 2,
                                    )
                                  : isEndorsedByMe
                                      ? Border.all(
                                          color:
                                              Colors.green.withOpacity(0.5),
                                          width: 1.5,
                                        )
                                      : null,
                            ),
                            child: Row(
                              children: [
                                // Checkbox indicator
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isEndorsedByMe
                                        ? Colors.green
                                        : isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                    border: Border.all(
                                      color: isEndorsedByMe
                                          ? Colors.green
                                          : isTaken
                                              ? Colors.white24
                                              : Colors.white54,
                                      width: 2,
                                    ),
                                  ),
                                  child: isEndorsedByMe
                                      ? const Icon(Icons.check,
                                          size: 14, color: Colors.white)
                                      : isSelected
                                          ? const Icon(Icons.check,
                                              size: 14,
                                              color: AppTheme.primaryRose)
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                Text(cat['emoji']!,
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: isTaken
                                          ? Colors.white.withOpacity(0.4)
                                          : null,
                                    )),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat['label']!,
                                        style: TextStyle(
                                          color: isTaken
                                              ? Colors.white38
                                              : Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isTaken)
                                        const Text(
                                          'Already endorsed',
                                          style: TextStyle(
                                            color: Colors.white30,
                                            fontSize: 11,
                                          ),
                                        ),
                                      if (isEndorsedByMe)
                                        const Text(
                                          'You endorsed this',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (count > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => widget.onSubmit(_selected.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryRose,
                disabledBackgroundColor: Colors.white.withOpacity(0.2),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selected.isEmpty
                    ? 'Select endorsements'
                    : 'Submit ${_selected.length} endorsement${_selected.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
