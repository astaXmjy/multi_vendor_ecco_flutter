import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../api/services/profile_service.dart';
import '../../../core/models/profile_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/profile_menu_item.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  ProfileModel? _profileData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // In _ProfilePageState class in profile_page.dart
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print("Starting to load profile data");
      final result = await _profileService.getUserProfile();
      print("Profile service result: success=${result['success']}");

      if (result['success']) {
        try {
          print("Creating ProfileModel from result data");
          final profile = ProfileModel.fromJson(result['data']);

          setState(() {
            _profileData = profile;
            _isLoading = false;
          });
          print("Profile data loaded successfully");
        } catch (e, stackTrace) {
          print("Error creating ProfileModel: $e");
          print("Stack trace: $stackTrace");
          setState(() {
            _error = 'Failed to process profile data: $e';
            _isLoading = false;
          });
        }
      } else {
        print("Failed to load profile: ${result['message']}");
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print("Exception in _loadProfile: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        _error = 'Failed to load profile data: $e';
        _isLoading = false;
      });
    }
  }

  // In your profile_page.dart file, add this method
  void _navigateToEditProfile() async {
    if (_profileData == null) return;

    final result =
        await context.push<bool>('/profile/edit', extra: _profileData);

    // If profile was updated, reload profile data
    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Profile',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _buildBody(),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF7A2E),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_profileData == null) {
      return const Center(
        child: Text('No profile data available'),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Profile header with avatar and user name
          ProfileHeader(
            profileData: _profileData!,
          ),

          const SizedBox(height: 16),

          // Account info card
          ProfileInfoCard(
            title: 'Account Information',
            items: [
              {'label': 'Email', 'value': _profileData!.email},
              {'label': 'Phone', 'value': _profileData!.phone},
              // {
              //   'label': 'Member Since',
              //   'value': _formatDate(_profileData!.createdAt)
              // },
              {'label': 'Status', 'value': _profileData!.status.toUpperCase()},
            ],
          ),

          const SizedBox(height: 16),

          // Orders & Wallet card
          ProfileInfoCard(
            title: 'Orders & Wallet',
            items: [
              {
                'label': 'Total Orders',
                'value': '${_profileData!.totalOrders}'
              },
              {
                'label': 'Total Spent',
                'value': '₹${_profileData!.totalOrderValue}'
              },
              {
                'label': 'Wallet Balance',
                'value': '₹${_profileData!.walletBalance}'
              },
              {
                'label': 'Reward Points',
                'value': '${_profileData!.rewardPoints} pts'
              },
            ],
          ),

          const SizedBox(height: 16),

          // Menu items
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  onTap: () {
                    _navigateToEditProfile();
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.location_on,
                  title: 'My Addresses',
                  subtitle: '${_profileData!.addresses.length} saved addresses',
                  onTap: () {
                    context.go('/profile/addresses');
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.history,
                  title: 'Order History',
                  onTap: () {
                    // Navigate to order history
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Wallet & Transactions',
                  onTap: () {
                    // Navigate to wallet
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.security,
                  title: 'Password & Security',
                  onTap: () {
                    // Navigate to security settings
                  },
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.notifications,
                  title: 'Notification Preferences',
                  onTap: () {
                    // Navigate to notification settings
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
