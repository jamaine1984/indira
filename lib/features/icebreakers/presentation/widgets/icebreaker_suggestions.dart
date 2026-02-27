import 'package:flutter/material.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/icebreakers/services/icebreaker_service.dart';

class IcebreakerSuggestions extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> otherUser;
  final String matchId;
  final ValueChanged<String> onSelect;

  const IcebreakerSuggestions({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.matchId,
    required this.onSelect,
  });

  @override
  State<IcebreakerSuggestions> createState() => _IcebreakerSuggestionsState();
}

class _IcebreakerSuggestionsState extends State<IcebreakerSuggestions> {
  final _service = IcebreakerService();
  late List<String> _suggestions;

  @override
  void initState() {
    super.initState();
    _suggestions = _service.generateIcebreakers(
      currentUser: widget.currentUser,
      otherUser: widget.otherUser,
    );
  }

  void _refresh() {
    setState(() {
      _suggestions = _service.generateIcebreakers(
        currentUser: widget.currentUser,
        otherUser: widget.otherUser,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('\u{1F4A1}', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Icebreakers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _refresh,
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 16, color: AppTheme.secondaryPlum),
                    const SizedBox(width: 4),
                    Text('More', style: TextStyle(color: AppTheme.secondaryPlum, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                widget.onSelect(s);
                _service.logIcebreakerUsed(widget.matchId, s);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryRose.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.send, size: 16, color: AppTheme.primaryRose.withOpacity(0.6)),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
