import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

class AdListItem extends StatelessWidget {
  final Map<String, dynamic> ad;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPayment;

  const AdListItem({
    super.key,
    required this.ad,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPayment,
  });

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF9C4); // Light yellow
      case 'active':
        return Colors.green[100]!;
      case 'expired':
        return Colors.red[100]!;
      case 'paused':
        return Colors.grey[100]!;
      default:
        return const Color(0xFFFFF9C4);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF8B4513); // Brown
      case 'active':
        return Colors.green[800]!;
      case 'expired':
        return Colors.red[800]!;
      case 'paused':
        return Colors.grey[800]!;
      default:
        return const Color(0xFF8B4513);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ad['status'] ?? 'pending';
    final imageUrl = ad['image_url'] as String?;
    final title = ad['title'] ?? 'Untitled Ad';
    final impressions = ad['current_impressions'] ?? 0;
    final clicks = ad['current_clicks'] ?? 0;
    final targetImpressions = ad['target_impressions'] ?? 0;
    final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0.0;
    final progress = targetImpressions > 0 
        ? (impressions / targetImpressions).clamp(0.0, 1.0) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Image, Title, and Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 24),
                              );
                            },
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 24),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                              '$impressions / $targetImpressions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      MyColors.primary,
                                    ),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),

                              ],

                              ),
                            ),
                            // Status Badge (top right)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusBackgroundColor(status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusTextColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                  ),
                  
                ],
              ),
              const SizedBox(height: 16),
              // Progress Section
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       '$impressions / $targetImpressions',
              //       style: TextStyle(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w500,
              //         color: Colors.grey[700],
              //       ),
              //     ),
              //     Text(
              //       '${(progress * 100).toStringAsFixed(0)}%',
              //       style: TextStyle(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w500,
              //         color: Colors.grey[700],
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 6),
              // LinearProgressIndicator(
              //   value: progress,
              //   backgroundColor: Colors.grey[200],
              //   valueColor: AlwaysStoppedAnimation<Color>(
              //     MyColors.primary,
              //   ),
              //   minHeight: 6,
              //   borderRadius: BorderRadius.circular(3),
              // ),
              const SizedBox(height: 20),
              // Statistics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Impressions', impressions.toString()),
                  _buildStatColumn('Clicks', clicks.toString()),
                  _buildStatColumn('CTR', '${ctr.toStringAsFixed(2)}%'),
                ],
              ),
              const SizedBox(height: 20),
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (status == 'pending' && onPayment != null)
                    _buildActionButton(
                      icon: Icons.credit_card,
                      label: 'Pay',
                      color: MyColors.primary,
                      onTap: onPayment,
                    ),
                  if (onEdit != null)
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Edit',
                      color: MyColors.primary,
                      onTap: onEdit,
                    ),
                  if (onDelete != null)
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: MyColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
