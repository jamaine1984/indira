import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/theme/app_theme.dart';

class DeveloperSettingsScreen extends ConsumerStatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  ConsumerState<DeveloperSettingsScreen> createState() =>
      _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState
    extends ConsumerState<DeveloperSettingsScreen> {
  final TextEditingController _codeController = TextEditingController();
  final String _correctCode = '19840367';
  bool _isUnlocked = false;
  bool _isLoading = false;

  // Developer stats
  int _totalUsers = 0;
  int _totalMatches = 0;
  int _totalMessages = 0;
  int _totalReports = 0;
  int _totalGifts = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyCode() {
    if (_codeController.text == _correctCode) {
      setState(() {
        _isUnlocked = true;
      });
      _loadDeveloperStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Developer mode unlocked!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadDeveloperStats() async {
    setState(() => _isLoading = true);

    try {
      // Get total users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').count().get();
      _totalUsers = usersSnapshot.count ?? 0;

      // Get total matches
      final matchesSnapshot =
          await FirebaseFirestore.instance.collection('matches').count().get();
      _totalMatches = matchesSnapshot.count ?? 0;

      // Get total messages (approximate)
      final messagesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('messages')
          .count()
          .get();
      _totalMessages = messagesSnapshot.count ?? 0;

      // Get total reports
      final reportsSnapshot =
          await FirebaseFirestore.instance.collection('reports').count().get();
      _totalReports = reportsSnapshot.count ?? 0;

      // Get total gifts
      final giftsSnapshot = await FirebaseFirestore.instance
          .collection('user_gifts')
          .count()
          .get();
      _totalGifts = giftsSnapshot.count ?? 0;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.developer_mode,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Developer Settings',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isUnlocked
                      ? _buildDeveloperContent()
                      : _buildCodeEntry(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeEntry() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: AppTheme.primaryRose.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            const Text(
              'Enter Developer Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryRose,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => _verifyCode(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Unlock',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Section
          const Text(
            'Database Statistics',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildStatCard('Total Users', _totalUsers, Icons.people),
            _buildStatCard('Total Matches', _totalMatches, Icons.favorite),
            _buildStatCard('Total Messages', _totalMessages, Icons.message),
            _buildStatCard('Total Reports', _totalReports, Icons.report),
            _buildStatCard('Total Gifts', _totalGifts, Icons.card_giftcard),

            const SizedBox(height: 32),

            // Refresh button
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadDeveloperStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRose,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Developer Actions
            const Text(
              'Developer Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Clear Cache
            _buildActionButton(
              'Clear Local Cache',
              Icons.delete_sweep,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared (placeholder)'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Test Notifications
            _buildActionButton(
              'Test Push Notification',
              Icons.notifications,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent (placeholder)'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // View Logs
            _buildActionButton(
              'View Error Logs',
              Icons.bug_report,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error logs viewer (placeholder)'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Force Sync
            _buildActionButton(
              'Force Firebase Sync',
              Icons.sync,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firebase sync completed (placeholder)'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // App Info
            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow('App Version', '1.0.0'),
            _buildInfoRow('Build Number', '1'),
            _buildInfoRow('Environment', 'Development'),
            _buildInfoRow(
                'User ID', FirebaseAuth.instance.currentUser?.uid ?? 'N/A'),

            const SizedBox(height: 32),

            // Lock button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isUnlocked = false;
                    _codeController.clear();
                  });
                },
                icon: const Icon(Icons.lock),
                label: const Text('Lock Developer Mode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryRose.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryRose.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRose,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: AppTheme.primaryRose),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
