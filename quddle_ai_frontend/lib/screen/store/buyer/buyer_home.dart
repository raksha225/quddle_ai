import 'package:flutter/material.dart';
import 'package:quddle_ai_frontend/utils/routes.dart';


class BuyerHome extends StatelessWidget {
  const BuyerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to categories - handled by parent
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF940D8E), // Purple
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Categories Row
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryItem('Electronics', Icons.phone_android, const Color(0xFF940D8E)),
                const SizedBox(width: 22),
                _buildCategoryItem('Fashion', Icons.checkroom, const Color(0xFF3B82F6)),
                const SizedBox(width: 22),
                _buildCategoryItem('Home', Icons.home, const Color(0xFF10B981)),
                const SizedBox(width: 22),
                _buildCategoryItem('Beauty', Icons.diamond, const Color(0xFF8B5CF6)),
                const SizedBox(width: 22),
                _buildCategoryItem('Home Decor', Icons.chair, const Color(0xFFF59E0B)),
                const SizedBox(width: 22),
                _buildCategoryItem('Books', Icons.menu_book, const Color(0xFFEF4444)),
                const SizedBox(width: 22),
                _buildCategoryItem('Fruits & Vegs', Icons.apple, const Color(0xFF84CC16)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Summer Sale Banner
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF940D8E), // Purple
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Summer Sale!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Featured Products Section
          const Text(
            'Featured Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Featured Products Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 8, // Show 8 products (1-8)
            itemBuilder: (context, index) {
              final productNumber = index + 1;
              final colors = [
                const Color(0xFF3B82F6), // Blue
                const Color(0xFF10B981), // Green
                const Color(0xFF8B5CF6), // Purple
                const Color(0xFFF59E0B), // Orange
                const Color(0xFFEF4444), // Red
                const Color(0xFF06B6D4), // Cyan
                const Color(0xFF84CC16), // Lime
                const Color(0xFFEC4899), // Pink
              ];
              
              final productNames = [
                'Wireless Headph...',
                'Smart Watch SE',
                'Gaming Laptop',
                'Bluetooth Speaker',
                'Wireless Mouse',
                'Mechanical Keyboard',
                'USB-C Hub',
                'Power Bank',
              ];
              
              final prices = [
                '\$129.99',
                '\$249.00',
                '\$899.99',
                '\$79.99',
                '\$49.99',
                '\$159.99',
                '\$89.99',
                '\$39.99',
              ];
              
              return _buildProductCard(
                'Product $productNumber',
                productNames[index],
                prices[index],
                colors[index],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon, Color color) {
    return Column(
      children: [
        // Icon Container
        Container(
          width: 90,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        // Text outside the box
        Text(
          name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProductCard(String title, String name, String price, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF940D8E), // Purple
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {

                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF940D8E), // Purple
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
