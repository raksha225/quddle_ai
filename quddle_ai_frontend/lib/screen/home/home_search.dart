import 'package:flutter/material.dart';
import '../../utils/routes.dart';
import '../../services/reels_service.dart';

class HomeSearch extends StatefulWidget {
  const HomeSearch({super.key});

  @override
  State<HomeSearch> createState() => _HomeSearchState();
}

class _HomeSearchState extends State<HomeSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceItem> _allServices = [];
  List<ServiceItem> _filteredServices = [];
  bool _isLoading = false;
  bool _hasSearchText = false;
  List<dynamic> _videos = [];
  List<dynamic> _myReels = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadReels();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _hasSearchText = _searchController.text.isNotEmpty;
    });
  }

  void _initializeServices() {
    _allServices = [
      ServiceItem(
        icon: Icons.video_library_outlined,
        title: 'Reels',
        isAvailable: true,
        onTap: (context) => _navigateToReels(context),
      ),
      ServiceItem(
        icon: Icons.live_tv_outlined,
        title: 'Live Streaming',
        isAvailable: false,
        onTap: (context) => _navigateToLiveStream(context),
      ),
      ServiceItem(
        icon: Icons.message_outlined,
        title: 'Messages',
        isAvailable: false,
        onTap: (context) => _navigateToChatting(context),
      ),
      ServiceItem(
        icon: Icons.store_outlined,
        title: 'Classifieds',
        isAvailable: false,
        onTap: (context) => _navigateToStore(context),
      ),
      ServiceItem(
        icon: Icons.local_offer_outlined,
        title: 'Coupons',
        isAvailable: false,
        onTap: (context) => _navigateToCoupons(context),
      ),
      ServiceItem(
        icon: Icons.build_outlined,
        title: 'Services',
        isAvailable: false,
        onTap: (context) => _navigateToServices(context),
      ),
      ServiceItem(
        icon: Icons.campaign_outlined,
        title: 'Advertiser',
        isAvailable: false,
        onTap: (context) => _navigateToAdvertiser(context),
      ),
      ServiceItem(
        icon: Icons.chat_bubble_outline,
        title: 'AI Assistant',
        isAvailable: true,
        onTap: (context) => AppRoutes.navigateToChatbot(context),
      ),
      ServiceItem(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        isAvailable: true,
        onTap: (context) => AppRoutes.navigateToNotifications(context),
      ),
      ServiceItem(
        icon: Icons.person_outline,
        title: 'Profile',
        isAvailable: true,
        onTap: (context) => AppRoutes.navigateToProfileHome(context),
      ),
    ];
    _filteredServices = _allServices;
  }

  Future<void> _loadReels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> _allReelsResponse = await ReelsService.listAllReels();
      List<dynamic> _myReelsResponse = await ReelsService.listMyReels();

      List<dynamic> _allReels = [];
      List<dynamic> _myReels = [];

      const oldDomain =
          'quddle-ai-reel-upload-process-videos.s3.ap-south-1.amazonaws.com';
      const newDomain = 'db1e7qdc0cu2m.cloudfront.net';

      for (final reel in _allReelsResponse) {
        final updatedReel = Map<String, dynamic>.from(reel);
        updatedReel['s3_serve_url'] =
            updatedReel['s3_serve_url']?.replaceAll(oldDomain, newDomain);
        _allReels.add(updatedReel);
      }

      for (final reel in _myReelsResponse) {
        final updatedReel = Map<String, dynamic>.from(reel);
        updatedReel['s3_serve_url'] =
            updatedReel['s3_serve_url']?.replaceAll(oldDomain, newDomain);
        _myReels.add(updatedReel);
      }

      if (mounted) {
        setState(() {
          _videos = _allReels;
          _myReels = _myReels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterServices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredServices = _allServices;
      } else {
        _filteredServices = _allServices.where((service) {
          return service.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _navigateToReels(BuildContext context) {
    AppRoutes.navigateToReelHome(
      context,
      videos: _videos,
      myReels: _myReels,
    );
  }

  void _navigateToLiveStream(BuildContext context) {
    // Coming soon - no navigation
  }

  void _navigateToChatting(BuildContext context) {
    // Coming soon - no navigation
  }

  void _navigateToStore(BuildContext context) {
    // Coming soon - no navigation
  }

  void _navigateToCoupons(BuildContext context) {
    // Coming soon - no navigation
  }

  void _navigateToServices(BuildContext context) {
    // Coming soon - no navigation
  }

  void _navigateToAdvertiser(BuildContext context) {
    // Coming soon - no navigation
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search for services...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF3B83F4), // Light blue color
            ),
            suffixIcon: _hasSearchText
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterServices('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: _filterServices,
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [

          // Services list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7D017C),
                      ),
                    ),
                  )
                : _filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No services found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 32,
                          runSpacing: 24,
                          children: _filteredServices.map((service) {
                            return _buildServiceButton(service);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(ServiceItem service) {
    return GestureDetector(
      onTap: service.isAvailable
          ? () => service.onTap(context)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${service.title} is coming soon!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF7D017C),
                ),
              );
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular icon container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF7D017C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              service.icon,
              color: const Color(0xFF7D017C),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            service.title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Reserve consistent space for all buttons
          const SizedBox(height: 4),
          // Add "Coming Soon" badge for unavailable services
          if (!service.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[400]!,
                  width: 0.5,
                ),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(height: 16), // Placeholder for consistent spacing
        ],
      ),
    );
  }
}

class ServiceItem {
  final IconData icon;
  final String title;
  final bool isAvailable;
  final Function(BuildContext) onTap;

  ServiceItem({
    required this.icon,
    required this.title,
    required this.isAvailable,
    required this.onTap,
  });
}
