import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/entertainment/services/entertainment_service.dart';

class MultiplayerHubScreen extends StatefulWidget {
  final String gameType; // 'would_you_rather' or 'compatibility'

  const MultiplayerHubScreen({super.key, required this.gameType});

  @override
  State<MultiplayerHubScreen> createState() => _MultiplayerHubScreenState();
}

class _MultiplayerHubScreenState extends State<MultiplayerHubScreen> {
  final _service = EntertainmentService();
  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;
  bool _creating = false;

  String get _title => widget.gameType == 'would_you_rather'
      ? 'Would You Rather'
      : 'Compatibility Game';

  String get _emoji =>
      widget.gameType == 'would_you_rather' ? '\u{1F46B}' : '\u{1F4AF}';

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final matches = await _service.getMatches();
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _loading = false;
    });
  }

  Future<void> _startGame(String opponentId) async {
    setState(() => _creating = true);
    try {
      final sessionId = await _service.createGameSession(
        gameType: widget.gameType,
        opponentId: opponentId,
      );
      if (!mounted) return;
      if (widget.gameType == 'would_you_rather') {
        context.push('/would-you-rather/$sessionId');
      } else {
        context.push('/compatibility/$sessionId');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        '$_emoji $_title',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.gameType == 'would_you_rather'
                        ? 'Pick a match to play Would You Rather! Answer 10 fun dating questions and compare your choices.'
                        : 'Find out how compatible you are! Both of you answer 10 personality questions and get a compatibility score.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Choose a match
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose a match to play with',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Matches list
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _matches.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('\u{1F494}',
                                      style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No matches yet!',
                                    style: TextStyle(
                                      fontFamily: 'PlayfairDisplay',
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start swiping to find matches and play games together!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _matches.length,
                            itemBuilder: (context, index) {
                              final match = _matches[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: _creating
                                        ? null
                                        : () => _startGame(match['uid'] as String),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundImage: match['photoUrl'] != null
                                                ? NetworkImage(
                                                    match['photoUrl'] as String)
                                                : null,
                                            child: match['photoUrl'] == null
                                                ? const Icon(Icons.person)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              match['displayName'] as String? ??
                                                  'User',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textCharcoal,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.secondaryPlum,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Play',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              if (_creating)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Creating game session...',
                        style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
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
}
