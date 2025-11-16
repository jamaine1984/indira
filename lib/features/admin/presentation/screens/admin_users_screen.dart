import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/admin/services/admin_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Users List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _searchQuery.isEmpty
                ? _adminService.getAllUsers()
                : _adminService.searchUsers(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildUserCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final photos = (userData['photos'] as List<dynamic>?)?.cast<String>() ?? [];
    final displayName = userData['displayName'] as String? ?? 'Unknown';
    final email = userData['email'] as String? ?? '';
    final age = userData['age'] as int? ?? 0;
    final gender = userData['gender'] as String? ?? '';
    final subscriptionTier =
        userData['subscriptionTier'] as String? ?? 'free';
    final isBlocked = userData['isBlocked'] as bool? ?? false;
    final isBanned = userData['isBanned'] as bool? ?? false;

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
                // Profile Photo
                CircleAvatar(
                  radius: 30,
                  backgroundImage: photos.isNotEmpty
                      ? CachedNetworkImageProvider(photos.first)
                      : null,
                  child: photos.isEmpty
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isBanned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BANNED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (isBlocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BLOCKED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$age years • $gender',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: subscriptionTier == 'premium'
                                  ? AppTheme.accentGold
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subscriptionTier.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: subscriptionTier == 'premium'
                                    ? AppTheme.textCharcoal
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleUserAction(
                    userId,
                    value,
                    userData,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: isBlocked ? 'unblock' : 'block',
                      child: Row(
                        children: [
                          Icon(
                            isBlocked ? Icons.lock_open : Icons.block,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(isBlocked ? 'Unblock User' : 'Block User'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: isBanned ? 'unban' : 'ban',
                      child: Row(
                        children: [
                          Icon(
                            isBanned ? Icons.check_circle : Icons.cancel,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(isBanned ? 'Unban User' : 'Ban User'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'subscription',
                      child: Row(
                        children: [
                          Icon(Icons.card_membership, size: 20),
                          SizedBox(width: 8),
                          Text('Change Subscription'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete User',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserAction(
    String userId,
    String action,
    Map<String, dynamic> userData,
  ) async {
    switch (action) {
      case 'view':
        _showUserDetails(userId, userData);
        break;
      case 'block':
      case 'unblock':
        await _adminService.toggleUserBlock(userId, action == 'block');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'User ${action == 'block' ? 'blocked' : 'unblocked'} successfully'),
            ),
          );
        }
        break;
      case 'ban':
      case 'unban':
        await _adminService.toggleUserBan(userId, action == 'ban');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'User ${action == 'ban' ? 'banned' : 'unbanned'} successfully'),
            ),
          );
        }
        break;
      case 'subscription':
        _showSubscriptionDialog(userId, userData['subscriptionTier'] ?? 'free');
        break;
      case 'delete':
        _showDeleteConfirmation(userId);
        break;
    }
  }

  void _showUserDetails(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userData['displayName'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', userData['email']),
              _buildDetailRow('Age', userData['age']?.toString() ?? 'N/A'),
              _buildDetailRow('Gender', userData['gender'] ?? 'N/A'),
              _buildDetailRow('Height', userData['height']?.toString() ?? 'N/A'),
              _buildDetailRow('Education', userData['education'] ?? 'N/A'),
              _buildDetailRow('Religion', userData['religion'] ?? 'N/A'),
              _buildDetailRow('Bio', userData['bio'] ?? 'N/A'),
              _buildDetailRow(
                'Subscription',
                userData['subscriptionTier'] ?? 'free',
              ),
              _buildDetailRow(
                'Photos',
                '${(userData['photos'] as List?)?.length ?? 0}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(String userId, String currentTier) {
    String selectedTier = currentTier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Free'),
                value: 'free',
                groupValue: selectedTier,
                onChanged: (value) {
                  setState(() => selectedTier = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Premium'),
                value: 'premium',
                groupValue: selectedTier,
                onChanged: (value) {
                  setState(() => selectedTier = value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('VIP'),
                value: 'vip',
                groupValue: selectedTier,
                onChanged: (value) {
                  setState(() => selectedTier = value!);
                },
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
                final expiresAt = selectedTier != 'free'
                    ? DateTime.now().add(const Duration(days: 30))
                    : null;
                await _adminService.updateUserSubscription(
                  userId,
                  selectedTier,
                  expiresAt,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription updated successfully'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.deleteUser(userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
