import 'package:flutter/material.dart';
import '../../services/classifieds_service.dart';
import '../../utils/constants/colors.dart';
import 'post_classified_screen.dart';
import 'classified_detail_screen.dart';

class ClassifiedsListScreen extends StatefulWidget {
  const ClassifiedsListScreen({super.key});

  @override
  State<ClassifiedsListScreen> createState() => _ClassifiedsListScreenState();
}

class _ClassifiedsListScreenState extends State<ClassifiedsListScreen> {
  List<dynamic> _classifieds = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Furniture',
    'Vehicles',
    'Real Estate',
    'Fashion',
    'Sports',
    'Books',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadClassifieds();
  }

  Future<void> _loadClassifieds() async {
    setState(() => _isLoading = true);

    final result = await ClassifiedsService.getClassifieds(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );

    if (result['success'] && mounted) {
      setState(() {
        _classifieds = result['classifieds'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classifieds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.pushNamed(context, '/wallet');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = (_selectedCategory ?? 'All') == category;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category == 'All' ? null : category;
                      });
                      _loadClassifieds();
                    },
                    selectedColor: MyColors.primary.withOpacity(0.2),
                    checkmarkColor: MyColors.primary,
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Classifieds list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _classifieds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No classifieds found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadClassifieds,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _classifieds.length,
                          itemBuilder: (context, index) {
                            final classified = _classifieds[index];
                            return _buildClassifiedCard(classified);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostClassifiedScreen()),
          );
          if (result == true) {
            _loadClassifieds();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Ad'),
        backgroundColor: MyColors.primary,
      ),
    );
  }

  Widget _buildClassifiedCard(Map<String, dynamic> classified) {
    final images = classified['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassifiedDetailScreen(classified: classified),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Icon(Icons.image, size: 40, color: Colors.grey)
                    : null,
              ),

              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classified['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (classified['price'] != null)
                      Text(
                        'AED ${classified['price']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MyColors.primary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (classified['category'] != null)
                      Chip(
                        label: Text(
                          classified['category'],
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: MyColors.primary.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    const SizedBox(height: 4),
                    if (classified['location'] != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              classified['location'],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}