import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';
import 'package:indira_love/features/festival/services/festival_service.dart';

class FestivalScreen extends StatefulWidget {
  const FestivalScreen({super.key});

  @override
  State<FestivalScreen> createState() => _FestivalScreenState();
}

class _FestivalScreenState extends State<FestivalScreen> {
  final _service = FestivalService();
  final Map<String, bool> _rsvpStatus = {};
  final Map<String, int> _rsvpCounts = {};

  @override
  void initState() {
    super.initState();
    _loadRsvpData();
  }

  Future<void> _loadRsvpData() async {
    final festivals = FestivalService.getAllFestivals();
    for (final f in festivals) {
      final id = f['id'] as String;
      final hasRsvpd = await _service.hasRsvpd(id);
      final count = await _service.getRsvpCount(id);
      if (mounted) {
        setState(() {
          _rsvpStatus[id] = hasRsvpd;
          _rsvpCounts[id] = count;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allFestivals = FestivalService.getAllFestivals();
    final now = DateTime.now();
    final active = allFestivals.where((f) {
      final start = f['startDate'] as DateTime;
      final end = f['endDate'] as DateTime;
      return now.isAfter(start) && now.isBefore(end);
    }).toList();
    final upcoming = allFestivals.where((f) {
      final start = f['startDate'] as DateTime;
      return start.isAfter(now);
    }).toList()
      ..sort((a, b) => (a['startDate'] as DateTime).compareTo(b['startDate'] as DateTime));
    final past = allFestivals.where((f) {
      final end = f['endDate'] as DateTime;
      return end.isBefore(now);
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        l10n.festivalEvents,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text('\u{1F389}', style: TextStyle(fontSize: 28)),
                  ],
                ),
              ),

              // Active Festival Banner
              if (active.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(active.first['color'] as int),
                          Color(active.first['color'] as int).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(active.first['color'] as int).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(active.first['emoji'] as String, style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.happeningNow.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text(active.first['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay')),
                              Text(active.first['tagline'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Festival List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        child: Text(l10n.upcomingFestivals, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      ),
                      ...upcoming.map((f) => _buildFestivalCard(f)),
                    ],
                    if (active.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 16),
                        child: Text(l10n.happeningNow, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      ),
                      ...active.map((f) => _buildFestivalCard(f, isActive: true)),
                    ],
                    if (past.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 16),
                        child: Text(l10n.pastEvents, style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      ),
                      ...past.take(3).map((f) => _buildFestivalCard(f, isPast: true)),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFestivalCard(Map<String, dynamic> festival, {bool isActive = false, bool isPast = false}) {
    final l10n = AppLocalizations.of(context);
    final id = festival['id'] as String;
    final color = Color(festival['color'] as int);
    final activities = festival['activities'] as List<dynamic>;
    final startDate = festival['startDate'] as DateTime;
    final endDate = festival['endDate'] as DateTime;
    final hasRsvpd = _rsvpStatus[id] ?? false;
    final rsvpCount = _rsvpCounts[id] ?? 0;

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[startDate.month - 1]} ${startDate.day} - ${months[endDate.month - 1]} ${endDate.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isPast ? 0.08 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: color, width: 2) : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Text(festival['emoji'] as String, style: TextStyle(fontSize: 32, color: isPast ? Colors.grey : null)),
          title: Text(
            festival['name'] as String,
            style: TextStyle(
              color: isPast ? Colors.white54 : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: TextStyle(color: isPast ? Colors.white38 : Colors.white60, fontSize: 12)),
              if (rsvpCount > 0)
                Text('$rsvpCount ${l10n.interested.toLowerCase()}', style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          iconColor: Colors.white60,
          collapsedIconColor: Colors.white38,
          children: [
            Text(
              festival['description'] as String,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.activities, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activities.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(a.toString(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
            if (!isPast) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasRsvpd ? null : () async {
                    await _service.rsvpToEvent(id);
                    setState(() {
                      _rsvpStatus[id] = true;
                      _rsvpCounts[id] = (rsvpCount) + 1;
                    });
                    if (mounted) {
                      AppSnackBar.success(context, "${l10n.youreGoing} - ${festival['name']}!");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasRsvpd ? Colors.white24 : color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(hasRsvpd ? l10n.youreGoing : l10n.interested, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
