import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/admin/services/admin_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  final AdminService _adminService = AdminService();
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterStatus == null,
                onSelected: (selected) {
                  setState(() => _filterStatus = null);
                },
              ),
              FilterChip(
                label: const Text('Pending'),
                selected: _filterStatus == 'pending',
                onSelected: (selected) {
                  setState(() => _filterStatus = selected ? 'pending' : null);
                },
              ),
              FilterChip(
                label: const Text('Reviewed'),
                selected: _filterStatus == 'reviewed',
                onSelected: (selected) {
                  setState(() => _filterStatus = selected ? 'reviewed' : null);
                },
              ),
              FilterChip(
                label: const Text('Actioned'),
                selected: _filterStatus == 'actioned',
                onSelected: (selected) {
                  setState(() => _filterStatus = selected ? 'actioned' : null);
                },
              ),
            ],
          ),
        ),

        // Reports List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _adminService.getAllReports(status: _filterStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No reports found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildReportCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(String reportId, Map<String, dynamic> reportData) {
    final reporterId = reportData['reporterId'] as String? ?? '';
    final reportedUserId = reportData['reportedUserId'] as String? ?? '';
    final reason = reportData['reason'] as String? ?? 'Unknown';
    final description = reportData['description'] as String? ?? '';
    final status = reportData['status'] as String? ?? 'pending';
    final timestamp = (reportData['timestamp'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (timestamp != null)
                  Text(
                    '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Report Details
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reason: $reason',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // User Info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(reportedUserId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) return const SizedBox.shrink();

                final photos =
                    (userData['photos'] as List<dynamic>?)?.cast<String>() ??
                        [];
                final displayName =
                    userData['displayName'] as String? ?? 'Unknown';

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: photos.isNotEmpty
                          ? CachedNetworkImageProvider(photos.first)
                          : null,
                      child: photos.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reported User:',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Action Buttons
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _showReviewDialog(reportId, reportedUserId),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Review'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _showActionDialog(reportId, reportedUserId),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: AppTheme.primaryRose,
                      ),
                      child: const Text('Take Action'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'actioned':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showReviewDialog(String reportId, String reportedUserId) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Admin Notes',
                hintText: 'Add your review notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.updateReportStatus(
                reportId,
                'reviewed',
                adminNotes: notesController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report reviewed successfully'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(String reportId, String reportedUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _adminService.takeReportAction(
                  reportId,
                  reportedUserId,
                  'warn',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User warned')),
                  );
                }
              },
              icon: const Icon(Icons.warning),
              label: const Text('Warn User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _adminService.takeReportAction(
                  reportId,
                  reportedUserId,
                  'suspend',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User suspended for 7 days')),
                  );
                }
              },
              icon: const Icon(Icons.block),
              label: const Text('Suspend (7 days)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _adminService.takeReportAction(
                  reportId,
                  reportedUserId,
                  'ban',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User banned permanently')),
                  );
                }
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Ban Permanently'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _adminService.takeReportAction(
                  reportId,
                  reportedUserId,
                  'dismiss',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report dismissed')),
                  );
                }
              },
              icon: const Icon(Icons.close),
              label: const Text('Dismiss Report'),
            ),
          ],
        ),
      ),
    );
  }
}
