// lib/presentation/pages/profile/my_addresses_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/address_model.dart';
import '../../../providers/address_provider.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/address_card.dart';
import '../auth/address_form_page.dart';

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({Key? key}) : super(key: key);

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    // Use the address provider to load addresses
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    await addressProvider.loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Addresses',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        child: Consumer<AddressProvider>(
          builder: (context, addressProvider, child) {
            if (addressProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF7A2E),
                ),
              );
            }

            if (addressProvider.error != null) {
              return _buildErrorView(addressProvider.error!);
            }

            if (addressProvider.addresses.isEmpty) {
              return _buildEmptyAddressView();
            }

            return _buildAddressList(addressProvider.addresses);
          },
        ),
      ),
      bottomNavigationBar:
          const CustomBottomNavBar(currentIndex: 4), // Profile tab
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAddress(),
        backgroundColor: const Color(0xFFFF7A2E),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Failed to load addresses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAddresses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A2E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAddressView() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'No Addresses Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add a new address to have your orders delivered',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddAddress(),
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(List<AddressModel> addresses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return AddressCard(
          address: address,
          onEdit: () => _navigateToEditAddress(address),
          onDelete: () => _confirmDeleteAddress(address),
          onSetDefault:
              address.isDefault ? null : () => _setDefaultAddress(address.id!),
        );
      },
    );
  }

  void _navigateToAddAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressFormPage(
          mode: AddressFormMode.newAddress,
        ),
      ),
    );
  }

  void _navigateToEditAddress(AddressModel address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormPage(
          mode: AddressFormMode.editAddress,
          address: address,
        ),
      ),
    );
  }

  Future<void> _setDefaultAddress(String addressId) async {
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);

    // Show loading indicator
    _showLoadingDialog('Setting as default...');

    final result = await addressProvider.setDefaultAddress(addressId);

    // Dismiss loading dialog
    if (mounted) Navigator.pop(context);

    if (!result['success']) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Failed to set as default address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text(
          'Are you sure you want to delete this address? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAddress(address.id!);
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);

    // Show loading indicator
    _showLoadingDialog('Deleting address...');

    final result = await addressProvider.deleteAddress(addressId);

    // Dismiss loading dialog
    if (mounted) Navigator.pop(context);

    if (!result['success']) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(
                color: Color(0xFFFF7A2E),
              ),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }
}
