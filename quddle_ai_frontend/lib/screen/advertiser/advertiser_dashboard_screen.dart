import 'package:flutter/material.dart';
import '../../utils/routes.dart';
import '../../utils/constants/colors.dart';
import '../../utils/styles/newstyles.dart';
import 'widgets/ad_form.dart';
import 'widgets/ad_list_item.dart';
import '../../services/ads_service.dart';

class AdvertiserDashboardScreen extends StatefulWidget {
  const AdvertiserDashboardScreen({super.key});

  @override
  State<AdvertiserDashboardScreen> createState() => _AdvertiserDashboardScreenState();
}

class _AdvertiserDashboardScreenState extends State<AdvertiserDashboardScreen> {
  List<dynamic> _ads = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, active, pending, expired
  int _currentBottomIndex = 0; // 0: Status, 1: Create Ad, 2: Analytics
  Map<String, dynamic>? _editingAd;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
    });

    final result = await AdsService.getMyAds();

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      setState(() {
        _ads = List<dynamic>.from(result['ads'] ?? []);
      });
    } else {
      if (mounted) {
        if (result['message'] == 'Authentication required') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to view your ads')),
          );
          AppRoutes.navigateToLogin(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to load ads')),
          );
        }
      }
    }
  }

  List<dynamic> get _filteredAds {
    if (_selectedFilter == 'all') return _ads;
    return _ads.where((ad) => ad['status'] == _selectedFilter).toList();
  }

  void _showEditAdForm(Map<String, dynamic> ad) {
    setState(() {
      _editingAd = ad;
      _currentBottomIndex = 1; // Switch to Create Ad tab
    });
  }

  void _resetForm() {
    setState(() {
      _editingAd = null;
    });
  }

  Future<void> _handleSubmit(Map<String, dynamic> adData) async {
    if (_editingAd != null) {
      // Update existing ad
      await _updateAd(_editingAd!['id'], adData);
    } else {
      // Create new ad
      await _createAd(adData);
    }
  }

  Future<void> _createAd(Map<String, dynamic> adData) async {
    final imageFile = adData['image_file'];
    if (imageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
      }
      return;
    }

    final result = await AdsService.createAd(
      title: adData['title'] ?? '',
      linkUrl: adData['link_url'],
      paymentAmount: adData['payment_amount'],
      targetImpressions: adData['target_impressions'],
      imageFile: imageFile,
    );

    if (result['success'] == true) {
      await _loadAds();
      _resetForm();
      setState(() {
        _currentBottomIndex = 0; // Switch back to Status tab
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ad created successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create ad')),
        );
      }
    }
  }

  Future<void> _updateAd(String adId, Map<String, dynamic> adData) async {
    final result = await AdsService.updateAd(
      adId: adId,
      title: adData['title'],
      linkUrl: adData['link_url'],
    );

    if (result['success'] == true) {
      await _loadAds();
      _resetForm();
      setState(() {
        _currentBottomIndex = 0; // Switch back to Status tab
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ad updated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update ad')),
        );
      }
    }
  }

  Future<void> _deleteAd(String adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text('Are you sure you want to delete this ad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await AdsService.deleteAd(adId);

    if (result['success'] == true) {
      await _loadAds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ad deleted successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to delete ad')),
        );
      }
    }
  }

  Future<void> _handlePayment(String adId) async {
    final result = await AdsService.initiatePayment(adId);

    if (result['success'] == true) {
      // TODO: Integrate Stripe SDK to complete payment with clientSecret
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment intent created. Complete payment on frontend.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      // TODO: Navigate to payment screen or show payment dialog
      // Use result['paymentIntent']['clientSecret'] for Stripe payment
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to initiate payment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.whitebox,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: MyColors.advertisterNavbar,
          ),
        ),
        elevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => AppRoutes.goBack(context),
        ),
        title: const Text(
          'Advertiser Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _buildCurrentView(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentBottomIndex) {
      case 0:
        return _buildStatusView();
      case 1:
        return _buildCreateAdView();
      case 2:
        return _buildAnalyticsView();
      default:
        return _buildStatusView();
    }
  }

  Widget _buildStatusView() {
    return Column(
      children: [
        // Segmented Control Style Filter
        NewStyles.segmentedControl(
          context: context,
          selectedValue: _selectedFilter,
          options: const ['All', 'Active', 'Pending', 'Expired'],
          values: const ['all', 'active', 'pending', 'expired'],
          onValueChanged: (value) {
            setState(() {
              _selectedFilter = value;
            });
          },
        ),

        // Ads List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAds.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAds,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredAds.length,
                        itemBuilder: (context, index) {
                          final ad = _filteredAds[index];
                          return AdListItem(
                            ad: ad,
                            onTap: () => _showEditAdForm(ad),
                            onEdit: () => _showEditAdForm(ad),
                            onDelete: () => _deleteAd(ad['id']),
                            onPayment: ad['status'] == 'pending'
                                ? () => _handlePayment(ad['id'])
                                : null,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCreateAdView() {
    return Column(
      children: [
        // Form Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _editingAd != null ? 'Edit Ad' : 'Create New Ad',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_editingAd != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _resetForm,
                ),
            ],
          ),
        ),

        // Ad Form
        Expanded(
          child: AdForm(
            existingAd: _editingAd,
            onSubmit: _handleSubmit,
            onDelete: _editingAd != null
                ? () => _deleteAd(_editingAd!['id'])
                : null,
            onPayment: _editingAd != null && _editingAd!['status'] == 'pending'
                ? () => _handlePayment(_editingAd!['id'])
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: 'Status',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.add_circle_outline,
                selectedIcon: Icons.add_circle,
                label: 'Create Ad',
                index: 1,
              ),
              _buildBottomNavItem(
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics,
                label: 'Analytics',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentBottomIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentBottomIndex = index;
            if (index != 1) {
              _resetForm(); // Reset form when leaving Create Ad tab
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? MyColors.primary : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? MyColors.primary : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            _selectedFilter == 'all'
                ? 'No ads yet'
                : 'No ${_selectedFilter} ads',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first ad to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

}
