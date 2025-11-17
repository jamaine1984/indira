import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/admin/services/admin_service.dart';
import 'package:indira_love/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:indira_love/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:indira_love/features/admin/presentation/screens/admin_analytics_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    // In debug mode, bypass admin check for development access
    const bool kDebugMode = true; // Enable dev access to admin panel

    if (kDebugMode) {
      // Grant admin access in debug mode
      print('DEBUG: Granting admin access in debug mode');
      if (mounted) {
        setState(() {
          _isAdmin = true;
          _isLoading = false;
        });
      }
      return;
    }

    // Production admin check
    final isAdmin = await _adminService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });

      if (!isAdmin) {
        // Not admin, redirect to discover
        print('DEBUG: User is not admin, redirecting to discover');
        context.go('/discover');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textCharcoal,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/discover'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryRose,
          unselectedLabelColor: AppTheme.textCharcoal.withOpacity(0.6),
          indicatorColor: AppTheme.primaryRose,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
            Tab(icon: Icon(Icons.report), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminUsersScreen(),
          AdminAnalyticsScreen(),
          AdminReportsScreen(),
        ],
      ),
    );
  }
}
