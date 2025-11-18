import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';

class ClassifiedDetailScreen extends StatelessWidget {
  final Map<String, dynamic> classified;

  const ClassifiedDetailScreen({super.key, required this.classified});

  @override
  Widget build(BuildContext context) {
    final images = classified['images'] as List?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images carousel
            if (images != null && images.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 80),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    classified['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price
                  if (classified['price'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: MyColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AED ${classified['price']}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: MyColors.primary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Category & Location
                  Row(
                    children: [
                      if (classified['category'] != null) ...[
                        const Icon(Icons.category, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          classified['category'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (classified['location'] != null) ...[
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classified['location'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    classified['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // Posted date
                  if (classified['created_at'] != null)
                    Text(
                      'Posted: ${DateTime.parse(classified['created_at']).toString().split('.')[0]}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Contact seller functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact seller feature coming soon!')),
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text('Contact Seller'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}