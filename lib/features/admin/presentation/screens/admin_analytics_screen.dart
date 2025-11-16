import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/admin/services/admin_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>>? _growthData;
  Map<String, dynamic>? _demographics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _adminService.getAnalytics();
      final growth = await _adminService.getUserGrowthData(7);
      final demographics = await _adminService.getUserDemographics();

      if (mounted) {
        setState(() {
          _analyticsData = analytics;
          _growthData = growth;
          _demographics = demographics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics
            _buildKeyMetrics(),
            const SizedBox(height: 24),

            // User Growth Chart
            _buildUserGrowthChart(),
            const SizedBox(height: 24),

            // Real-time Ad Watches
            _buildRealTimeAdWatches(),
            const SizedBox(height: 24),

            // Demographics
            _buildDemographics(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textCharcoal,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Users',
              _analyticsData?['totalUsers']?.toString() ?? '0',
              Icons.people,
              AppTheme.primaryRose,
            ),
            _buildMetricCard(
              'Active (24h)',
              _analyticsData?['activeUsers24h']?.toString() ?? '0',
              Icons.person,
              Colors.green,
            ),
            _buildMetricCard(
              'Total Matches',
              _analyticsData?['totalMatches']?.toString() ?? '0',
              Icons.favorite,
              Colors.red,
            ),
            _buildMetricCard(
              'Messages Today',
              _analyticsData?['messagesToday']?.toString() ?? '0',
              Icons.message,
              Colors.blue,
            ),
            _buildMetricCard(
              'Ads Today',
              _analyticsData?['adsWatchedToday']?.toString() ?? '0',
              Icons.play_circle,
              AppTheme.accentGold,
            ),
            _buildMetricCard(
              'Total Ads',
              _analyticsData?['totalAdsWatched']?.toString() ?? '0',
              Icons.analytics,
              AppTheme.secondaryPlum,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    if (_growthData == null || _growthData!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Growth (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textCharcoal,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _growthData!.length) {
                            return Text(
                              _growthData![value.toInt()]['date'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _growthData!
                          .asMap()
                          .entries
                          .map(
                            (entry) => FlSpot(
                              entry.key.toDouble(),
                              (entry.value['count'] as int).toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: AppTheme.primaryRose,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryRose.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeAdWatches() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Real-Time Ad Watches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textCharcoal,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _adminService.getAdWatchStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final adsToday = snapshot.data!.docs.length;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle,
                            size: 32,
                            color: AppTheme.secondaryPlum,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$adsToday',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryPlum,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ads watched today',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textCharcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length > 5
                            ? 5
                            : snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp =
                              (data['timestamp'] as Timestamp?)?.toDate();

                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.play_arrow,
                              color: AppTheme.primaryRose,
                            ),
                            title: Text(
                              'User: ${data['userId']?.toString().substring(0, 8)}...',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              timestamp != null
                                  ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographics() {
    if (_demographics == null) {
      return const SizedBox.shrink();
    }

    final genderCount =
        _demographics!['genderCount'] as Map<String, dynamic>? ?? {};
    final ageGroups =
        _demographics!['ageGroups'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Demographics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textCharcoal,
          ),
        ),
        const SizedBox(height: 16),

        // Gender Distribution
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gender Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...genderCount.entries.map((entry) {
                  final total = genderCount.values.fold<int>(
                    0,
                    (sum, count) => sum + (count as int),
                  );
                  final percentage = total > 0
                      ? ((entry.value as int) / total * 100).toStringAsFixed(1)
                      : '0';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: total > 0
                                ? (entry.value as int) / total
                                : 0,
                            backgroundColor: Colors.grey[200],
                            color: AppTheme.primaryRose,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${entry.value} ($percentage%)',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Age Distribution
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Age Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...ageGroups.entries.map((entry) {
                  final total = ageGroups.values.fold<int>(
                    0,
                    (sum, count) => sum + (count as int),
                  );
                  final percentage = total > 0
                      ? ((entry.value as int) / total * 100).toStringAsFixed(1)
                      : '0';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: total > 0
                                ? (entry.value as int) / total
                                : 0,
                            backgroundColor: Colors.grey[200],
                            color: AppTheme.secondaryPlum,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${entry.value} ($percentage%)',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
